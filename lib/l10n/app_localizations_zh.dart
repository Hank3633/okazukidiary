// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'おかず日記';

  @override
  String get expense => '支出';

  @override
  String get income => '收入';

  @override
  String get iconSettings => '圖標設定';

  @override
  String get statistics => '收支統計';

  @override
  String get settings => '設定';

  @override
  String recordSaved(Object type, Object amount) {
    return '已記$type：$amount 元';
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

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'おかず日記';

  @override
  String get expense => '支出';

  @override
  String get income => '收入';

  @override
  String get iconSettings => '圖標設定';

  @override
  String get statistics => '收支統計';

  @override
  String get settings => '設定';

  @override
  String recordSaved(Object type, Object amount) {
    return '已記$type：$amount 元';
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
