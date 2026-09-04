import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

class RecordedAudio {
  const RecordedAudio({
    required this.bytes,
    required this.filename,
  });

  final Uint8List bytes;
  final String filename;
}

/// Records clean audio for speech recognition.
///
/// On Chrome/web we deliberately use record's FILE mode instead of
/// startStream()+manual WAV construction. The web implementation returns a
/// browser Blob URL from stop(); we download that Blob into real WAV bytes and
/// send those bytes to FastAPI. This avoids sample-rate/PCM-size mismatches.
class VoiceRecorderService {
  VoiceRecorderService([AudioRecorder? recorder])
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  Future<RecordedAudio> recordFor({
    Duration duration = const Duration(seconds: 7),
  }) async {
    print('🎤 STEP 1: Checking microphone permission...');

    final permission = await _recorder.hasPermission();
    print('🎤 STEP 2: Permission = $permission');

    if (!permission) {
      throw StateError(
        'Microphone permission denied. Please allow microphone access in Chrome.',
      );
    }

    if (kIsWeb) {
      return _recordWebWav(duration);
    }

    // Keep a PCM stream implementation for native platforms.
    return _recordNativePcm(duration);
  }

  Future<RecordedAudio> _recordWebWav(Duration duration) async {
    print('🎤 WEB: Starting direct WAV recording...');
    print('🎤 WEB: target=${duration.inMilliseconds}ms, sampleRate=16000, mono');

    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      numChannels: 1,
      sampleRate: 16000,
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
    );

    await _recorder.start(config, path: '');
    final startedAt = DateTime.now();
    print('🎤 WEB: Recorder started. Speak now...');

    try {
      await Future<void>.delayed(duration);
    } finally {
      print('🎤 WEB: Stopping recorder...');
    }

    final blobUrl = await _recorder.stop();
    final elapsed = DateTime.now().difference(startedAt);
    print('🎤 WEB: stopped after ${elapsed.inMilliseconds}ms');
    print('🎤 WEB: blobUrl=$blobUrl');

    if (blobUrl == null || blobUrl.isEmpty) {
      throw StateError('Chrome did not return a recorded audio Blob.');
    }

    final response = await http.get(Uri.parse(blobUrl));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Could not read the Chrome audio recording (HTTP ${response.statusCode}).',
      );
    }

    final bytes = Uint8List.fromList(response.bodyBytes);
    print('🎤 WEB: WAV bytes=${bytes.length}');

    if (bytes.length < 44 ||
        bytes[0] != 0x52 || // R
        bytes[1] != 0x49 || // I
        bytes[2] != 0x46 || // F
        bytes[3] != 0x46 || // F
        bytes[8] != 0x57 || // W
        bytes[9] != 0x41 || // A
        bytes[10] != 0x56 || // V
        bytes[11] != 0x45) { // E
      throw StateError('Chrome returned audio, but it is not a valid WAV file.');
    }

    final header = ByteData.sublistView(bytes);
    final sampleRate = header.getUint32(24, Endian.little);
    final channels = header.getUint16(22, Endian.little);
    final bits = header.getUint16(34, Endian.little);

    print('🎤 WEB: WAV sampleRate=$sampleRate channels=$channels bits=$bits');

    return RecordedAudio(
      bytes: bytes,
      filename: 'silverhands_voice_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
  }

  Future<RecordedAudio> _recordNativePcm(Duration duration) async {
    print('🎤 NATIVE: Starting PCM stream...');

    final chunks = <Uint8List>[];
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        numChannels: 1,
        sampleRate: 16000,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    final subscription = stream.listen((chunk) {
      chunks.add(Uint8List.fromList(chunk));
    });

    try {
      await Future<void>.delayed(duration);
    } finally {
      await _recorder.stop();
      await subscription.cancel();
    }

    final totalBytes = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    if (totalBytes == 0) {
      throw StateError('Microphone returned zero audio bytes.');
    }

    final pcm = Uint8List(totalBytes);
    var offset = 0;
    for (final chunk in chunks) {
      pcm.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    final wav = _createWavFile(
      pcmData: pcm,
      sampleRate: 16000,
      channels: 1,
      bitsPerSample: 16,
    );

    return RecordedAudio(
      bytes: wav,
      filename: 'silverhands_voice_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
  }

  Uint8List _createWavFile({
    required Uint8List pcmData,
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final buffer = ByteData(44 + pcmData.length);

    void writeString(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        buffer.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    buffer.setUint32(4, 36 + pcmData.length, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, channels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);
    writeString(36, 'data');
    buffer.setUint32(40, pcmData.length, Endian.little);

    final result = buffer.buffer.asUint8List();
    result.setRange(44, 44 + pcmData.length, pcmData);
    return result;
  }

  Future<void> dispose() => _recorder.dispose();
}
