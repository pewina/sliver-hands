class Opportunity {
  const Opportunity({
    this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.price,
    required this.seller,
    required this.category,
    required this.imageUrl,
    required this.skills,
    required this.matchScore,
    required this.verified,
    required this.description,
    this.distance = 'Nearby',
    this.demandLevel = 'High demand',
    this.sellersRequired = 1,
    this.recommendationReasons = const [],
    this.aiScore = const RecommendationScore(),
  });

  final String? id;
  final String title;
  final String subtitle;
  final String location;
  final String price;
  final String seller;
  final String category;
  final String imageUrl;
  final List<String> skills;
  final int matchScore;
  final bool verified;
  final String description;
  final String distance;
  final String demandLevel;
  final int sellersRequired;
  final List<String> recommendationReasons;
  final RecommendationScore aiScore;
}

class RecommendationScore {
  const RecommendationScore({
    this.skillCompatibility = 35,
    this.localDemand = 25,
    this.seasonalDemand = 18,
    this.distance = 8,
    this.experience = 8,
  });
  final int skillCompatibility;
  final int localDemand;
  final int seasonalDemand;
  final int distance;
  final int experience;
}
