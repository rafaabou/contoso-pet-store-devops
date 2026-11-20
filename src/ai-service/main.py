from fastapi import FastAPI, status
from routers.description_generator import description
from routers.image_generator import image
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from routers import providers
import os

app = FastAPI(version=os.environ.get("APP_VERSION", "0.1.0"))
app.include_router(description)
app.include_router(image)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/health", summary="check if server is healthy", operation_id="health")
async def get_health():
    """
    Returns status code 200
    """
    capabilities = []

    # Description capability requires at least one armed text provider
    if providers.text_providers():
        capabilities.append("description")

    # Image capability requires at least one armed image provider
    if providers.image_providers():
        capabilities.append("image")

    print("Generative AI capabilities: ", ", ".join(capabilities))
    return JSONResponse(content={
        "status": 'ok',
        "version": app.version,
        "capabilities": capabilities,
        "providers": providers.status(),
    }, status_code=status.HTTP_200_OK)