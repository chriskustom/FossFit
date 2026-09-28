import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/widgets/crop_screen.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_cropper/image_cropper.dart';

Future<Uint8List?> pickImage(BuildContext context) async {
  Uint8List? bytes;

  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;

    if (!context.mounted) return null;
    bytes = await _cropWithImageCropper(pickedFile.path, context);
  } else {
    final typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png', 'webp']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      var fileBytes = downscale(await file.readAsBytes());
      if (!context.mounted) return null;
      bytes = await _cropWithDesktop(fileBytes, context);
    }
  }

  if (bytes == null) return null;

  final image = img.decodeImage(bytes);
  if (image == null) return null;

  final resized = img.copyResize(
    image,
    width: image.width >= image.height ? 512 : null,
    height: image.height > image.width ? 512 : null,
    interpolation: img.Interpolation.average,
  );

  return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
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

Uint8List downscale(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;

  const maxSize = 2048;

  if (image.width <= maxSize && image.height <= maxSize) {
    return bytes;
  }

  final resized = img.copyResize(
    image,
    width: image.width > image.height ? maxSize : null,
    height: image.height >= image.width ? maxSize : null,
  );

  return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
}
