# store-admin

This is a Vue.js app that simulates a store admin portal where users can manually process orders, and manage products. It is meant to be used in conjunction with the [product-service](../product-service/) and [makeline-service](../makeline-service). You can also deploy the [ai-service](../ai-service) to generate product descriptions and images (Gemini-first with free fallbacks) and to upload product photos. You should also run the [virtual-customer](../virtual-customer) to simulate customers placing orders to have some order data to work with.

## Running the app locally

### Prerequisites

- [Node.js](https://nodejs.org/en/download/)
- [Vue CLI Service](https://cli.vuejs.org/guide/cli-service.html)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- A free [Gemini API key](https://aistudio.google.com/apikey) (required for AI features; optional free fallbacks: NVIDIA `nvapi-` key, Cloudflare Workers AI token + Account ID, xKiro API key)

### Running the app

The app relies on the [product-service](../product-service), [makeline-service](../order-service), and optionally the [ai-service](../ai-service) along with mongodb and rabbitmq instances running. A docker-compose file is provided to make this easy.

To run the necessary services, clone the repo, open a terminal, and navigate to the `store-admin` directory.

The `ai-service` block in `docker-compose.yml` is enabled by default. Export at least one provider key before `docker compose up` (empty = provider not armed, chain skips it):

```bash
export GEMINI_API_KEY=<your key> NVIDIA_API_KEY=<your key> CLOUDFLARE_API_TOKEN=<your token> CLOUDFLARE_ACCOUNT_ID=<your id> XKIRO_API_KEY=<your key>
```

> IMPORTANT: When filling in the values, do not put the value in double-quotes.

```yaml
environment:
  - GEMINI_API_KEY=${GEMINI_API_KEY:-} # required for AI features
  - NVIDIA_API_KEY=${NVIDIA_API_KEY:-} # optional text fallback
  - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN:-} # optional image fallback
  - CLOUDFLARE_ACCOUNT_ID=${CLOUDFLARE_ACCOUNT_ID:-} # pairs with the token
  - XKIRO_API_KEY=${XKIRO_API_KEY:-} # optional last-resort image fallback
```

Then run the following command:

```bash
docker compose up
```

With the services running, open a new terminal and navigate to the `store-admin` directory. Then run the following commands:

```bash
export VUE_APP_PRODUCT_SERVICE_URL=http://localhost:3002/
export VUE_APP_MAKELINE_SERVICE_URL=http://localhost:3001/

npm install
npm run serve
```

When the app is running, you should see output similar to the following:

```text
  App running at:
  - Local:   http://localhost:8081/ 
  - Network: http://192.168.0.144:8081/

  Note that the development build is not optimized.
  To create a production build, run npm run build.
```

Open a browser and navigate to `http://localhost:8081/`. You should see the store admin app running.