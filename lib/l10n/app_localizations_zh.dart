// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '小芽記帳本';

  @override
  String get record => '記帳';

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

  @override
  String get keepOneCategory => '至少保留一個分類';

  @override
  String get addCategory => '新增分類';

  @override
  String get editCategory => '編輯分類';

  @override
  String get categoryName => '分類名稱';

  @override
  String get importImage => '匯入圖片';

  @override
  String get selectBuiltInIcon => '選擇內建圖示';

  @override
  String get statisticsColor => '統計顏色';

  @override
  String get saving => '儲存中…';

  @override
  String get saveCategory => '儲存分類';

  @override
  String get imageReadFailed => '無法讀取圖片，請選擇有效的圖片檔案。';

  @override
  String get imageSaveFailed => '儲存圖片失敗，請重試。';

  @override
  String get categoryNameExists => '分類名稱已存在，請使用不同名稱';

  @override
  String deleteCategoryTitle(Object name) {
    return '刪除「$name」？';
  }

  @override
  String get deleteCategoryMessage => '此分類會從圖標清單移除，既有記錄與統計仍會保留。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get expenseIcons => '支出圖標';

  @override
  String get incomeIcons => '收入圖標';

  @override
  String get iconSize => '分類圖示尺寸';

  @override
  String get iconSizeHint => '可直接切換並回到「記帳」頁查看效果。';

  @override
  String get showAndReorderHint => '勾選顯示分類；拖曳右側把手調整順序。';

  @override
  String get builtInCategories => '內建分類';

  @override
  String get customCategories => '自訂分類';

  @override
  String get noCustomCategories => '尚無自訂分類。';

  @override
  String get dragToReorder => '拖曳排序';

  @override
  String get thisMonth => '本月';

  @override
  String get noRecords => '此日期區間尚無記錄';

  @override
  String total(Object amount) {
    return '總計：$amount';
  }

  @override
  String get recordManagement => '帳目管理';

  @override
  String get searchRecords => '搜尋分類';

  @override
  String get all => '全部';

  @override
  String get allDates => '全部日期';

  @override
  String get editRecord => '編輯帳目';

  @override
  String get deleteRecord => '刪除帳目';

  @override
  String get deleteRecordMessage => '確定要刪除這筆帳目嗎？此操作無法復原。';

  @override
  String get amount => '金額';

  @override
  String get date => '日期';

  @override
  String get category => '分類';

  @override
  String get save => '儲存';

  @override
  String get noMatchingRecords => '沒有符合篩選條件的帳目';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '小芽記帳本';

  @override
  String get record => '記帳';

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

  @override
  String get keepOneCategory => '至少保留一個分類';

  @override
  String get addCategory => '新增分類';

  @override
  String get editCategory => '編輯分類';

  @override
  String get categoryName => '分類名稱';

  @override
  String get importImage => '匯入圖片';

  @override
  String get selectBuiltInIcon => '選擇內建圖示';

  @override
  String get statisticsColor => '統計顏色';

  @override
  String get saving => '儲存中…';

  @override
  String get saveCategory => '儲存分類';

  @override
  String get imageReadFailed => '無法讀取圖片，請選擇有效的圖片檔案。';

  @override
  String get imageSaveFailed => '儲存圖片失敗，請重試。';

  @override
  String get categoryNameExists => '分類名稱已存在，請使用不同名稱';

  @override
  String deleteCategoryTitle(Object name) {
    return '刪除「$name」？';
  }

  @override
  String get deleteCategoryMessage => '此分類會從圖標清單移除，既有記錄與統計仍會保留。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get expenseIcons => '支出圖標';

  @override
  String get incomeIcons => '收入圖標';

  @override
  String get iconSize => '分類圖示尺寸';

  @override
  String get iconSizeHint => '可直接切換並回到「記帳」頁查看效果。';

  @override
  String get showAndReorderHint => '勾選顯示分類；拖曳右側把手調整順序。';

  @override
  String get builtInCategories => '內建分類';

  @override
  String get customCategories => '自訂分類';

  @override
  String get noCustomCategories => '尚無自訂分類。';

  @override
  String get dragToReorder => '拖曳排序';

  @override
  String get thisMonth => '本月';

  @override
  String get noRecords => '此日期區間尚無記錄';

  @override
  String total(Object amount) {
    return '總計：$amount';
  }

  @override
  String get recordManagement => '帳目管理';

  @override
  String get searchRecords => '搜尋分類';

  @override
  String get all => '全部';

  @override
  String get allDates => '全部日期';

  @override
  String get editRecord => '編輯帳目';

  @override
  String get deleteRecord => '刪除帳目';

  @override
  String get deleteRecordMessage => '確定要刪除這筆帳目嗎？此操作無法復原。';

  @override
  String get amount => '金額';

  @override
  String get date => '日期';

  @override
  String get category => '分類';

  @override
  String get save => '儲存';

  @override
  String get noMatchingRecords => '沒有符合篩選條件的帳目';
}
