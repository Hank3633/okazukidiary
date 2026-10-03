import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:okazukidiary/main.dart';

void main() {
  testWidgets('可在主要功能頁面之間切換', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'zh',
      'TW',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('記帳'), findsWidgets);

    await tester.tap(find.text('收支統計'));
    await tester.pumpAndSettle();
    expect(find.text('此日期區間尚無記錄'), findsOneWidget);

    await tester.tap(find.text('圖標設定'));
    await tester.pumpAndSettle();
    expect(find.text('分類圖示尺寸'), findsOneWidget);
  });
}
