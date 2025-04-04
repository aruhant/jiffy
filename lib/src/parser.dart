import 'package:intl/intl.dart';
import 'package:jiffy/src/locale/ordinals.dart';

import 'enums/unit.dart';
import 'getter.dart';
import 'locale/locale.dart';
import 'utils/jiffy_exception.dart';

class Parser {
  final Getter _getter;

  Parser(this._getter);

  DateTime fromString(
      String input, String? pattern, Locale locale, bool isUtc) {
    if (pattern != null) {
      if (pattern.trim().isEmpty) {
        throw JiffyException('The provided pattern for input `$input` cannot '
            'be blank');
      }
      final ordinals = locale.ordinals;
      return _parseString(locale.code, _replaceParseInput(input, ordinals),
              _replacePatternInput(pattern))
          .copyWith(isUtc: isUtc);
    }

    if (_matchesSlashStringDateTime(input)) {
      return _parseString(locale.code, input, 'yyyy/MM/dd');
    } else if (_matchesIsoDateTime(input) ||
        _matchesDartStringDateTime(input)) {
      return DateTime.parse(input);
    } else {
      throw JiffyException(
          'Could not read date time of input `$input`, try using a pattern, '
          'e.g. input: "12, Oct", pattern: "dd, MMM"');
    }
  }

  DateTime fromList(List<int> input, bool isUtc) {
    if (input.isEmpty) {
      throw JiffyException('The provided datetime list cannot be empty');
    }
    final length = input.length;
    return DateTime(
            input[0],
            length > 1 ? input[1] : 1,
            length > 2 ? input[2] : 1,
            length > 3 ? input[3] : 0,
            length > 4 ? input[4] : 0,
            length > 5 ? input[5] : 0,
            length > 6 ? input[6] : 0,
            length > 7 ? input[7] : 0)
        .copyWith(isUtc: isUtc);
  }

  DateTime fromMap(Map<Unit, int> input, bool isUtc) {
    if (input.isEmpty) {
      throw JiffyException('The provided datetime map cannot be empty');
    }
    return DateTime(
            input[Unit.year] ?? _getter.year(DateTime.now()),
            input[Unit.month] ?? _getter.month(DateTime.now()),
            input[Unit.day] ?? _getter.date(DateTime.now()),
            input[Unit.hour] ?? _getter.hour(DateTime.now()),
            input[Unit.minute] ?? _getter.minute(DateTime.now()),
            input[Unit.second] ?? _getter.second(DateTime.now()),
            input[Unit.millisecond] ?? _getter.millisecond(DateTime.now()),
            input[Unit.microsecond] ?? _getter.microsecond(DateTime.now()))
        .copyWith(isUtc: isUtc);
  }

  DateTime _parseString(String locale, String input, String pattern) {
    try {
      return DateFormat(pattern, locale).parse(input);
    } on FormatException catch (e) {
      throw JiffyException('Could not parse input `$input`, failed with the '
          'following error: ${e.toString()}');
    }
  }

  String _replacePatternInput(String pattern) {
    return pattern.replaceFirst('do', 'd');
  }

  String _replaceParseInput(String input, Ordinals ordinals) {
    return input
        .replaceFirst(' pm', ' PM')
        .replaceFirst(' am', ' AM')
        .replaceFirst(_matchesOrdinalDates(input, ordinals), '');
  }

  bool _matchesSlashStringDateTime(String input) {
    return RegExp(r'\d{4}/\d{1,2}/\d{1,2}$').hasMatch(input);
  }

  bool _matchesDartStringDateTime(String input) {
    return RegExp(
            r'\d{4}-\d{1,2}-\d{1,2} \d{1,2}(:\d{1,2})?(:\d{1,2})?(.\d+)?(Z?)$')
        .hasMatch(input);
  }

  bool _matchesIsoDate(String input) {
    return RegExp(r'\d{4}-\d{1,2}-\d{1,2}$').hasMatch(input);
  }

  bool _matchesIsoLocalDateTime(String input) {
    return RegExp(r'^(\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])'
            r'T([01][0-9]|2[0-3]):([0-5][0-9])(:([0-5][0-9]|60)(\.\d+)?)?$')
        .hasMatch(input);
  }

  bool _matchesIsoUtcDateTime(String input) {
    return RegExp(r'^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])'
            r'T([01][0-9]|2[0-3]):([0-5][0-9])(:([0-5][0-9]|60)(\.\d+)?)?Z$')
        .hasMatch(input);
  }

  bool _matchesIsoUtcOffsetDateTime(String input) {
    return RegExp(r'^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])'
            r'T([01][0-9]|2[0-3]):([0-5][0-9])(:([0-5][0-9]|60)(\.\d+)?)?'
            r'([+-](0[0-9]|1[0-4]):([0-5][0-9]))$')
        .hasMatch(input);
  }

  bool _matchesIsoDateTime(String input) {
    return _matchesIsoDate(input) ||
        _matchesIsoLocalDateTime(input) ||
        _matchesIsoUtcDateTime(input) ||
        _matchesIsoUtcOffsetDateTime(input);
  }

  String _matchesOrdinalDates(String input, Ordinals ordinals) {
    final matches =
        // ignore: prefer_interpolation_to_compose_strings
        RegExp(r'\d+\s*(' + ordinals.asList().join('|') + ')')
            .allMatches(input);
    return matches.isNotEmpty ? matches.first.group(1) ?? '' : '';
  }
}
