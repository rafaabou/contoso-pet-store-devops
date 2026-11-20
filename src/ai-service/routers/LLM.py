from google import genai
import os

GEMINI_TEXT_MODEL = "gemini-3.6-flash"
GEMINI_IMAGE_MODEL = "gemini-2.5-flash-image"


def get_gemini():
    """Initialize the Gemini (Google AI Studio) client."""
    api_key: str = os.environ.get("GEMINI_API_KEY")

    if not api_key:
        raise Exception("GEMINI_API_KEY environment variable must be set (get one at https://aistudio.google.com/apikey)")

    client = genai.Client(api_key=api_key, http_options={"timeout": 60000})
    print("Using Gemini (Google AI Studio) client")
    return client


def get_openai(api_key: str, base_url: str):
    """Build an OpenAI-compatible client for any provider (NVIDIA NIM, Groq, Mistral, OpenAI...)."""
    from openai import OpenAI

    return OpenAI(api_key=api_key, base_url=base_url, timeout=60.0, max_retries=2)