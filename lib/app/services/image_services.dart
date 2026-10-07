import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/widgets/crop_screen.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

Future<Uint8List?> pickImage(BuildContext context) async {
  Uint8List? bytes;

  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;
    if (!context.mounted) return null;

    bytes = await _cropWithImageCropper(pickedFile.path, context);

    if (bytes == null) return null;

    // Android: store at 50% of the cropped image dimensions.
    if (Platform.isAndroid) {
      return _resizeTo50Percent(bytes);
    }

    // iOS / Web: keep your existing 512px max size.
    return _resizeToMax512(bytes);
  } else {
    final typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png', 'webp']);

    final file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file == null) return null;

    final fileBytes = await file.readAsBytes();

    if (!context.mounted) return null;

    // Desktop: don't resize before or after cropping.
    return await _cropWithDesktop(fileBytes, context);
  }
}

Future<Uint8List?> _cropWithImageCropper(String path, BuildContext context) async {
  if (!context.mounted) return null;

  final cropped = await ImageCropper().cropImage(
    sourcePath: path,
    uiSettings: [
      AndroidUiSettings(toolbarTitle: 'Crop'),
      IOSUiSettings(title: 'Crop'),
      WebUiSettings(context: context),
    ],
  );

  if (cropped == null) return null;

  return await cropped.readAsBytes();
}

Future<Uint8List?> _cropWithDesktop(Uint8List bytes, BuildContext context) async {
  return await Navigator.push<Uint8List?>(context, MaterialPageRoute(builder: (_) => CropScreen(imageBytes: bytes)));
}

Uint8List _resizeTo50Percent(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;

  final resized = img.copyResize(
    image,
    width: (image.width * 0.5).round(),
    height: (image.height * 0.5).round(),
    interpolation: img.Interpolation.average,
  );

  return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
}

Uint8List _resizeToMax512(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;

  if (image.width <= 512 && image.height <= 512) {
    return bytes;
  }

  final resized = img.copyResize(
    image,
    width: image.width >= image.height ? 512 : null,
    height: image.height > image.width ? 512 : null,
    interpolation: img.Interpolation.average,
  );

  return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
}
