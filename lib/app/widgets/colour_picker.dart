import 'package:flutter/material.dart';

class ColorBarPicker extends StatefulWidget {
  const ColorBarPicker({super.key, this.initialColor, required this.primaryColor, this.onChanged});

  final String? initialColor;
  final Color primaryColor;
  final ValueChanged<Color>? onChanged;

  @override
  State<ColorBarPicker> createState() => _ColorBarPickerState();
}

class _ColorBarPickerState extends State<ColorBarPicker> {
  late double _value;
  late Color _color;

  @override
  void initState() {
    super.initState();

    _color = _parseColor(widget.initialColor) ?? widget.primaryColor;
    _value = _colorToPosition(_color);
  }

  Color? _parseColor(String? value) {
    if (value == null) return null;

    final argb = int.tryParse(value);
    if (argb == null) return null;

    return Color(argb);
  }

  double _colorToPosition(Color color) {
    final hsv = HSVColor.fromColor(color);

    return hsv.hue / 360.0;
  }

  Color _positionToColor(double position) {
    final hue = position * 360.0;

    return HSVColor.fromAHSV(1.0, hue % 360.0, 1.0, 1.0).toColor();
  }

  void _onChanged(double value) {
    final color = _positionToColor(value);

    setState(() {
      _value = value;
      _color = color;
    });

    widget.onChanged?.call(color);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red],
          ).withOpacity(.85),
        ),
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 20,

            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,

            thumbColor: widget.primaryColor,

            overlayColor: widget.primaryColor.withValues(alpha: 0.20),

            thumbShape: const RoundSliderThumbWithBorder(enabledThumbRadius: 7.5),

            trackShape: const FullWidthTrackShape(),
          ),
          child: Slider(min: 0.0, max: 1.0, value: _value, onChanged: _onChanged),
        ),
      ),
    );
  }
}

class RoundSliderThumbWithBorder extends SliderComponentShape {
  final double enabledThumbRadius;
  final double? disabledThumbRadius;

  const RoundSliderThumbWithBorder({this.enabledThumbRadius = 10.0, this.disabledThumbRadius});

  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(isEnabled ? enabledThumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Color thumbColor = sliderTheme.thumbColor ?? Colors.white;
    final Color borderColor = Colors.black.withAlpha(150);
    final double borderWidth = 2.0;

    final Paint fillPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final Tween<double> radiusTween = Tween<double>(begin: _disabledThumbRadius, end: enabledThumbRadius);
    final double radius = radiusTween.evaluate(enableAnimation);

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);
  }
}

class FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const FullWidthTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2;

    return Rect.fromLTWH(offset.dx, offset.dy + (parentBox.size.height - trackHeight) / 2, parentBox.size.width, trackHeight);
  }
}
