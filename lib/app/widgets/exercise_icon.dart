import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';

class ExerciseIcon extends StatelessWidget {
  final Exercise exercise;
  final bool showImages;
  const ExerciseIcon({super.key, required this.exercise, this.showImages = false});
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: Container(
        width: 24,
        height: 24,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: showImages && exercise.hasImage() == true
              ? DecorationImage(
                  image: MemoryImage(exercise.image ?? Uint8List(0)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Color.fromARGB(100, 0, 0, 0), BlendMode.darken),
                )
              : null,
        ),
        child: showImages && exercise.hasImage() == true
            ? null
            : Text(
                exercise.name.isNotEmpty ? exercise.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
      ),
    );
  }
}
