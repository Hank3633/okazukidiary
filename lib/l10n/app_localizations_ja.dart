// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'こはる家計簿';

  @override
  String get record => '記帳';

  @override
  String get expense => '支出';

  @override
  String get income => '収入';

  @override
  String get iconSettings => 'アイコン設定';

  @override
  String get statistics => '収支統計';

  @override
  String get settings => '設定';

  @override
  String recordSaved(Object type, Object amount) {
    return '$typeを記録しました：$amount円';
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

  @override
  String get keepOneCategory => 'カテゴリを1つ以上残してください';

  @override
  String get addCategory => 'カテゴリを追加';

  @override
  String get editCategory => 'カテゴリを編集';

  @override
  String get categoryName => 'カテゴリ名';

  @override
  String get importImage => '画像を読み込む';

  @override
  String get selectBuiltInIcon => '内蔵アイコンを選択';

  @override
  String get statisticsColor => '統計の色';

  @override
  String get saving => '保存中…';

  @override
  String get saveCategory => 'カテゴリを保存';

  @override
  String get imageReadFailed => '画像を読み込めません。正しい画像ファイルを選択してください。';

  @override
  String get imageSaveFailed => '画像を保存できません。もう一度お試しください。';

  @override
  String get categoryNameExists => '同じ名前のカテゴリが既にあります';

  @override
  String deleteCategoryTitle(Object name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get deleteCategoryMessage => 'このカテゴリはアイコン一覧から削除されます。既存の記録と統計は保持されます。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get expenseIcons => '支出アイコン';

  @override
  String get incomeIcons => '収入アイコン';

  @override
  String get iconSize => 'カテゴリのアイコンサイズ';

  @override
  String get iconSizeHint => 'サイズを切り替え、「記帳」画面に戻って確認できます。';

  @override
  String get showAndReorderHint => 'チェックで表示、右のハンドルをドラッグして並べ替えます。';

  @override
  String get dragToReorder => 'ドラッグして並べ替え';

  @override
  String get thisMonth => '今月';

  @override
  String get noRecords => 'この期間の記録はありません';

  @override
  String total(Object amount) {
    return '合計：$amount';
  }

  @override
  String get recordManagement => '帳目管理';

  @override
  String get searchRecords => 'カテゴリを検索';

  @override
  String get all => 'すべて';

  @override
  String get allDates => 'すべての日付';

  @override
  String get editRecord => '帳目を編集';

  @override
  String get deleteRecord => '帳目を削除';

  @override
  String get deleteRecordMessage => 'この帳目を削除しますか？この操作は元に戻せません。';

  @override
  String get amount => '金額';

  @override
  String get date => '日付';

  @override
  String get category => 'カテゴリ';

  @override
  String get save => '保存';

  @override
  String get noMatchingRecords => '条件に一致する帳目はありません';
}
