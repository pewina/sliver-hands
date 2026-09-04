import '../data/mock/mock_data.dart';
import '../data/models/opportunity.dart';
import '../features/collaboration/collaboration_models.dart';

/// In-memory state used by the hackathon demo.
///
/// The important part is that the profile is now the single source of truth:
/// voice -> detected skills -> profile -> recommendations -> matches -> collaboration.
class DemoStore {
  DemoStore._();
  static final DemoStore instance = DemoStore._();

  Map<String, dynamic> profile = <String, dynamic>{
    'full_name': 'SilverHands Member',
    'display_name': 'SilverHands Member',
    'age': null,
    'location': 'Chennai, Tamil Nadu',
    'language': 'Tamil',
    'experience': '0 years',
    'experience_years': 0,
    'skills': <String>['Cooking'],
    'headline': 'Skilled home-based livelihood creator',
    'bio': 'Your SilverHands profile will be personalised from the skills you share.',
    'transcript': '',
    'verified': true,
    'aadhaar_verified': true,
  };

  final Set<String> seenOpportunityIds = <String>{};
  final Set<String> interestedOpportunityIds = <String>{};

  int publishedProducts = 0;
  int ordersCompleted = 0;
  int earnings = 0;
  bool notificationEnabled = true;

  List<String> get skills => (profile['skills'] as List? ?? const [])
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList();

  int get experienceYears =>
      int.tryParse(profile['experience_years']?.toString() ?? '') ?? 0;

  String get language => profile['language']?.toString() ?? 'English';

  void saveProfile({
    required String name,
    required String location,
    required String language,
    required String experience,
    required List<String> skills,
    String transcript = '',
  }) {
    final years = _extractYears(experience);
    final cleanSkills = skills
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    profile = <String, dynamic>{
      ...profile,
      'full_name': name.trim().isEmpty ? 'SilverHands Member' : name.trim(),
      'display_name': name.trim().isEmpty ? 'SilverHands Member' : name.trim(),
      'location': location,
      'language': language,
      'experience': '$years years',
      'experience_years': years,
      'skills': cleanSkills,
      'transcript': transcript,
      'headline': _headline(cleanSkills, years),
      'bio': _bio(cleanSkills, years, location),
    };
  }

  void applyGeneratedProfile({required String headline, required String bio}) {
    profile['headline'] = headline;
    profile['bio'] = bio;
  }

  void updateVoiceProfile({
    required List<String> skills,
    required String experience,
    required List<String> languages,
    required String transcript,
  }) {
    final selectedLanguage = languages.isNotEmpty ? languages.first : language;
    saveProfile(
      name: profile['full_name']?.toString() ?? 'SilverHands Member',
      location: profile['location']?.toString() ?? 'Chennai, Tamil Nadu',
      language: selectedLanguage,
      experience: experience,
      skills: skills,
      transcript: transcript,
    );
  }

  List<Opportunity> get recommendedOpportunities {
    final userSkills = skills;

    final scored = opportunities.map((opportunity) {
      final overlap = _skillOverlap(userSkills, opportunity.skills);
      final skillRatio = opportunity.skills.isEmpty
          ? 0.0
          : overlap / opportunity.skills.length;

      // Strong skill match dominates. Demand, seasonality and verification
      // make the recommendation feel intelligent rather than random.
      final score = (skillRatio * 62 +
              opportunity.baseDemandScore +
              opportunity.baseSeasonalScore +
              (opportunity.verified ? 5 : 0) +
              (experienceYears > 0 ? 3 : 0))
          .round()
          .clamp(0, 99)
          .toInt();

      final reasons = <String>[];
      if (overlap > 0) {
        reasons.add('Matches your ${_prettySkill(userSkills.firstWhere(
          (userSkill) => _skillMatches(userSkill, opportunity.skills),
          orElse: () => opportunity.skills.first,
        ))} skill');
      }
      if (opportunity.baseDemandScore >= 12) {
        reasons.add('High local demand');
      }
      if (opportunity.baseSeasonalScore >= 8) {
        reasons.add('Good seasonal opportunity');
      }
      reasons.add('Flexible, home-friendly work');

      return Opportunity(
        id: opportunity.id,
        title: opportunity.title,
        subtitle: opportunity.subtitle,
        location: opportunity.location,
        price: opportunity.price,
        seller: opportunity.seller,
        category: opportunity.category,
        imageUrl: opportunity.imageUrl,
        skills: opportunity.skills,
        matchScore: score,
        verified: opportunity.verified,
        description: opportunity.description,
        distance: opportunity.distance,
        demandLevel: opportunity.demandLevel,
        sellersRequired: opportunity.sellersRequired,
        recommendationReasons: reasons,
        aiScore: RecommendationScore(
          skillCompatibility: (skillRatio * 50).round(),
          localDemand: opportunity.baseDemandScore.clamp(0, 20).toInt(),
          seasonalDemand: opportunity.baseSeasonalScore.clamp(0, 15).toInt(),
          distance: 8,
          experience: experienceYears > 0 ? 7 : 2,
        ),
      );
    }).toList();

    scored.sort((a, b) {
      final skillA = _skillOverlap(userSkills, a.skills);
      final skillB = _skillOverlap(userSkills, b.skills);
      if (skillA != skillB) return skillB.compareTo(skillA);
      return b.matchScore.compareTo(a.matchScore);
    });

    return scored;
  }

  List<Opportunity> get interestedOpportunities {
    final ranked = recommendedOpportunities;
    return opportunities
        .where((o) => interestedOpportunityIds.contains(o.id))
        .map((o) {
          for (final item in ranked) {
            if (item.id == o.id) return item;
          }
          return _toOpportunity(o);
        })
        .toList();
  }

  List<Opportunity> get availableOpportunities => recommendedOpportunities
      .where((o) => o.id == null || !seenOpportunityIds.contains(o.id))
      .toList();

  void decide(String id, bool interested) {
    seenOpportunityIds.add(id);
    if (interested) {
      interestedOpportunityIds.add(id);
    } else {
      interestedOpportunityIds.remove(id);
    }
  }

  void undo(String id) {
    seenOpportunityIds.remove(id);
    interestedOpportunityIds.remove(id);
  }

  void publish() => publishedProducts++;

  CollaborativeOrder collaborationFor(Opportunity opportunity) {
    final total = opportunity.sellersRequired > 1
        ? (opportunity.sellersRequired >= 4 ? 120 : 60)
        : 1;

    final matchingPool = <SquadSeller>[];
    final candidatePool = _collaborationPoolFor(opportunity);
    var remaining = total;

    // The current user is always the first member of the squad. Their
    // voice-identified skills are explicitly carried into the collaboration.
    final myContribution = total >= 40 ? 30 : total;
    matchingPool.add(
      SquadSeller(
        name: 'You',
        contribution: myContribution,
        skills: skills.isEmpty ? opportunity.skills.join(', ') : skills.join(', '),
        location: profile['location']?.toString() ?? 'Chennai',
        reliability: 100,
      ),
    );
    remaining -= myContribution;

    for (final seller in candidatePool) {
      if (remaining <= 0) break;
      final contribution = remaining >= 40 ? 30 : remaining;
      matchingPool.add(
        SquadSeller(
          name: seller.name,
          contribution: contribution,
          skills: seller.skills,
          location: seller.location,
          reliability: seller.reliability,
        ),
      );
      remaining -= contribution;
    }

    if (matchingPool.isEmpty) {
      matchingPool.add(
        SquadSeller(
          name: 'SilverHands Partner',
          contribution: total,
          skills: opportunity.skills.join(', '),
          location: 'Nearby, Chennai',
          reliability: 94,
        ),
      );
    }

    return CollaborativeOrder(
      title: opportunity.title,
      totalUnits: total,
      sellers: matchingPool,
    );
  }

  void resetDemo() {
    seenOpportunityIds.clear();
    interestedOpportunityIds.clear();
    publishedProducts = 0;
    ordersCompleted = 0;
    earnings = 0;
    profile = <String, dynamic>{
      'full_name': 'SilverHands Member',
      'display_name': 'SilverHands Member',
      'location': 'Chennai, Tamil Nadu',
      'language': 'Tamil',
      'experience': '0 years',
      'experience_years': 0,
      'skills': <String>['Cooking'],
      'headline': 'Skilled home-based livelihood creator',
      'bio': 'Your SilverHands profile will be personalised from the skills you share.',
      'transcript': '',
      'verified': true,
      'aadhaar_verified': true,
    };
  }


  Opportunity _toOpportunity(DemoOpportunity o) => Opportunity(
        id: o.id,
        title: o.title,
        subtitle: o.subtitle,
        location: o.location,
        price: o.price,
        seller: o.seller,
        category: o.category,
        imageUrl: o.imageUrl,
        skills: o.skills,
        matchScore: 0,
        verified: o.verified,
        description: o.description,
        distance: o.distance,
        demandLevel: o.demandLevel,
        sellersRequired: o.sellersRequired,
      );

  int _skillOverlap(List<String> userSkills, List<String> opportunitySkills) =>
      opportunitySkills.where((wanted) => userSkills.any((have) => _skillEquivalent(have, wanted))).length;

  bool _skillMatches(String userSkill, List<String> opportunitySkills) =>
      opportunitySkills.any((wanted) => _skillEquivalent(userSkill, wanted));

  bool _skillEquivalent(String a, String b) {
    final x = a.toLowerCase().trim();
    final y = b.toLowerCase().trim();
    if (x == y) return true;

    const groups = <String, Set<String>>{
      'cooking': {'cooking', 'home cooking', 'traditional cooking', 'meal prep', 'food preparation'},
      'pickle': {'pickle making', 'pickles', 'pickle preparation'},
      'tailoring': {'tailoring', 'stitching', 'sewing', 'blouse making', 'alterations'},
      'embroidery': {'embroidery', 'hand embroidery', 'needlework', 'handicrafts'},
      'handicrafts': {'handicrafts', 'crafts', 'handmade', 'embroidery', 'pottery'},
      'teaching': {'teaching', 'tutoring', 'mentoring', 'storytelling', 'language training'},
      'gardening': {'gardening', 'plant care', 'terrace gardening', 'nursery'},
      'childcare': {'childcare', 'child care', 'babysitting', 'caregiving'},
    };

    for (final values in groups.values) {
      if (values.contains(x) && values.contains(y)) return true;
    }
    return false;
  }

  List<_Partner> _collaborationPoolFor(Opportunity opportunity) {
    final isCooking = opportunity.skills.any((s) => _skillEquivalent('Cooking', s));
    final isTailoring = opportunity.skills.any((s) => _skillEquivalent('Tailoring', s));
    final isHandmade = opportunity.skills.any((s) => _skillEquivalent('Handicrafts', s));

    if (isTailoring) {
      return const [
        _Partner('Meena', 'Tailoring, blouse stitching', 'Adyar, Chennai', 97),
        _Partner('Revathi', 'Embroidery, finishing', 'T. Nagar, Chennai', 95),
        _Partner('Shanthi', 'Alterations, stitching', 'Velachery, Chennai', 94),
      ];
    }
    if (isHandmade) {
      return const [
        _Partner('Revathi', 'Handicrafts, embroidery', 'T. Nagar, Chennai', 96),
        _Partner('Nirmala', 'Crafts, packaging', 'Mylapore, Chennai', 95),
        _Partner('Meena', 'Stitching, handmade goods', 'Adyar, Chennai', 93),
      ];
    }
    if (isCooking) {
      return const [
        _Partner('Lakshmi', 'Traditional cooking, snacks', 'Mylapore, Chennai', 98),
        _Partner('Meena', 'Savouries, packaging', 'Adyar, Chennai', 96),
        _Partner('Revathi', 'Gift packing, crafts', 'T. Nagar, Chennai', 94),
        _Partner('Shanthi', 'Traditional cooking, pickles', 'Velachery, Chennai', 97),
      ];
    }
    return const [
      _Partner('Meena', 'Teaching, mentoring', 'Adyar, Chennai', 96),
      _Partner('Revathi', 'Community support', 'T. Nagar, Chennai', 94),
    ];
  }

  int _extractYears(String value) {
    final digits = RegExp(r'\d+').firstMatch(value)?.group(0);
    return int.tryParse(digits ?? '') ?? 0;
  }

  String _headline(List<String> skills, int years) {
    if (skills.isEmpty) return 'Skilled SilverHands creator';
    final first = skills.first;
    return years > 0 ? 'Experienced $first specialist' : '$first specialist';
  }

  String _bio(List<String> skills, int years, String location) {
    final skillText = skills.isEmpty ? 'practical skills' : skills.join(', ');
    final experience = years > 0 ? '$years years of experience' : 'hands-on experience';
    return 'A SilverHands creator from $location with $experience in $skillText, ready for flexible livelihood opportunities.';
  }

  String _prettySkill(String value) => value.trim();
}

class _Partner {
  const _Partner(this.name, this.skills, this.location, this.reliability);
  final String name;
  final String skills;
  final String location;
  final int reliability;
}
