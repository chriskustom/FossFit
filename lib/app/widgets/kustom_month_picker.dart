import 'package:flutter/material.dart';

Future<DateTime?> showKustomMonthYearPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,

  Color? backgroundColor,
  Color? selectedColor,
  Color? selectedTextColor,
  Color? textColor,
  Color? disabledTextColor,

  double width = 320,
  double monthHeight = 42,
  double borderRadius = 16,
  double padding = 16,
}) {
  final initial = DateTime(initialDate.year, initialDate.month);
  final first = DateTime(firstDate.year, firstDate.month);
  final last = DateTime(lastDate.year, lastDate.month);

  final bg = backgroundColor ?? Theme.of(context).colorScheme.surface;
  final selected = selectedColor ?? Theme.of(context).colorScheme.primary;
  final selectedText = selectedTextColor ?? Theme.of(context).colorScheme.onPrimary;
  final text = textColor ?? Theme.of(context).colorScheme.onSurface;
  final disabled = disabledTextColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      var selectedYear = initial.year;
      var selectedMonth = initial.month;

      return StatefulBuilder(
        builder: (context, setState) {
          final months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

          bool isAllowed(int year, int month) {
            final date = DateTime(year, month);
            return !date.isBefore(first) && !date.isAfter(last);
          }

          final yearRange = List.generate(last.year - first.year + 1, (index) => first.year + index);

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
            child: SizedBox(
              width: width,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedYear,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w600),
                        items: yearRange.map((year) {
                          return DropdownMenuItem(value: year, child: Text('$year'));
                        }).toList(),
                        onChanged: (year) {
                          if (year == null) return;

                          setState(() {
                            selectedYear = year;
                            if (!isAllowed(selectedYear, selectedMonth)) {
                              for (var month = 1; month <= 12; month++) {
                                if (isAllowed(selectedYear, month)) {
                                  selectedMonth = month;
                                  break;
                                }
                              }
                            }
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.1,
                      ),
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final allowed = isAllowed(selectedYear, month);
                        final isSelected = selectedYear == initial.year && month == initial.month;

                        return SizedBox(
                          height: monthHeight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: isSelected ? selected : Colors.transparent,
                              foregroundColor: isSelected ? selectedText : text,
                              disabledForegroundColor: disabled,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: allowed
                                ? () {
                                    Navigator.of(dialogContext).pop(DateTime(selectedYear, month));
                                  }
                                : null,
                            child: Text(months[index], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
