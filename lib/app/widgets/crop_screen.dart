import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/services/app_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';

class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _DesktopCropScreenState();
}

class _DesktopCropScreenState extends State<CropScreen> {
  final CropController _controller = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    final colour = Theme.of(context).colorScheme;
    return AppShell(
      title: 'Crop image',
      floatingActionButton: FloatingActionButton(
        onPressed: AppHaptics.tapWithHaptics(
          context,
          _isCropping
              ? null
              : () {
                  setState(() => _isCropping = true);
                  _controller.crop();
                },
        ),
        child: const Icon(Icons.save),
      ),
      body: Crop(
        baseColor: colour.surface,
        image: widget.imageBytes,
        controller: _controller,
        onCropped: (result) {
          switch (result) {
            case CropSuccess(:final croppedImage):
              // croppedImage is Uint8List
              Navigator.pop(context, croppedImage);

            case CropFailure(:final cause):
              debugPrint('Crop failed: $cause');
          }
        },
      ),
    );
  }
}
