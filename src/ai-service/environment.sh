#!/bin/bash

# --- Primary provider: Google AI Studio (Gemini) ---
# !!! Do NOT commit a real key. Set it locally, e.g. in ~/.bashrc, or pass it
#     to the container via --env-file / docker secrets / Vault.
export GEMINI_API_KEY=*******

# Model used to generate product descriptions
export GEMINI_TEXT_MODEL=*******

# Model used to generate product images (Nano Banana).
# If this image model is deprecated, use gemini-3.1-flash-image instead.
export GEMINI_IMAGE_MODEL=*******

# --- Backup provider: NVIDIA NIM (free nvapi- key at https://build.nvidia.com) ---
export NVIDIA_API_KEY=*******
export NVIDIA_TEXT_MODEL=*******
export NVIDIA_IMAGE_MODEL=*******

# --- Last-resort image provider: Cloudflare Workers AI (free plan, see .env.example) ---
export CLOUDFLARE_API_TOKEN=*******
export CLOUDFLARE_ACCOUNT_ID=*******
export CLOUDFLARE_IMAGE_MODEL=*******

# --- 4th image fallback: xKiro gateway (free plan, dashboard -> API Keys) ---
export XKIRO_API_KEY=*******
export XKIRO_IMAGE_MODEL=*******

# --- Failover chain order (a provider is only used if its API key is set) ---
export AI_TEXT_PROVIDERS=*******
export AI_IMAGE_PROVIDERS=*******

# --- Parallel image mode (opt-in): all armed providers race, first wins ---
export AI_IMAGE_PARALLEL=*******

echo "AI_TEXT_PROVIDERS: $AI_TEXT_PROVIDERS"
echo "AI_IMAGE_PROVIDERS: $AI_IMAGE_PROVIDERS"
echo "GEMINI_API_KEY is set: $([ -n "$GEMINI_API_KEY" ] && echo yes || echo NO)"
echo "NVIDIA_API_KEY is set: $([ -n "$NVIDIA_API_KEY" ] && echo yes || echo NO)"
echo "CLOUDFLARE_API_TOKEN is set: $([ -n "$CLOUDFLARE_API_TOKEN" ] && echo yes || echo NO)"
echo "XKIRO_API_KEY is set: $([ -n "$XKIRO_API_KEY" ] && echo yes || echo NO)"