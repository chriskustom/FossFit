import 'package:flutter/material.dart';

class NumberPicker extends StatefulWidget {
  final int min;
  final int max;
  final int initial;
  final ValueChanged<int>? onChanged;

  const NumberPicker({super.key, this.min = 0, this.max = 12, this.initial = 0, this.onChanged});

  @override
  State<NumberPicker> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  late int value;

  @override
  void initState() {
    super.initState();
    value = widget.initial.clamp(widget.min, widget.max);
  }

  void _inc() {
    if (value < widget.max) {
      setState(() => value++);
      widget.onChanged?.call(value);
    }
  }

  void _dec() {
    if (value > widget.min) {
      setState(() => value--);
      widget.onChanged?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: value > widget.min ? _dec : null,
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove, size: 16)),
          ),
          SizedBox(
            width: 28, // keeps it compact & stable
            child: Center(child: Text('$value', style: const TextStyle(fontSize: 14))),
          ),
          GestureDetector(
            onTap: value < widget.max ? _inc : null,
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, size: 16)),
          ),
        ],
      ),
    );
  }
}
