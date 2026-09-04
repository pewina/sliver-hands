import '../../core/backend_client.dart';
import 'content_generation_service.dart';

class ApiContentGenerationService implements ContentGenerationService {
  ApiContentGenerationService({BackendClient? client})
      : client = client ?? BackendClient.instance;

  final BackendClient client;

  @override
  Future<ProductContent> generateFromProductPhoto({
    required String productName,
    required String productDescription,
    required String language,
  }) async {
    try {
      final result = await client.postJson(
        '/content/generate',
        {
          'product_name': productName,
          'product_description': productDescription,
          'language': language,
        },
      );

      return ProductContent(
        whatsAppStatus: result['whatsapp_status']?.toString() ?? '',
        instagramCaption: result['instagram_caption']?.toString() ?? '',
        facebookPost: result['facebook_post']?.toString() ?? '',
        posterHeadline: result['poster_headline']?.toString() ?? productName,
        posterSubheadline: result['poster_subheadline']?.toString() ?? '',
        posterCta: result['poster_cta']?.toString() ?? 'WhatsApp to enquire / order',
      );
    } catch (error, stackTrace) {
      // Demo-safe fallback: the poster/content creator must remain usable
      // even if the local FastAPI server, Gemini key, network, or model is
      // temporarily unavailable. Real AI is attempted first; the local
      // generator then produces category-aware copy so the demo never dies
      // on a backend dependency.
      print('CONTENT API FAILED — using local SilverHands fallback: $error');
      print(stackTrace);

      return const MockContentGenerationService().generateFromProductPhoto(
        productName: productName,
        productDescription: productDescription,
        language: language,
      );
    }
  }
}
