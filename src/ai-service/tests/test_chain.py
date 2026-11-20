"""Failover-chain behavior: arming, ordering, sequential + parallel failover."""
import pytest

from routers import providers


def _arm(monkeypatch, **pairs):
    for key, value in pairs.items():
        monkeypatch.setenv(key, value)


def test_image_chain_skips_unarmed_and_unknown(monkeypatch):
    _arm(monkeypatch, GEMINI_API_KEY="g", XKIRO_API_KEY="x",
         AI_IMAGE_PROVIDERS="gemini,nvidia,cloudflare,xkiro,bogus")
    # nvidia/cloudflare lack keys -> skipped; bogus is not a provider -> dropped
    assert providers.image_providers() == ["gemini", "xkiro"]


def test_cloudflare_needs_both_token_and_account(monkeypatch):
    _arm(monkeypatch, CLOUDFLARE_API_TOKEN="t")
    assert "cloudflare" not in providers.image_providers()
    _arm(monkeypatch, CLOUDFLARE_ACCOUNT_ID="a")
    assert "cloudflare" in providers.image_providers()


def test_no_armed_providers_raises_config_error():
    with pytest.raises(providers.AllProvidersFailed) as exc:
        providers.generate_image("a puppy")
    assert "no provider armed" in exc.value.attempted["config"]


def test_sequential_failover_reaches_second_provider(monkeypatch):
    _arm(monkeypatch, GEMINI_API_KEY="g", XKIRO_API_KEY="x")
    calls = []

    def fake_call(provider, model, prompt):
        calls.append(provider)
        if provider == "gemini":
            raise RuntimeError("429 boom")
        return "data:image/png;base64,AAA"

    monkeypatch.setattr(providers, "_image_call", fake_call)
    uri, winner = providers.generate_image("a puppy")
    assert winner == "xkiro"
    assert uri.startswith("data:image/png;base64,")
    assert calls == ["gemini", "xkiro"]


def test_all_fail_reports_every_attempt(monkeypatch):
    _arm(monkeypatch, GEMINI_API_KEY="g", XKIRO_API_KEY="x")

    def always_fail(provider, model, prompt):
        raise RuntimeError(f"{provider} down")

    monkeypatch.setattr(providers, "_image_call", always_fail)
    with pytest.raises(providers.AllProvidersFailed) as exc:
        providers.generate_image("a puppy")
    assert set(exc.value.attempted) == {"gemini", "xkiro"}


def test_parallel_first_success_wins(monkeypatch):
    _arm(monkeypatch, GEMINI_API_KEY="g", XKIRO_API_KEY="x",
         AI_IMAGE_PARALLEL="true")

    def fake_call(provider, model, prompt):
        if provider == "xkiro":
            return "data:image/png;base64,AAA"
        raise RuntimeError("slow failure")

    monkeypatch.setattr(providers, "_image_call", fake_call)
    uri, winner = providers.generate_image("a puppy")
    assert winner == "xkiro"
    assert uri.startswith("data:image/png;base64,")


def test_parallel_all_fail_reports_every_attempt(monkeypatch):
    _arm(monkeypatch, GEMINI_API_KEY="g", XKIRO_API_KEY="x",
         AI_IMAGE_PARALLEL="1")

    def always_fail(provider, model, prompt):
        raise RuntimeError(f"{provider} down")

    monkeypatch.setattr(providers, "_image_call", always_fail)
    with pytest.raises(providers.AllProvidersFailed) as exc:
        providers.generate_image("a puppy")
    assert set(exc.value.attempted) == {"gemini", "xkiro"}


def test_cloudflare_success_parses_base64(monkeypatch):
    class Resp:
        def raise_for_status(self):
            pass

        def json(self):
            return {"success": True, "result": {"image": "QUJD"}}

    monkeypatch.setattr(providers.httpx, "post", lambda *a, **k: Resp())
    uri = providers._cloudflare_image("t", "a", "@cf/black-forest-labs/flux-1-schnell", "a cat")
    assert uri == "data:image/png;base64,QUJD"


def test_cloudflare_api_error_raises(monkeypatch):
    class Resp:
        def raise_for_status(self):
            pass

        def json(self):
            return {"success": False, "errors": [{"message": "quota spent"}]}

    monkeypatch.setattr(providers.httpx, "post", lambda *a, **k: Resp())
    with pytest.raises(Exception, match="quota spent"):
        providers._cloudflare_image("t", "a", "m", "a cat")


def test_xkiro_job_poll_then_fetch(monkeypatch):
    polls = iter([
        {"status": "processing"},
        {"status": "succeeded", "data": [{"url": "https://cdn/x.png"}]},
    ])

    class Resp:
        def __init__(self, payload=None, content=b"", mime="image/png"):
            self._payload = payload
            self.content = content
            self.headers = {"content-type": mime}

        def raise_for_status(self):
            pass

        def json(self):
            return self._payload

    def fake_post(url, **kwargs):
        return Resp(payload={"id": "job1"})

    def fake_get(url, **kwargs):
        if url.endswith("job1"):
            return Resp(payload=next(polls))
        return Resp(content=b"PNGDATA", mime="image/png")

    monkeypatch.setattr(providers.httpx, "post", fake_post)
    monkeypatch.setattr(providers.httpx, "get", fake_get)
    monkeypatch.setattr(providers.time, "sleep", lambda s: None)
    uri = providers._xkiro_image("k", "sensenova/sensenova-u1.5-lite", "a dog")
    assert uri == "data:image/png;base64,UE5HREFUQQ=="


def test_xkiro_blocked_job_raises(monkeypatch):
    class Resp:
        def raise_for_status(self):
            pass

        def json(self):
            return {"id": "job9"}

    class Poll:
        def raise_for_status(self):
            pass

        def json(self):
            return {"status": "blocked", "error": {"message": "policy nope"}}

    monkeypatch.setattr(providers.httpx, "post", lambda *a, **k: Resp())
    monkeypatch.setattr(providers.httpx, "get", lambda *a, **k: Poll())
    monkeypatch.setattr(providers.time, "sleep", lambda s: None)
    with pytest.raises(Exception, match="blocked"):
        providers._xkiro_image("k", "m", "a dog")
