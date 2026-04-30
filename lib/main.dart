import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/main_shell.dart';
import 'app/pages/login_page.dart';
import 'app/pages/splash_screen.dart';
import 'core/services/app_state.dart';
import 'core/services/reminder_notifications.dart';
import 'core/theme/app_theme.dart';
import 'primeiro_acesso/first_access_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderNotifications.init();
  await initializeDateFormatting('pt_BR', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const InoveGlpApp(),
    ),
  );
}

class InoveGlpApp extends StatelessWidget {
  const InoveGlpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inove GLP',
      theme: AppTheme.light(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, s, _) {
        if (!s.isReady) {
          return const SplashScreen();
        }
        if (!s.isLoggedIn) {
          return LoginPage(
            onFirstAccess: () {
              s.startFirstAccess();
            },
          );
        }
        if (!s.firstAccessDone) {
          return const FirstAccessFlow();
        }
        return const MainShell();
      },
    );
  }
}
