import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoin/main.dart';
import 'package:invoin/screens/home_screen.dart';

void main() {
  Finder navDestination(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  int selectedIndex(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('Shell merender bottom navigation dengan Beranda sebagai default',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InvoinApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(navDestination('Beranda'), findsOneWidget);
    expect(navDestination('Transaksi'), findsOneWidget);
    expect(navDestination('AI Chat'), findsOneWidget);

    expect(selectedIndex(tester), 0);
    expect(find.text('Pencatatan keuangan dari struk'), findsOneWidget);
  });

  testWidgets('Shell berpindah antara 3 destination utama',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InvoinApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(navDestination('Transaksi'));
    await tester.tap(navDestination('Transaksi'));
    await tester.pumpAndSettle();
    expect(selectedIndex(tester), 1);

    await tester.ensureVisible(navDestination('AI Chat'));
    await tester.tap(navDestination('AI Chat'));
    await tester.pumpAndSettle();
    expect(selectedIndex(tester), 2);

    await tester.ensureVisible(navDestination('Beranda'));
    await tester.tap(navDestination('Beranda'));
    await tester.pumpAndSettle();
    expect(selectedIndex(tester), 0);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Beranda tetap menjadi primary action untuk scan struk',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InvoinApp());
    await tester.pumpAndSettle();

    expect(find.text('Input Manual'), findsNothing);

    final scanStruk = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.text('Scan Struk'),
    );
    expect(scanStruk, findsOneWidget);

    await tester.ensureVisible(scanStruk);
    await tester.tap(scanStruk);
    await tester.pumpAndSettle();

    expect(find.text('Pilih atau ambil foto struk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
