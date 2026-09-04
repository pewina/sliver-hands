import 'dart:async';

String inferBusinessCategory({
  required String productName,
  required String skills,
  required String selectedCategory,
}) {
  final text = '$productName $skills $selectedCategory'.toLowerCase();
  if (RegExp(r'pickle|cooking|food|bakery|catering|sweets|snack|meal').hasMatch(text)) return 'Food / Culinary';
  if (RegExp(r'tailor|stitch|embroid|sewing|fashion|blouse|dress|clothing').hasMatch(text)) return 'Tailoring / Fashion';
  if (RegExp(r'handicraft|craft|pottery|art|weaving|basket|jewell').hasMatch(text)) return 'Handicrafts / Art';
  if (RegExp(r'tutor|teach|education|class|math|english|school').hasMatch(text)) return 'Tutoring / Education';
  if (RegExp(r'beauty|salon|makeup|hair|mehendi|henna|skin').hasMatch(text)) return 'Beauty / Salon';
  if (RegExp(r'garden|plant|nursery|flower|terrace|organic').hasMatch(text)) return 'Gardening / Plants';
  if (RegExp(r'repair|plumb|electric|carp|clean|home service').hasMatch(text)) return 'Home Services';
  if (RegExp(r'photo|camera|video|design|creative').hasMatch(text)) return 'Creative Services';
  if (RegExp(r'traditional|classical|dance|music|culture|rangoli|kolam').hasMatch(text)) return 'Traditional Arts';
  return selectedCategory == 'Service' ? 'Local Services' : 'Products & Services';
}

String categoryHeadline(String category, String offering) {
  final o = offering.trim().isEmpty ? 'Your craft' : offering.trim();
  switch (category) {
    case 'Food / Culinary': return 'Freshly Made. Just for You.';
    case 'Tailoring / Fashion': return 'Stitched With Skill.';
    case 'Handicrafts / Art': return 'Handcrafted With Care.';
    case 'Tutoring / Education': return 'Learn. Grow. Succeed.';
    case 'Beauty / Salon': return 'Feel Confident. Feel Beautiful.';
    case 'Gardening / Plants': return 'Bring Nature Home.';
    case 'Home Services': return 'Trusted Skills. Reliable Service.';
    case 'Creative Services': return 'Bring Your Ideas to Life.';
    case 'Traditional Arts': return 'Tradition, Crafted With Heart.';
    default: return o.length > 28 ? 'Made With Skill. Made For You.' : o;
  }
}


class ProductContent {
  const ProductContent({
    required this.whatsAppStatus,
    required this.instagramCaption,
    required this.facebookPost,
    required this.posterHeadline,
    required this.posterSubheadline,
    required this.posterCta,
  });

  final String whatsAppStatus;
  final String instagramCaption;
  final String facebookPost;
  final String posterHeadline;
  final String posterSubheadline;
  final String posterCta;
}

abstract class ContentGenerationService {
  Future<ProductContent> generateFromProductPhoto({
    required String productName,
    required String productDescription,
    required String language,
  });
}

class MockContentGenerationService implements ContentGenerationService {
  const MockContentGenerationService();

  @override
  Future<ProductContent> generateFromProductPhoto({
    required String productName,
    required String productDescription,
    required String language,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    final category = inferBusinessCategory(
      productName: productName,
      skills: productDescription,
      selectedCategory: 'Product',
    );
    final headline = categoryHeadline(category, productName);
    final cta = category == 'Tutoring / Education' ? 'ENQUIRE NOW' :
        category == 'Home Services' ? 'BOOK NOW' :
        category == 'Creative Services' ? 'CONTACT NOW' :
        category == 'Products & Services' ? 'VIEW PROFILE' : 'ORDER / ENQUIRE NOW';

    return ProductContent(
      whatsAppStatus:
          '✨ $headline\n\n'
          '$productName\n'
          '$productDescription\n\n'
          'Made with care by a SilverHands creator.\n'
          '📩 Message me on WhatsApp to enquire, order or book.\n\n'
          '#SilverHands #SupportLocal #MadeWithSkill',
      instagramCaption:
          '$headline\n\n'
          '$productName\n'
          '$productDescription\n\n'
          'Discover a skilled local creator through SilverHands.\n'
          '#SilverHands #SupportLocal #MadeWithCare',
      facebookPost:
          '$headline\n\n'
          'Discover $productName from a SilverHands creator.\n\n'
          '$productDescription\n\n'
          'Contact them through their SilverHands profile.',
      posterHeadline: headline,
      posterSubheadline: '$productName • $category',
      posterCta: cta,
    );
  }
}
