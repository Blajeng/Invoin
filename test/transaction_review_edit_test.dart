import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:invoin/models/receipt_item.dart';
import 'package:invoin/models/transaction.dart';
import 'package:invoin/repositories/transaction_repository.dart';
import 'package:invoin/screens/transaction_review_screen.dart';
import 'package:invoin/services/receipt_service.dart';
import 'package:invoin/utils/app_theme.dart';
import 'package:invoin/utils/formatters.dart';

void main() {
  initializeDateFormatting('id_ID');

  Transaction buildDraft() {
    final date = DateTime(2026, 9, 24);
    return Transaction(
      id: 'draft-1',
      storeName: 'Indomaret',
      transactionDate: date,
      total: 48000,
      category: 'Groceries',
      items: const [
        ReceiptItem(name: 'Mineral Water', quantity: 2, price: 5000),
        ReceiptItem(name: 'Bread', quantity: 1, price: 18000),
      ],
      createdAt: date,
      updatedAt: date,
    );
  }

  Finder itemField(String suffix, int index) => find.byKey(ValueKey('item_${suffix}_$index'));

  String textOf(WidgetTester tester, Finder finder) {
    final field = tester.widget<TextFormField>(finder);
    return field.controller!.text;
  }

  Future<TransactionRepository> pumpReviewScreen(WidgetTester tester) async {
    final repository = TransactionRepository();
    final draft = buildDraft();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: (settings) {
          if (settings.name == '/transaction-review') {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) =>
                  TransactionReviewScreen(receiptService: ReceiptService(repository)),
            );
          }
          return null;
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/transaction-review',
                  arguments: draft,
                ),
                child: const Text('buka review'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka review'));
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('Review merender line item yang sudah ada di draft', (tester) async {
    await pumpReviewScreen(tester);

    expect(find.text('Review Transaksi'), findsOneWidget);
    expect(find.text('2 item'), findsOneWidget);

    expect(textOf(tester, itemField('name', 0)), 'Mineral Water');
    expect(textOf(tester, itemField('quantity', 0)), '2');
    expect(textOf(tester, itemField('price', 0)), '5000');
    expect(textOf(tester, itemField('name', 1)), 'Bread');
    expect(textOf(tester, itemField('quantity', 1)), '1');
    expect(textOf(tester, itemField('price', 1)), '18000');

    expect(find.text(formatCurrency(10000)), findsOneWidget); 
    expect(find.text(formatCurrency(18000)), findsOneWidget); 
  });

  testWidgets('Nama, jumlah, dan harga item yang sudah ada bisa diedit',
      (tester) async {
    final repository = await pumpReviewScreen(tester);

    await tester.enterText(itemField('name', 0), 'Air Mineral');
    await tester.enterText(itemField('quantity', 0), '5');
    await tester.ensureVisible(itemField('price', 0));
    await tester.enterText(itemField('price', 0), '7000');
    await tester.pumpAndSettle();

    expect(textOf(tester, itemField('name', 0)), 'Air Mineral');
    expect(textOf(tester, itemField('quantity', 0)), '5');
    expect(textOf(tester, itemField('price', 0)), '7000');
    expect(find.text(formatCurrency(35000)), findsOneWidget);
    expect(textOf(tester, find.byType(TextFormField).at(1)), '48000');

    expect(repository.getAll(), isEmpty);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Konfirmasi eksplisit menyimpan nilai hasil edit', (tester) async {
    final repository = await pumpReviewScreen(tester);

    await tester.enterText(itemField('name', 0), 'Air Mineral');
    await tester.enterText(itemField('quantity', 0), '5');
    await tester.ensureVisible(itemField('price', 0));
    await tester.enterText(itemField('price', 0), '7000');
    await tester.pumpAndSettle();

    expect(repository.getAll(), isEmpty);

    await tester.ensureVisible(find.text('Konfirmasi & Simpan'));
    await tester.tap(find.text('Konfirmasi & Simpan'));
    await tester.pumpAndSettle();

    final saved = repository.getAll();
    expect(saved, hasLength(1));
    expect(saved.single.items.first.name, 'Air Mineral');
    expect(saved.single.items.first.quantity, 5);
    expect(saved.single.items.first.price, 7000);

    expect(saved.single.items[1].name, 'Bread');
    expect(saved.single.items[1].quantity, 1);
    expect(saved.single.items[1].price, 18000);

    expect(saved.single.total, 48000);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Nilai item yang tidak valid ditolak dan tidak disimpan',
      (tester) async {
    final repository = await pumpReviewScreen(tester);

    await tester.enterText(itemField('quantity', 0), '0');
    await tester.ensureVisible(find.text('Konfirmasi & Simpan'));
    await tester.tap(find.text('Konfirmasi & Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Jumlah harus lebih dari 0'), findsOneWidget);
    expect(repository.getAll(), isEmpty);

    await tester.enterText(itemField('quantity', 0), '2');
    await tester.enterText(itemField('price', 0), 'abc');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Konfirmasi & Simpan'));
    await tester.tap(find.text('Konfirmasi & Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Harga harus berupa angka'), findsOneWidget);
    expect(repository.getAll(), isEmpty);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Editing nama toko dan tanggal tetap bekerja', (tester) async {
    final repository = await pumpReviewScreen(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Superindo',
    );
    await tester.pumpAndSettle();

    expect(find.text(formatDate(DateTime(2026, 9, 24))), findsOneWidget);
    await tester.tap(find.text(formatDate(DateTime(2026, 9, 24))));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Konfirmasi & Simpan'));
    await tester.tap(find.text('Konfirmasi & Simpan'));
    await tester.pumpAndSettle();

    final saved = repository.getAll();
    expect(saved, hasLength(1));
    expect(saved.single.storeName, 'Superindo');
    expect(saved.single.transactionDate, DateTime(2026, 9, 24));

    expect(tester.takeException(), isNull);
  });
}
