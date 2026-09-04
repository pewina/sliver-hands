import '../../core/backend_client.dart';
import '../../core/voice_recorder_service.dart';

class DetectedProfile {
  const DetectedProfile({
    required this.skills,
    required this.experience,
    required this.languages,
    required this.transcript,
  });

  final List<String> skills;
  final String experience;
  final List<String> languages;
  final String transcript;
}

abstract class OnboardingRepository {
  Future<DetectedProfile> analyseIntroduction(String language);
}

class ApiOnboardingRepository implements OnboardingRepository {
  ApiOnboardingRepository({
    BackendClient? client,
    VoiceRecorderService? recorder,
  })  : _client = client ?? BackendClient.instance,
        _recorder = recorder ?? VoiceRecorderService();

  final BackendClient _client;
  final VoiceRecorderService _recorder;

  @override
  Future<DetectedProfile> analyseIntroduction(String language) async {
    final audio = await _recorder.recordFor();

    final result = await _client.postMultipart(
      '/voice/transcribe',
      bytes: audio.bytes,
      filename: audio.filename,
      field: 'audio',
      fields: {
        'language': language,
      },
    );

    final transcript = result['transcript']?.toString().trim() ?? '';
    final error = result['error']?.toString().trim() ?? '';

    if (transcript.isEmpty) {
      throw StateError(
        error.isNotEmpty
            ? error
            : 'We could not transcribe your voice. Please try again.',
      );
    }

    return DetectedProfile(
      skills: (result['skills'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      experience: '${result['experience_years'] ?? 0} years',
      languages: (result['languages'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      transcript: transcript,
    );
  }
}

class MockOnboardingRepository implements OnboardingRepository {
  const MockOnboardingRepository();

  @override
  Future<DetectedProfile> analyseIntroduction(String language) async {
    await Future<void>.delayed(
      const Duration(seconds: 2),
    );

    if (language.toLowerCase() == 'tamil') {
      return const DetectedProfile(
        skills: ['Tailoring', 'Blouse Making', 'Embroidery'],
        experience: '15 years',
        languages: ['Tamil'],
        transcript: 'எனக்கு 15 வருடமாக தையல் வேலை தெரியும். நான் blouse stitching மற்றும் embroidery செய்வேன்.',
      );
    }

    return const DetectedProfile(
      skills: ['Tailoring', 'Blouse Making', 'Embroidery'],
      experience: '15 years',
      languages: ['English'],
      transcript: 'I have 15 years of tailoring experience. I do blouse stitching and embroidery.',
    );
  }
}

class HybridOnboardingRepository implements OnboardingRepository {
  HybridOnboardingRepository({
    ApiOnboardingRepository? api,
    MockOnboardingRepository? mock,
  })  : _api = api ?? ApiOnboardingRepository(),
        _mock = mock ?? const MockOnboardingRepository();

  final ApiOnboardingRepository _api;
  final MockOnboardingRepository _mock;

  @override
  Future<DetectedProfile> analyseIntroduction(String language) async {
    return _api.analyseIntroduction(language);
  }
}