import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

extension BuildContextExtensions on BuildContext {
  String formatDateTime(DateTime value) =>
      DateFormat.yMd(Localizations.localeOf(this).languageCode).add_Hm().format(value);
}
