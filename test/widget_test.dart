import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obsidian_slate/main.dart';
import 'package:obsidian_slate/database/database_provider.dart';
import 'package:obsidian_slate/database/app_database.dart';
import 'package:obsidian_slate/database/connection/in_memory_connection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IdemApp smoke test and navigation rendering', (WidgetTester tester) async {
    final db = AppDatabase.forTesting(constructInMemoryDatabase());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const IdemApp(),
      ),
    );

    // Initial settle
    await tester.pumpAndSettle();

    // Verify Today screen title and action render
    expect(find.text('Today'), findsWidgets);
    expect(find.byTooltip('Plan Day'), findsOneWidget);

    await db.close();
  });
}
