import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class ImageFile {
  final String name;
  final Uint8List bytes;

  ImageFile({required this.name, required this.bytes});
}

class ImagePage extends StatefulWidget {
  final ImageFile image;

  const ImagePage({super.key, required this.image});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  static const double _minScale = 1.0;
  static const double _maxScale = 5.0;

  final TransformationController _transformationController = TransformationController();

  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();

    _transformationController.addListener(_handleTransformation);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformation);
    _transformationController.dispose();
    super.dispose();
  }

  void _handleTransformation() {
    final scale = _transformationController.value.getMaxScaleOnAxis();

    final zoomed = scale > _minScale + 0.001;

    if (zoomed != _isZoomed) {
      setState(() {
        _isZoomed = zoomed;
      });
    }
  }

  void _reset() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(path.basenameWithoutExtension(widget.image.name)),
        actions: [IconButton(tooltip: 'Reset', onPressed: _reset, icon: const Icon(Icons.refresh))],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,

        minScale: _minScale,
        maxScale: _maxScale,
        panEnabled: _isZoomed,

        scaleEnabled: true,

        boundaryMargin: EdgeInsets.zero,

        clipBehavior: Clip.none,
        constrained: true,

        child: Center(
          child: Image.memory(widget.image.bytes, fit: BoxFit.contain, filterQuality: FilterQuality.high),
        ),
      ),
    );
  }
}
