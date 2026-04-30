import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/app_state.dart';
import '../core/theme/app_theme.dart';
import 'pages/alimentacao_page.dart';
import 'pages/configuracoes_page.dart';
import 'pages/hidratacao_page.dart';
import 'pages/inicio_page.dart';
import 'pages/log_injection_sheet.dart';
import 'pages/pro_plan_sheet.dart';
import 'pages/treino_page.dart';
import 'widgets/app_logo.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  String _appBarTitle() {
    switch (_idx) {
      case 0:
        return 'Início';
      case 1:
        return 'Alimentação';
      case 2:
        return 'Hidratação';
      case 3:
        return 'Treino';
      case 4:
        return 'Perfil';
      default:
        return 'Inove GLP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hydration = _idx == 2;
    return Scaffold(
      backgroundColor: hydration ? AppTheme.hydrationBackground : null,
      appBar: AppBar(
        centerTitle: hydration,
        leading: hydration
            ? null
            : const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Center(
                  child: AppLogo(size: 36, borderRadius: 10),
                ),
              ),
        leadingWidth: hydration ? null : 52,
        title: Text(
          _appBarTitle(),
          style: hydration
              ? const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF37474F),
                )
              : null,
        ),
        backgroundColor: hydration ? AppTheme.hydrationBackground : null,
        foregroundColor: hydration ? const Color(0xFF37474F) : null,
        elevation: hydration ? 0 : null,
        scrolledUnderElevation: hydration ? 0 : null,
        surfaceTintColor: hydration ? Colors.transparent : null,
      ),
      body: IndexedStack(
        index: _idx,
        children: const [
          InicioPage(),
          AlimentacaoPage(),
          HidratacaoTabView(),
          TreinoPage(),
          ConfiguracoesPage(),
        ],
      ),
      floatingActionButton: _idx == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LogInjectionSheet(),
                  ),
                );
              },
              backgroundColor: AppTheme.teal,
              elevation: 2,
              icon: const Icon(Icons.vaccines_rounded, color: Colors.white),
              label: const Text('Nova aplicação', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) {
          if (i == 3) {
            final pro = context.read<AppState>().isPro;
            if (!pro) {
              showProPlanSheet(context);
              return;
            }
          }
          setState(() => _idx = i);
        },
        backgroundColor: AppTheme.surfaceCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTheme.teal.withValues(alpha: 0.22),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 24),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.teal, size: 24),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined, size: 24),
            selectedIcon: Icon(Icons.restaurant_menu_rounded, color: AppTheme.teal, size: 24),
            label: 'Alimentação',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined, size: 24),
            selectedIcon: Icon(Icons.water_drop_rounded, color: AppTheme.teal, size: 24),
            label: 'Hidratação',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined, size: 24),
            selectedIcon: Icon(Icons.fitness_center_rounded, color: AppTheme.teal, size: 24),
            label: 'Treino',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, size: 24),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.teal, size: 24),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
