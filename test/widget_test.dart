import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:se1902_g3_project_cscm/main.dart';

void main() {
  testWidgets('App starts on the CSCM splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CSCMApp());

    expect(find.text('CSCM'), findsOneWidget);
    expect(find.text('Chuỗi Cửa Hàng Tiện Lợi'), findsOneWidget);
    expect(find.byIcon(Icons.store_mall_directory_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Đăng nhập hệ thống'), findsOneWidget);
  });
}
