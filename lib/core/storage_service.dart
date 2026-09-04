import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> uploadProductImage({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage.from('product-images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: true,
      ),
    );

    return _client.storage.from('product-images').getPublicUrl(path);
  }
}
