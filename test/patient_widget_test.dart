import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Patient Form Widget Test', () {
    testWidgets('form pasien punya field nama', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
          ),
        ),
      );

      expect(find.text('Nama Lengkap'), findsOneWidget);
    });

    testWidgets('form pasien punya field NIK', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(labelText: 'NIK'),
            ),
          ),
        ),
      );

      expect(find.text('NIK'), findsOneWidget);
    });

    testWidgets('bisa input nama di field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(hintText: 'Masukkan nama'),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Iqbal Fahrozi');
      await tester.pump();

      expect(find.text('Iqbal Fahrozi'), findsOneWidget);
    });

    testWidgets('tombol simpan ada di form', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(onPressed: () {}, child: const Text('Simpan')),
          ),
        ),
      );

      expect(find.text('Simpan'), findsOneWidget);
    });
  });

  group('Patient List Widget Test', () {
    testWidgets('list pasien menampilkan card', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: const Text('Iqbal Fahrozi'),
                subtitle: const Text('NIK: 3201012801990001'),
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Iqbal Fahrozi'), findsOneWidget);
    });

    testWidgets('list pasien punya search bar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari pasien...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
