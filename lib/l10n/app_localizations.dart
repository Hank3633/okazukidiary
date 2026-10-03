import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'小芽記帳本'**
  String get appTitle;

  /// No description provided for @record.
  ///
  /// In zh_TW, this message translates to:
  /// **'記帳'**
  String get record;

  /// No description provided for @expense.
  ///
  /// In zh_TW, this message translates to:
  /// **'支出'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In zh_TW, this message translates to:
  /// **'收入'**
  String get income;

  /// No description provided for @iconSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'圖標設定'**
  String get iconSettings;

  /// No description provided for @statistics.
  ///
  /// In zh_TW, this message translates to:
  /// **'收支統計'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @recordSaved.
  ///
  /// In zh_TW, this message translates to:
  /// **'已記{type}：{amount} 元'**
  String recordSaved(Object type, Object amount);

  /// No description provided for @salary.
  ///
  /// In zh_TW, this message translates to:
  /// **'薪資'**
  String get salary;

  /// No description provided for @bonus.
  ///
  /// In zh_TW, this message translates to:
  /// **'獎金'**
  String get bonus;

  /// No description provided for @freelance.
  ///
  /// In zh_TW, this message translates to:
  /// **'接案'**
  String get freelance;

  /// No description provided for @investment.
  ///
  /// In zh_TW, this message translates to:
  /// **'投資'**
  String get investment;

  /// No description provided for @interest.
  ///
  /// In zh_TW, this message translates to:
  /// **'利息'**
  String get interest;

  /// No description provided for @dividend.
  ///
  /// In zh_TW, this message translates to:
  /// **'股利'**
  String get dividend;

  /// No description provided for @allowance.
  ///
  /// In zh_TW, this message translates to:
  /// **'零用錢'**
  String get allowance;

  /// No description provided for @refund.
  ///
  /// In zh_TW, this message translates to:
  /// **'退款'**
  String get refund;

  /// No description provided for @sale.
  ///
  /// In zh_TW, this message translates to:
  /// **'物品出售'**
  String get sale;

  /// No description provided for @rent.
  ///
  /// In zh_TW, this message translates to:
  /// **'租金'**
  String get rent;

  /// No description provided for @gift.
  ///
  /// In zh_TW, this message translates to:
  /// **'禮金'**
  String get gift;

  /// No description provided for @other.
  ///
  /// In zh_TW, this message translates to:
  /// **'其他'**
  String get other;

  /// No description provided for @keepOneCategory.
  ///
  /// In zh_TW, this message translates to:
  /// **'至少保留一個分類'**
  String get keepOneCategory;

  /// No description provided for @addCategory.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增分類'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯分類'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In zh_TW, this message translates to:
  /// **'分類名稱'**
  String get categoryName;

  /// No description provided for @importImage.
  ///
  /// In zh_TW, this message translates to:
  /// **'匯入圖片'**
  String get importImage;

  /// No description provided for @selectBuiltInIcon.
  ///
  /// In zh_TW, this message translates to:
  /// **'選擇內建圖示'**
  String get selectBuiltInIcon;

  /// No description provided for @statisticsColor.
  ///
  /// In zh_TW, this message translates to:
  /// **'統計顏色'**
  String get statisticsColor;

  /// No description provided for @saving.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存中…'**
  String get saving;

  /// No description provided for @saveCategory.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存分類'**
  String get saveCategory;

  /// No description provided for @imageReadFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'無法讀取圖片，請選擇有效的圖片檔案。'**
  String get imageReadFailed;

  /// No description provided for @imageSaveFailed.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存圖片失敗，請重試。'**
  String get imageSaveFailed;

  /// No description provided for @categoryNameExists.
  ///
  /// In zh_TW, this message translates to:
  /// **'分類名稱已存在，請使用不同名稱'**
  String get categoryNameExists;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除「{name}」？'**
  String deleteCategoryTitle(Object name);

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In zh_TW, this message translates to:
  /// **'此分類會從圖標清單移除，既有記錄與統計仍會保留。'**
  String get deleteCategoryMessage;

  /// No description provided for @cancel.
  ///
  /// In zh_TW, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除'**
  String get delete;

  /// No description provided for @expenseIcons.
  ///
  /// In zh_TW, this message translates to:
  /// **'支出圖標'**
  String get expenseIcons;

  /// No description provided for @incomeIcons.
  ///
  /// In zh_TW, this message translates to:
  /// **'收入圖標'**
  String get incomeIcons;

  /// No description provided for @iconSize.
  ///
  /// In zh_TW, this message translates to:
  /// **'分類圖示尺寸'**
  String get iconSize;

  /// No description provided for @iconSizeHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'可直接切換並回到「記帳」頁查看效果。'**
  String get iconSizeHint;

  /// No description provided for @showAndReorderHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'勾選顯示分類；拖曳右側把手調整順序。'**
  String get showAndReorderHint;

  /// No description provided for @dragToReorder.
  ///
  /// In zh_TW, this message translates to:
  /// **'拖曳排序'**
  String get dragToReorder;

  /// No description provided for @thisMonth.
  ///
  /// In zh_TW, this message translates to:
  /// **'本月'**
  String get thisMonth;

  /// No description provided for @noRecords.
  ///
  /// In zh_TW, this message translates to:
  /// **'此日期區間尚無記錄'**
  String get noRecords;

  /// No description provided for @total.
  ///
  /// In zh_TW, this message translates to:
  /// **'總計：{amount}'**
  String total(Object amount);

  /// No description provided for @recordManagement.
  ///
  /// In zh_TW, this message translates to:
  /// **'帳目管理'**
  String get recordManagement;

  /// No description provided for @searchRecords.
  ///
  /// In zh_TW, this message translates to:
  /// **'搜尋分類'**
  String get searchRecords;

  /// No description provided for @all.
  ///
  /// In zh_TW, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @allDates.
  ///
  /// In zh_TW, this message translates to:
  /// **'全部日期'**
  String get allDates;

  /// No description provided for @editRecord.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯帳目'**
  String get editRecord;

  /// No description provided for @deleteRecord.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除帳目'**
  String get deleteRecord;

  /// No description provided for @deleteRecordMessage.
  ///
  /// In zh_TW, this message translates to:
  /// **'確定要刪除這筆帳目嗎？此操作無法復原。'**
  String get deleteRecordMessage;

  /// No description provided for @amount.
  ///
  /// In zh_TW, this message translates to:
  /// **'金額'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In zh_TW, this message translates to:
  /// **'日期'**
  String get date;

  /// No description provided for @category.
  ///
  /// In zh_TW, this message translates to:
  /// **'分類'**
  String get category;

  /// No description provided for @save.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存'**
  String get save;

  /// No description provided for @noMatchingRecords.
  ///
  /// In zh_TW, this message translates to:
  /// **'沒有符合篩選條件的帳目'**
  String get noMatchingRecords;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
