from google import genai
from google.genai import types

from app.config import settings
from app.database.supabase_client import get_supabase

class RAGService:
    def __init__(self):
        if not settings.gemini_api_key:
            raise RuntimeError("GEMINI_API_KEY is not configured.")
        self.ai = genai.Client(api_key=settings.gemini_api_key)

    def embed(self, text: str) -> list[float]:
        result = self.ai.models.embed_content(
            model=settings.embedding_model,
            contents=text,
            config=types.EmbedContentConfig(output_dimensionality=settings.embedding_dim),
        )
        return result.embeddings[0].values

    def ask(self, question: str, language: str):
        vector = self.embed(question)
        matches = get_supabase().rpc(
            "match_knowledge",
            {"query_embedding": vector, "match_threshold": 0.45, "match_count": 6},
        ).execute().data

        context = "\n\n".join(
            f"[{m['title']}]\n{m['content']}" for m in matches
        )
        prompt = f"""
Answer the user's question in {language} using only the provided SilverHands knowledge.
If the knowledge does not contain the answer, say that you do not have enough information.
Keep the answer concise and practical.

Knowledge:
{context}

Question:
{question}
"""
        response = self.ai.models.generate_content(
            model=settings.gemini_model,
            contents=prompt,
        )
        return (response.text or "").strip(), [m["title"] for m in matches]

rag = None

def get_rag():
    global rag
    if rag is None:
        rag = RAGService()
    return rag
