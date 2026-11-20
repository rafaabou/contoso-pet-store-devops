# ai-service

This is a FastAPI app that provides an API for interacting with Google Generative AI (Gemini + Nano Banana) with automatic failover to NVIDIA NIM (FLUX images / GPT-OSS text) for a pet store. It is meant to be used in conjunction with the [store-admin](../store-admin) app.

Endpoints:

- `GET  /health` - liveness + capabilities + armed provider chain
- `POST /generate/description` - write a product description from a name + tags
- `POST /generate/image` - generate a product photo from name + description (optional `price` adds retail-price context to the prompt), returned as a base64 data URI or image URL
- `POST /generate/image/upload` - upload a local product photo instead (`multipart/form-data`: `file` + `name` + `description` + optional `price`, max 2 MB, no AI/quota used), returned as a base64 data URI with `"provider": "upload"`

## How failover works

Each request tries the providers in order (defined by `AI_TEXT_PROVIDERS` / `AI_IMAGE_PROVIDERS`). A provider is only used when its API key is set. If the first one fails (rate limit, bad model, wrong key, timeout), the next one answers automatically. When every provider fails, the API returns **503** with a per-provider error summary so you can see exactly which key/model broke.

```
TEXT:   gemini → nvidia
IMAGES: gemini → cloudflare → xkiro   (nvidia dropped: persistent 504 on free tier = pure dead wait)
```

The provider that actually answered is included in the response (`"provider": "gemini"`, `"nvidia"`, `"cloudflare"` or `"xkiro"`).

## Configuration

| Variable | Default | Required | Purpose |
|---|---|---|---|
| `GEMINI_API_KEY` | — | yes* | Primary provider (Google AI Studio) |
| `GEMINI_TEXT_MODEL` | `gemini-3.6-flash` | no | Gemini text model |
| `GEMINI_IMAGE_MODEL` | `gemini-2.5-flash-image` | no | Gemini image model (Nano Banana) |
| `NVIDIA_API_KEY` | — | no* | Backup provider (build.nvidia.com, free) |
| `NVIDIA_TEXT_MODEL` | `openai/gpt-oss-20b` | no | NVIDIA text model |
| `NVIDIA_IMAGE_MODEL` | `black-forest-labs/flux.1-schnell` | no | NVIDIA image model (FLUX, via `ai.api.nvidia.com/v1/genai/{model}`) |
| `CLOUDFLARE_API_TOKEN` | — | no* | Last-resort image provider (dash.cloudflare.com, free plan, Workers AI token) |
| `CLOUDFLARE_ACCOUNT_ID` | — | no* | Cloudflare Account ID (same dashboard page) |
| `CLOUDFLARE_IMAGE_MODEL` | `@cf/black-forest-labs/flux-1-schnell` | no | Cloudflare image model (via `POST .../ai/run/{model}`) |
| `XKIRO_API_KEY` | — | no* | 4th image fallback (xkiro.com dashboard → API Keys, free plan, no card) |
| `XKIRO_IMAGE_MODEL` | `sensenova/sensenova-u1.5-lite` | no | xKiro image model (via async `POST /v1/images/generations` + polling) |
| `AI_TEXT_PROVIDERS` | `gemini,nvidia` | no | Text failover order |
| `AI_IMAGE_PROVIDERS` | `gemini,cloudflare,xkiro` | no | Image failover order |
| `AI_IMAGE_PARALLEL` | `false` | no | `true` = race all armed image providers, first success wins (faster, but burns quota on every provider per call) |

\* At least one provider key must be set for the service to be fully functional; with only `GEMINI_API_KEY`, Gemini serves both text and images.

> **Image free-tier note (2026-09-15):** Gemini image models (`2.5-flash-image`, `3-pro-image`, `3.1-flash-lite-image`, `3.1-flash-image`) all returned `429 RESOURCE_EXHAUSTED limit:0` on a free-tier Gemini API key, meaning this key/project has **zero image-generation quota** on the Gemini side. NVIDIA NIM (`black-forest-labs/flux.1-schnell`, free `nvapi-` key from build.nvidia.com, hosted `Infer` endpoint `https://ai.api.nvidia.com/v1/genai/{publisher}/{model}`) then returned a persistent `504 Gateway Timeout` — their gateway accepts the request but the FLUX backend never answers on the free tier (same error on repeat attempts, so not transient). Hugging Face Inference Providers was tried next and rejected: free accounts get only **$0.10/month** credits, depleted after a single image (`402 Payment Required`). The chain therefore ends at **Cloudflare Workers AI** (free plan: 10,000 Neurons/day ≈ ~170 FLUX images/day, resets daily, no card; `POST https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/run/@cf/black-forest-labs/flux-1-schnell` with Bearer API token, body `{"prompt": ...}`, response `{"result":{"image":"<base64>"}}`). Behind that sits **xKiro** as the 4th fallback (free plan, no card; `sensenova/sensenova-u1.5-lite`, OpenAI-compatible but **async**: `POST /v1/images/generations` returns `202` with a job id that is polled until `succeeded`, then the CDN url is fetched and wrapped as a data URI; free image quota is "limited" — a few images per rolling 24h). Request timeout is 600s everywhere since free-tier image queues are slow. Text generation on Gemini remains fully free and functional.

## Running the app locally

The app does not rely on any other services other than the Gemini/NVIDIA APIs, so you can run it locally without any other services running.

### Prerequisites

- [Python3](https://www.python.org/downloads/)
- [pip](https://pip.pypa.io/en/stable/installation/)
- [Gemini API key](https://aistudio.google.com/apikey) (Google AI Studio) — required
- [NVIDIA API key](https://build.nvidia.com) (free `nvapi-...` key) — optional, enables automatic failover
- [Cloudflare account](https://dash.cloudflare.com) (free plan: Workers AI token + Account ID) — optional, 3rd image fallback
- [xKiro API key](https://xkiro.com) (free plan: dashboard → API Keys) — optional, 4th image fallback

### Running the app

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

export GEMINI_API_KEY=
export NVIDIA_API_KEY=                        # optional
export AI_TEXT_PROVIDERS=gemini,nvidia        # optional, defaults already gemini,nvidia
export AI_IMAGE_PROVIDERS=gemini,nvidia

uvicorn main:app --host 127.0.0.1 --port 5001
```

When the app is running, you should see output similar to the following:

```text
INFO:     Started server process [134031]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:5001 (Press CTRL+C to quit)
```

Using the [`test-ai-service.http`](./test-ai-service.http) file in the root of the repo, you can test the API. However, you will need to use VS Code and have the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension installed.

### Running tests

Offline suite, no keys or network needed (vendor SDKs are stubbed):

```bash
pip install pytest httpx fastapi python-multipart
python -m pytest tests -q
```

Covers failover-chain arming/order (sequential + `AI_IMAGE_PARALLEL`), Cloudflare/xKiro response parsing, HTTP contracts (422/503), and upload guards (400/413).

### Running in Docker

```bash
docker build -t ai-service .
docker run -p 5001:5001 -e GEMINI_API_KEY=<your key> -e NVIDIA_API_KEY=<your key> ai-service
curl http://localhost:5001/health
```