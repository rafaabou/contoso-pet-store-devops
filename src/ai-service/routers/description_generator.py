from typing import List
from fastapi import APIRouter, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from routers import providers

description: APIRouter = APIRouter(prefix="/generate", tags=["generate"])


class ProductRequest(BaseModel):
    name: str = Field(..., description="Name of the product")
    tags: List[str] = Field(..., description="Tags describing the product")


@description.post("/description", summary="Get description for a product", operation_id="getDescription")
async def post_description(product: ProductRequest) -> JSONResponse:
    try:
        name: str = product.name
        tags: str = ",".join(product.tags)

        prompt: str = (
            "Describe this pet store product using joyful, playful, and enticing language.\n"
            "[DESCRIPTION GENERATION RULES]\n"
            "DONT WASTE WORDS\n"
            "USE SHORT, CLEAR, COMPLETE SENTENCES.\n"
            "DO NOT USE BULLET POINTS OR DASHES.\n"
            "USE ACTIVE VOICE.\n"
            "FOCUS ON THE CONTENT\n"
            "NO SEXISM, RACISM OR OTHER BIAS/BIGOTRY\n"
            "NO PROFANITY OR VULGARITY\n"
            "WORKPLACE/FAMILY SAFE\n"
            "[END RULES]\n"
            "describe the following product sold in a pet supplies store:\n"
            f"Product name: {name}\n"
            f"tags: {tags}"
        )

        result, provider = providers.generate_text(prompt)

        print(result)
        return JSONResponse(content={"description": result, "provider": provider}, status_code=status.HTTP_200_OK)
    except providers.AllProvidersFailed as e:
        print(f"All text providers failed: {e.attempted}")
        return JSONResponse(content={"error": str(e), "attempted": e.attempted}, status_code=status.HTTP_503_SERVICE_UNAVAILABLE)
    except Exception as e:
        # Return an error message as a JSON response
        return JSONResponse(content={"error": str(e)}, status_code=status.HTTP_400_BAD_REQUEST)