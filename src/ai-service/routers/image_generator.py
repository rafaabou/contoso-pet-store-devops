from typing import Optional

from fastapi import APIRouter, File, Form, UploadFile, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from routers import providers
import base64

image: APIRouter = APIRouter(prefix="/generate", tags=["generate"])

MAX_UPLOAD_BYTES = 2 * 1024 * 1024


class ProductImageRequest(BaseModel):
    name: str = Field(..., description="Name of the product")
    description: str = Field(..., description="Description of the product")
    price: Optional[float] = Field(None, ge=0, description="Retail price in USD (optional, added to the prompt as context)")


@image.post("/image", summary="Get image for a product", operation_id="getImage")
async def post_image(product: ProductImageRequest) -> JSONResponse:
    try:
        name: str = product.name
        description: str = product.description

        print("Calling image generators (failover chain)")

        prompt: str = (
            "Generate a cute photo realistic image of a product in its packaging "
            "in front of a plain background for a product called <" + name + "> "
            "with a description <" + description + "> to be sold in an online pet supply store"
        )
        if product.price is not None:
            prompt += f" at a retail price of ${product.price:.2f}"

        image_uri, provider = providers.generate_image(prompt)

        return JSONResponse(content={"image": image_uri, "provider": provider}, status_code=status.HTTP_200_OK)
    except providers.AllProvidersFailed as e:
        print(f"All image providers failed: {e.attempted}")
        return JSONResponse(content={"error": str(e), "attempted": e.attempted}, status_code=status.HTTP_503_SERVICE_UNAVAILABLE)
    except Exception as e:
        print(f"Error generating image: {str(e)}")
        # Return an error message as a JSON response
        return JSONResponse(content={"error": str(e)}, status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)


@image.post("/image/upload", summary="Upload a local product photo", operation_id="uploadImage")
async def post_image_upload(
    file: UploadFile = File(..., description="Local image file (max 2 MB)"),
    name: str = Form(..., description="Name of the product"),
    description: str = Form(..., description="Description of the product"),
    price: Optional[float] = Form(None, description="Retail price in USD (optional)"),
) -> JSONResponse:
    # Use-your-own-photo path: no AI provider is called (no quota used).
    # Returns the uploaded file as a data URI, same contract as /generate/image.
    try:
        if not (file.content_type or "").startswith("image/"):
            return JSONResponse(
                content={"error": f"not an image upload (got {file.content_type})"},
                status_code=status.HTTP_400_BAD_REQUEST,
            )
        contents = await file.read()
        if not contents:
            return JSONResponse(
                content={"error": "empty file"},
                status_code=status.HTTP_400_BAD_REQUEST,
            )
        if len(contents) > MAX_UPLOAD_BYTES:
            return JSONResponse(
                content={"error": f"image too large ({len(contents)} bytes, max {MAX_UPLOAD_BYTES})"},
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            )
        mime = (file.content_type or "image/jpeg").split(";")[0].strip()
        image_b64 = base64.b64encode(contents).decode("ascii")
        print(f"image uploaded for product '{name}' ({len(contents)} bytes, {mime})")
        return JSONResponse(
            content={"image": f"data:{mime};base64,{image_b64}", "provider": "upload"},
            status_code=status.HTTP_200_OK,
        )
    except Exception as e:
        print(f"Error uploading image: {str(e)}")
        return JSONResponse(content={"error": str(e)}, status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)