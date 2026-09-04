from app.database.supabase_client import get_supabase
from app.services.rag_service import get_rag


KNOWLEDGE = [
    {
        "title": "Cooking livelihood opportunities",
        "content": (
            "People with cooking skills can earn income by preparing "
            "homemade snacks, pickles, sweets, tiffins, traditional foods "
            "and festival food products. They can sell directly to customers, "
            "local businesses or through bulk orders."
        ),
    },
    {
        "title": "Homemade food business",
        "content": (
            "A homemade food business can include traditional snacks, "
            "pickles, spice mixes, sweets and other prepared foods. "
            "Important skills include recipe preparation, food safety, "
            "packaging, costing and customer communication."
        ),
    },
    {
        "title": "Food packaging skills",
        "content": (
            "Food packaging is useful for sellers who prepare homemade "
            "food products. Good packaging helps protect the product, "
            "present it professionally and make it easier to sell through "
            "local shops, customers and bulk orders."
        ),
    },
    {
        "title": "Traditional skills and livelihood",
        "content": (
            "Traditional skills such as cooking, tailoring, handicrafts, "
            "embroidery and food preparation can be converted into "
            "livelihood opportunities through individual orders, local "
            "business collaborations and community marketplaces."
        ),
    },
    {
        "title": "SilverHands marketplace",
        "content": (
            "SilverHands helps people showcase their practical skills "
            "and connect with livelihood opportunities. Sellers can create "
            "profiles based on their skills and experience and receive "
            "recommendations for suitable opportunities."
        ),
    },
]


def main():
    rag = get_rag()
    supabase = get_supabase()

    for item in KNOWLEDGE:
        print(f"Embedding: {item['title']}")

        embedding = rag.embed(item["content"])

        print(f"Dimensions: {len(embedding)}")

        if len(embedding) != 768:
            raise RuntimeError(
                f"Expected 768 dimensions, got {len(embedding)}"
            )

        supabase.table("knowledge_documents").insert({
            "title": item["title"],
            "content": item["content"],
            "embedding": embedding,
        }).execute()

        print("Inserted successfully.\n")

    print("Knowledge seeding complete.")


if __name__ == "__main__":
    main()