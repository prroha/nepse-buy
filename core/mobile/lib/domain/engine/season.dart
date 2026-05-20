import 'types.dart';

/// Dart port of `core/backend/src/signals/season.ts`.
///
/// Classifies a date into the strategy's three seasonal buckets using the
/// supplied tz offset (default Asia/Kathmandu UTC+5:45). The engine only
/// looks at the month — picking the right tz prevents an early-morning UTC
/// date in November from being classified as October at NPT.
const _weakMonths = {3, 6, 11};
const _strongMonths = {1, 7, 8};

Season classifySeason(DateTime date, {double tzOffsetHours = 5.75}) {
  final offsetMs = (tzOffsetHours * Duration.millisecondsPerHour).round();
  final local = date.toUtc().add(Duration(milliseconds: offsetMs));
  final month = local.month;
  if (_weakMonths.contains(month)) return Season.weak;
  if (_strongMonths.contains(month)) return Season.strong;
  return Season.normal;
}
