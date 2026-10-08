import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/db/models/features/exercise_model.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';
import 'package:intl/intl.dart';

class StringUtils {
  static SortBy parseSortBy(String? value) {
    switch (value) {
      case 'name':
        return SortBy.name;
      case 'date':
        return SortBy.date;
      default:
        return SortBy.date;
    }
  }

  static SortOrder parseOrder(String? value) {
    switch (value) {
      case 'asc':
        return SortOrder.asc;
      case 'desc':
        return SortOrder.desc;
      default:
        return SortOrder.desc;
    }
  }

  static GroupBy parseGroupBy(String? value) {
    switch (value) {
      case 'day':
        return GroupBy.day;
      case 'week':
        return GroupBy.week;
      default:
        return GroupBy.day;
    }
  }
}

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}

extension RandomItem<T> on List<T> {
  T get randomItem => this[Random().nextInt(length)];
}

void selectAll(TextEditingController controller) => controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);

String toString(double value) {
  final str = value.toStringAsFixed(2);
  if (str.endsWith('.0')) return str.substring(0, str.length - 2);
  if (str.endsWith('.00')) return str.substring(0, str.length - 3);
  return str;
}

String formatDateWithOrdinal(DateTime date) {
  String suffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  return '${DateFormat('EEE').format(date)}, '
      '${date.day}${suffix(date.day)} '
      '${DateFormat('MMM yy').format(date)}';
}

extension SortedExerciseGymSets on List<MapEntry<Exercise, GymSet?>> {
  void sortByOrder(SortBy sortBy, SortOrder sortOrder) {
    sort((a, b) {
      int result;
      switch (sortBy) {
        case SortBy.name:
          result = a.key.name.toLowerCase().compareTo(b.key.name.toLowerCase());
          break;
        case SortBy.date:
          result = a.value != null && b.value != null ? a.value!.created.compareTo(b.value!.created) : -1;
          break;
      }

      return sortOrder == SortOrder.asc ? result : -result;
    });
  }
}

///## An extension on the [String] class that provides methods for transforming text.
///
/// This extension adds various text transformation methods such as converting a string
/// to title case, small case, camel case, hyphen case, snake case, and capitalizing
/// the first letter of each word. These methods can be used to modify string formats
/// for various use cases.

extension StringExtensions on String {
  //!~~~~~~~~~~~~~~~~~~~~~~~ Title Case ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Converts the string to title case.
  ///* This method splits the string by spaces, hyphens, or underscores, and capitalizes
  /// each word while making other letters lowercase.
  ///* Returns a new string with each word capitalized and separated by a space.
  ///
  ///### Example:
  /// ```dart
  /// "hello_world".toTitleCase; // Returns "Hello World"
  /// ```
  ///
  ///### Returns: A [String] in title case.
  String get toTitleCase {
    // Split the string by non-alphabetic characters (spaces, underscores, etc.)
    List<String> words =
        replaceAll(RegExp(r'[_-]'), ' ') // Replace underscores and hyphens with spaces
            .split(' ') // Split by spaces
            .map((word) => word.trim()) // Remove any leading or trailing spaces
            .where((word) => word.isNotEmpty) // Remove empty words if any
            .toList();

    // Capitalize the first letter of each word and join them back together
    return words.map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '').join(' ');
  }

  //!~~~~~~~~~~~~~~~~~~~~~~~ Small Case Text ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Converts the string to small case text.
  ///* This method splits the string by spaces, hyphens, or underscores, and converts
  /// each word to lowercase.
  ///* Returns a new string with all letters in lowercase, separated by spaces.
  ///
  ///### Example:
  /// ```dart
  /// "Hello_World".toSmallCaseText; // Returns "hello world"
  /// ```
  ///
  ///### Returns: A [String] in small case text.
  String get toSmallCaseText {
    List<String> words = split(RegExp(r'[-_]'));
    for (int i = 0; i < words.length; i++) {
      words[i] = words[i].isEmpty ? '' : words[i].toLowerCase();
    }
    return words.join(' ');
  }

  //!~~~~~~~~~~~~~~~~~~~~~~~ Small Case ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Converts the string to small case text.
  ///* This method splits the string by spaces, hyphens, or underscores, and converts
  /// each word to lowercase.
  ///* Returns a new string with all letters in lowercase, separated by spaces.
  ///
  ///### Example:
  /// ```dart
  /// "Hello_World".toSmallCaseText; // Returns "hello world"
  /// ```
  ///
  ///### Returns: A [String] in small case text.
  String get toSmallCase {
    List<String> words = split(RegExp(r'[-_]'));
    for (int i = 0; i < words.length; i++) {
      words[i] = words[i].isEmpty ? '' : words[i].toLowerCase();
    }
    return words.join('');
  }

  //!~~~~~~~~~~~~~~~~~~~~~~~ Pascal Case ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Capitalizes the first letter of each word in the string.
  ///* This method splits the string by spaces, hyphens, or underscores and capitalizes
  /// the first letter of each word while making the rest of the letters lowercase.
  ///* Returns a new string where each word's first letter is capitalized, and the rest
  /// of the word is in lowercase.
  ///
  ///### Example:
  /// ```dart
  /// "hello world".toPascalCase; // Returns "HelloWorld"
  /// ```
  ///
  ///### Returns: A [String] with the first letter of each word capitalized.
  String get toPascalCase {
    return split(RegExp(r'[\s_-]+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join('');
  }

  //!~~~~~~~~~~~~~~~~~~~~~~~ Kebab Case ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Converts the string to hyphen case.
  ///* This method splits the string by spaces, hyphens, or underscores and then joins
  /// the words with kebab in lowercase.
  ///* Returns a new string in kebab case, with all words in lowercase and separated by hyphens.
  ///
  ///### Example:
  /// ```dart
  /// "Hello World".toKebabCase; // Returns "hello-world"
  /// ```
  ///
  ///### Returns: A [String] in kebab case.
  String get toKebabCase {
    return split(RegExp(r'[\s_-]+')).map((word) => word.toLowerCase()).join('-');
  }

  //!~~~~~~~~~~~~~~~~~~~~~~~ Camel Case ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Converts the string to camel case.
  ///* This method splits the string by spaces, hyphens, or underscores and converts
  /// it into camel case, where the first word is lowercase and all subsequent words
  /// start with an uppercase letter.
  ///* Returns a new string in camel case.
  ///
  ///### Example:
  /// ```dart
  /// "hello world".toCamelCase; // Returns "helloWorld"
  /// ```
  ///
  ///### Returns: A [String] in camel case.
  String get toCamelCase {
    List<String> words = split(RegExp(r'[\s_-]+'));
    if (words.isEmpty) return this;
    return words.first.toLowerCase() +
        words
            .skip(1)
            .map((word) {
              if (word.isEmpty) return '';
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            })
            .join('');
  }

  //!~~~~~~~~~~~~~~~~~~~~~~~ Snake Case ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Converts the string to snake case.
  ///* This method splits the string by spaces, hyphens, or underscores and joins
  /// the words with underscores in lowercase.
  ///* Returns a new string in snake case, with all words in lowercase and separated by underscores.
  ///
  ///### Example:
  /// ```dart
  /// "Hello World".toSnakeCase; // Returns "hello_world"
  /// ```
  ///
  ///### Returns: A [String] in snake case.
  String get toSnakeCase {
    return split(RegExp(r'[\s_-]+')).map((word) => word.toLowerCase()).join('_');
  }

  ///!~~~~~~~~~~~~~~~~~~~~~~~ Initials ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Returns the initials of the words in the string, up to a maximum of three.
  ///
  /// This method splits the string by spaces and extracts the first letter of each
  /// word, converting it to uppercase. It returns a string containing the
  /// initials.  Only the first three words are considered.
  ///
  /// Example:
  /// ```dart
  /// "John Doe".initials; // Returns "JD"
  /// "Jane Mary Doe".initials; // Returns "JMD"
  /// "A B C D".initials; // Returns "ABC"
  /// "  John Doe".initials; // Returns "JD" (handles leading spaces)
  /// "".initials; // Returns "" (handles empty string)
  /// "John".initials; // Returns "J"
  /// ```
  ///
  /// Returns: A [String] containing the initials.
  String get initials {
    List<String> words = split(' ');
    String initials = '';
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (i < 3) {
        initials += (word.isNotEmpty ? word[0] : '').toUpperCase();
      }
    }
    return initials;
  }

  ///!~~~~~~~~~~~~~~~~~~~~~~~ Currency Symbol ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///
  /// Returns a new string with the currency symbol prefixed to the original string.
  ///
  /// we can set any currency symbol statically or dynamically as per requirement.
  /// Example:
  /// ```dart
  /// "100".withCurrencySymbol; // Returns "₹ 100"
  /// "1000.50".withCurrencySymbol; // Returns "₹ 1000.50"
  /// "".withCurrencySymbol; // Returns "₹ "
  /// ```
  ///
  /// Returns:
  ///   A [String] with the currency symbol.
  String get withCurrencySymbol => '₹ $this';

  String? validate(String? v) {
    if ((v ?? '').isEmpty) {
      return '$this is required'.tran;
    } else {
      return null;
    }
  }

  ///!~~~~~~~~~~~~~~~~~~~~~~~ string to enum ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Converts a string to an enum value of type `T`.
  ///
  /// This method attempts to find an enum value in the provided list
  /// `enumValues` that matches the string representation of the enum's name.
  /// The comparison is done against the part of the enum value's string
  /// representation after the last dot (`.`).  If no match is found, it
  /// returns `null`.
  ///
  /// Example:
  /// ```dart
  /// enum Color { red, green, blue }
  ///
  /// "red".toEnum(Color.values); // Returns Color.red
  /// "green".toEnum(Color.values); // Returns Color.green
  /// "blue".toEnum(Color.values); // Returns Color.blue
  /// "RED".toEnum(Color.values); // Returns null (case-sensitive)
  /// "purple".toEnum(Color.values); // Returns null (not in enum)
  /// ```
  ///
  /// Type parameters:
  ///   * `T`: The enum type.
  ///
  /// Parameters:
  ///   * `enumValues`: A list of enum values of type `T` to search within.
  ///
  /// Returns:
  ///   The enum value of type `T` that matches the string, or `null` if no match is found.
  T? toEnum<T>(List<T> enumValues) => enumValues.firstWhereOrNull((e) => e.toString().split('.').last == this);

  ///!~~~~~~~~~~~~~~~~~~~~~~~ Hex to Color ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Converts a hexadecimal color string to a [Color] object.
  ///
  /// This method parses a hexadecimal string representation of a color and
  /// returns a corresponding [Color] object.  The string can optionally
  /// include a leading `#` character.  It supports both 6-digit (RGB) and
  /// 8-digit (ARGB) hex codes. If the input string is invalid, it returns
  /// the provided `defaultColor`.
  ///
  /// Example:
  /// ```dart
  /// "#FF0000".hexToColor(); // Returns Color(0xffff0000) (Red)
  /// "FF0000".hexToColor();  // Returns Color(0xffff0000) (Red)
  /// "#AARRGGBB".hexToColor(); //Returns Color(0xAARRGGBB)
  /// "000000".hexToColor(); // Returns Color(0xff000000) (Black - default)
  /// "invalid".hexToColor(); // Returns Color(0xff000000) (Black - default)
  /// "#FF000080".hexToColor(); // Returns Color(0xff000080) (Red with 50% alpha)
  /// ```
  ///
  /// Parameters:
  ///   * `defaultColor`: The [Color] to return if the hex string is invalid.
  ///     Defaults to black (0xff000000).
  ///
  /// Returns:
  ///   A [Color] object representing the parsed hex color, or `defaultColor`
  ///   if the input string is invalid.
  Color hexToColor({Color defaultColor = const Color(0xff000000)}) {
    String hexString = this;
    hexString = hexString.replaceAll('#', '');
    if (hexString.length != 6 && hexString.length != 8) {
      return defaultColor;
    }
    if (hexString.length == 6) {
      hexString = 'ff$hexString';
    }
    try {
      int hexValue = int.parse(hexString, radix: 16);
      return Color(hexValue);
    } catch (e) {
      return defaultColor; // Return defaultColor in the catch block as well
    }
  }

  //! Extension for translation to be used later when required
  String get tran {
    // transalatedKeyValuData[this] = this;
    // ColoredLog(jsonEncode(transalatedKeyValuData));
    // return this;
    // getNewKeys();
    return this;
  }

  ///!~~~~~~~~~~~~~~~~~~~~~~~ Obfuscate ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Obfuscates a string by replacing the middle characters with asterisks.
  ///
  /// If the string's length is less than or equal to 3, it returns the
  /// original string unchanged. Otherwise, it keeps the first three and
  /// last three characters and replaces the characters in between with
  /// asterisks.
  ///
  /// Example:
  /// ```dart
  /// "1234567890".obfuscate; // Returns "123*******0"
  /// "abcdef".obfuscate;   // Returns "abc***f"
  /// "abc".obfuscate;      // Returns "abc" (length <= 3)
  /// "ab".obfuscate;       // Returns "ab"  (length <= 3)
  /// "a".obfuscate;        // Returns "a" (length <= 3)
  /// "".obfuscate;         // Returns "" (length <= 3)
  /// ```
  ///
  /// Returns:
  ///   The obfuscated string, or the original string if its length is less
  ///   than or equal to 3.
  String get obfuscate {
    if (length <= 3) return this;
    String start = substring(0, 3);
    String end = substring(length - 3);
    String obfuscatedText = '$start${'*' * (length - 6)}$end';
    return obfuscatedText;
  }

  String truncate(int maxLength) => (length <= maxLength) ? this : '${substring(0, maxLength)}...';

  ///!~~~~~~~~~~~~~~~~~~~~~~~ To Date Time ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ///## Parses a string representation of a date and time into a [DateTime] object.
  ///
  /// This extension method attempts to parse the string as a date and time
  /// using several common formats. It returns `null` if the string cannot be
  /// parsed as a valid date and time.  It prioritizes parsing using
  /// `DateTime.tryParse` for ISO 8601 format, then it attempts parsing
  /// with `intl`'s `DateFormat` for other common formats.
  ///
  /// Example:
  /// ```dart
  /// "2024-03-15 10:30:00".toDateTime; // Returns DateTime(2024, 3, 15, 10, 30, 0)
  /// "2024-03-15".toDateTime;       // Returns DateTime(2024, 3, 15, 0, 0, 0)
  /// "15/03/2024".toDateTime;       // Returns DateTime(2024, 3, 15, 0, 0, 0)
  /// "March 15, 2024".toDateTime;    // Returns DateTime(2024, 3, 15, 0, 0, 0)
  /// "invalid date".toDateTime;      // Returns null
  /// null.toDateTime;                // Returns null
  /// ```
  ///
  /// Returns: A [DateTime] object if the string can be parsed, or `null` otherwise.
  DateTime? get toDateTime {
    final input = this;

    DateTime? parsed = DateTime.tryParse(input);
    if (parsed != null) return parsed;

    // Try each format
    for (final format in [...shortdateFormats, ...longdateFormats]) {
      try {
        parsed = DateFormat(format).parseStrict(input);
        return parsed;
      } catch (_) {
        // ignore parsing errors and continue
      }
    }

    return null;
  }
}
