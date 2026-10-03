// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Little Sprout Ledger';

  @override
  String get record => 'Record';

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

  @override
  String get keepOneCategory => 'Keep at least one category';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get importImage => 'Import Image';

  @override
  String get selectBuiltInIcon => 'Choose Built-in Icon';

  @override
  String get statisticsColor => 'Statistics Color';

  @override
  String get saving => 'Saving…';

  @override
  String get saveCategory => 'Save Category';

  @override
  String get imageReadFailed =>
      'Unable to read the image. Please choose a valid image file.';

  @override
  String get imageSaveFailed => 'Unable to save the image. Please try again.';

  @override
  String get categoryNameExists => 'A category with this name already exists.';

  @override
  String deleteCategoryTitle(Object name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteCategoryMessage =>
      'This category will be removed from the icon list. Existing records and statistics will be kept.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get expenseIcons => 'Expense Icons';

  @override
  String get incomeIcons => 'Income Icons';

  @override
  String get iconSize => 'Category Icon Size';

  @override
  String get iconSizeHint =>
      'Switch the size and return to the Record page to preview it.';

  @override
  String get showAndReorderHint =>
      'Check to show categories; drag the handle to reorder them.';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get thisMonth => 'This Month';

  @override
  String get noRecords => 'No records in this date range';

  @override
  String total(Object amount) {
    return 'Total: $amount';
  }

  @override
  String get recordManagement => 'Record Management';

  @override
  String get searchRecords => 'Search categories';

  @override
  String get all => 'All';

  @override
  String get allDates => 'All dates';

  @override
  String get editRecord => 'Edit Record';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get deleteRecordMessage =>
      'Delete this record? This cannot be undone.';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get category => 'Category';

  @override
  String get save => 'Save';

  @override
  String get noMatchingRecords => 'No records match the filters';
}
