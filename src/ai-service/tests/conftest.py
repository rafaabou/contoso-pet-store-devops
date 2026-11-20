"""Shared fixtures: stub the heavy vendor SDKs so the suite runs fully offline.

routers.providers does `from routers.LLM import ...` at module top, and the
real routers/LLM.py imports google-genai + openai. Pre-registering a fake
routers.LLM (plus SDK stubs as backup) keeps every test hermetic: no keys,
no network, no GPU.
"""
import os
import sys
import types

import pytest


def _install_sdk_stubs():
    google = types.ModuleType("google")
    genai = types.ModuleType("google.genai")
    genai.Client = object
    google.genai = genai
    sys.modules.setdefault("google", google)
    sys.modules.setdefault("google.genai", genai)

    openai = types.ModuleType("openai")
    openai.OpenAI = object
    sys.modules.setdefault("openai", openai)

    llm = types.ModuleType("routers.LLM")
    llm.GEMINI_TEXT_MODEL = "gemini-3.6-flash"
    llm.GEMINI_IMAGE_MODEL = "gemini-2.5-flash-image"
    llm.get_gemini = lambda *a, **k: None
    llm.get_openai = lambda *a, **k: None
    sys.modules.setdefault("routers.LLM", llm)


_install_sdk_stubs()

_MANAGED_PREFIXES = ("AI_", "GEMINI_", "NVIDIA_", "CLOUDFLARE_", "XKIRO_", "HF_", "HUGGINGFACE_")


@pytest.fixture(autouse=True)
def clean_ai_env(monkeypatch):
    """Every test starts with zero provider keys set (nothing armed)."""
    for key in [k for k in os.environ if k.startswith(_MANAGED_PREFIXES)]:
        monkeypatch.delenv(key, raising=False)
