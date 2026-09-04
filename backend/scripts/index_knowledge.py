"""Generate Gemini embeddings for every knowledge document that has no embedding."""
from app.database.supabase_client import get_supabase
from app.services.rag_service import get_rag

def main():
    supabase = get_supabase()
    rag = get_rag()
    rows = supabase.table("knowledge_documents").select("id,title,content").is_("embedding", "null").execute().data
    for row in rows:
        vector = rag.embed(f"{row['title']}\n{row['content']}")
        supabase.table("knowledge_documents").update({"embedding": vector}).eq("id", row["id"]).execute()
        print(f"embedded: {row['title']}")

if __name__ == "__main__":
    main()
