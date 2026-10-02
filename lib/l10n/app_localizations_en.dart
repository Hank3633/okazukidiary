// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Okazu Diary';

  @override
  String get expense => 'Expenses';

  @override
  String get income => 'Income';

  @override
  String get iconSettings => 'Icon Settings';

  @override
  String get statistics => 'Statistics';

  @override
  String get settings => 'Settings';

  @override
  String recordSaved(Object type, Object amount) {
    return '$type recorded: $amount';
  }

  @override
  String get salary => '薪資';

  @override
  String get bonus => '獎金';

  @override
  String get freelance => '接案';

  @override
  String get investment => '投資';

  @override
  String get interest => '利息';

  @override
  String get dividend => '股利';

  @override
  String get allowance => '零用錢';

  @override
  String get refund => '退款';

  @override
  String get sale => '物品出售';

  @override
  String get rent => '租金';

  @override
  String get gift => '禮金';

  @override
  String get other => '其他';
}
