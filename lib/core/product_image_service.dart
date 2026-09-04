import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ProductImageService {
  const ProductImageService();

  Future<({Uint8List bytes, String name, String contentType})?> pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final name = file.name;
    final extension = name.contains('.') ? name.split('.').last : 'jpg';
    final contentType = extension.toLowerCase() == 'png'
        ? 'image/png'
        : 'image/jpeg';

    return (bytes: bytes, name: name, contentType: contentType);
  }
}
