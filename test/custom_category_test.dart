import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okazukidiary/models/category_item.dart';
import 'package:okazukidiary/models/transaction_record.dart';
import 'package:okazukidiary/l10n/app_localizations.dart';
import 'package:okazukidiary/pages/category_editor.dart';
import 'package:okazukidiary/utils/category_reorder.dart';

void main() {
  test('自訂分類共用圖片仍維持獨立識別，序列化保存顏色與名稱', () {
    const first = CategoryItem(
      'assets/images/categories/0.png',
      '早餐',
      Colors.orange,
      customId: 'custom_1',
    );
    const second = CategoryItem(
      'assets/images/categories/0.png',
      '晚餐',
      Colors.blue,
      customId: 'custom_2',
    );
    expect(first.id, isNot(second.id));
    final restored = CategoryItem.fromJson(first.toJson());
    expect(restored.id, first.id);
    expect(restored.label, first.label);
    expect(restored.color.toARGB32(), first.color.toARGB32());
    expect(restored.imagePath, first.imagePath);
  });

  testWidgets('空白名稱不能儲存自訂分類', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CategoryEditor(),
      ),
    );
    await tester.tap(find.text('儲存分類'));
    await tester.pump();
    expect(find.text('請輸入分類名稱'), findsOneWidget);
  });

  test('記帳資料可序列化並還原', () {
    const category = CategoryItem(
      'assets/images/categories/6.png',
      '電費',
      Colors.amber,
    );
    final record = TransactionRecord(
      category: category,
      amount: 1250.5,
      isIncome: false,
      date: DateTime(2026, 10, 3),
      accountId: 'bank',
    );

    final restored = TransactionRecord.fromJson(record.toJson());

    expect(restored.category.id, category.id);
    expect(restored.amount, 1250.5);
    expect(restored.isIncome, isFalse);
    expect(restored.date, DateTime(2026, 10, 3));
    expect(restored.accountId, 'bank');
  });

  test('向下拖曳分類會插入目標位置，而非下一格', () {
    final categories = ['餐點', '飲料', '水果', '住宿'];

    reorderCategoryList(categories, 1, 4);

    expect(categories, ['餐點', '水果', '住宿', '飲料']);
  });
}
