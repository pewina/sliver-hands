from google import genai
from app.config import settings

print("Starting Gemini test...")

print("API key configured:", bool(settings.gemini_api_key))
print("Gemini model:", settings.gemini_model)

client = genai.Client(api_key=settings.gemini_api_key)

response = client.models.generate_content(
    model=settings.gemini_model,
    contents="Give me three livelihood skills relevant to a person who makes traditional homemade snacks."
)

print("\nGemini response:")
print(response.text)