from google import genai
from app.config import settings

client = genai.Client(api_key=settings.gemini_api_key)

response = client.models.generate_content(
    model=settings.gemini_model,
    contents="Give me three livelihood skills relevant to a homemaker who makes traditional snacks."
)

print(response.text)