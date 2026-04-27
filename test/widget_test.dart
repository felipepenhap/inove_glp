import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inove_glp/core/services/app_state.dart';
import 'package:inove_glp/main.dart';

void main() {
  testWidgets('InoveGlpApp root', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const InoveGlpApp(),
      ),
    );
    expect(find.byType(InoveGlpApp), findsOneWidget);
  });
}
