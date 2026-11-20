"""HTTP contracts: validation, provider passthrough, 503 shape, upload guards."""
from fastapi.testclient import TestClient

import main
from routers import providers

client = TestClient(main.app)

PRODUCT = {"name": "Tug Rope", "description": "durable tug toy for dogs"}


def test_image_rejects_prompt_only_body():
    r = client.post("/generate/image", json={"prompt": "a dog"})
    assert r.status_code == 422


def test_image_returns_provider_and_includes_price(monkeypatch):
    captured = {}

    def fake_gen(prompt):
        captured["prompt"] = prompt
        return "data:image/png;base64,AAA", "cloudflare"

    monkeypatch.setattr(providers, "generate_image", fake_gen)
    r = client.post("/generate/image", json={**PRODUCT, "price": 24.99})
    assert r.status_code == 200
    body = r.json()
    assert body["provider"] == "cloudflare"
    assert body["image"].startswith("data:image/png;base64,")
    assert "$24.99" in captured["prompt"]


def test_image_without_price_omits_it_from_prompt(monkeypatch):
    captured = {}

    def fake_gen(prompt):
        captured["prompt"] = prompt
        return "data:image/png;base64,AAA", "xkiro"

    monkeypatch.setattr(providers, "generate_image", fake_gen)
    r = client.post("/generate/image", json=PRODUCT)
    assert r.status_code == 200
    assert "retail price" not in captured["prompt"]


def test_image_all_providers_failed_is_503(monkeypatch):
    def fake_gen(prompt):
        raise providers.AllProvidersFailed({"gemini": "boom"})

    monkeypatch.setattr(providers, "generate_image", fake_gen)
    r = client.post("/generate/image", json=PRODUCT)
    assert r.status_code == 503
    assert r.json()["attempted"] == {"gemini": "boom"}


def _upload(files, data):
    return client.post("/generate/image/upload", files=files, data=data)


def test_upload_rejects_non_image():
    r = _upload(
        files={"file": ("notes.txt", b"hello", "text/plain")},
        data={"name": "N", "description": "D"},
    )
    assert r.status_code == 400


def test_upload_rejects_empty_file():
    r = _upload(
        files={"file": ("empty.png", b"", "image/png")},
        data={"name": "N", "description": "D"},
    )
    assert r.status_code == 400


def test_upload_rejects_oversize_file():
    big = b"\xff" * (2 * 1024 * 1024 + 1)
    r = _upload(
        files={"file": ("big.jpg", big, "image/jpeg")},
        data={"name": "N", "description": "D"},
    )
    assert r.status_code == 413


def test_upload_roundtrip_returns_data_uri():
    r = _upload(
        files={"file": ("toy.png", b"\x89PNG\r\n\x1a\n", "image/png")},
        data={"name": "N", "description": "D", "price": "5"},
    )
    assert r.status_code == 200
    body = r.json()
    assert body["provider"] == "upload"
    assert body["image"].startswith("data:image/png;base64,")
