import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_profile.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onFirstAccess});

  final VoidCallback onFirstAccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _remember = true;
  bool _obscurePass = true;
  bool _loading = false;
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(color: AppTheme.surface),
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final t = _bgController.value * 2 * math.pi;
              return Stack(
                children: [
                  _orb(
                    left: -60 + math.sin(t) * 18,
                    top: -80 + math.cos(t * 0.8) * 14,
                    size: 220,
                    color: AppTheme.teal.withValues(alpha: 0.14),
                  ),
                  _orb(
                    right: -70 + math.cos(t * 0.9) * 22,
                    top: 120 + math.sin(t * 1.1) * 18,
                    size: 190,
                    color: AppTheme.purple.withValues(alpha: 0.11),
                  ),
                  _orb(
                    right: -80 + math.sin(t * 0.7) * 20,
                    bottom: -90 + math.cos(t * 1.2) * 16,
                    size: 250,
                    color: AppTheme.navy.withValues(alpha: 0.08),
                  ),
                  _orb(
                    left: 40 + math.cos(t * 1.3) * 16,
                    bottom: 120 + math.sin(t * 0.95) * 14,
                    size: 110,
                    color: AppTheme.teal.withValues(alpha: 0.1),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 760;
                    final logoSize = math.min(
                      isCompact ? 340.0 : 400.0,
                      constraints.maxHeight * (isCompact ? 0.28 : 0.34),
                    );
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 18),
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: math.min(460, constraints.maxWidth),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: AppLogo(
                                    size: logoSize,
                                    borderRadius: 72,
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(0, isCompact ? -8 : -12),
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(
                                      18,
                                      isCompact ? 12 : 16,
                                      18,
                                      isCompact ? 14 : 18,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFFFFFF),
                                          Color(0xFFF7FAFF),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: AppTheme.navy.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.navy.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 26,
                                          offset: const Offset(0, 12),
                                        ),
                                        BoxShadow(
                                          color: AppTheme.teal.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 34,
                                          offset: const Offset(0, 18),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: _emailC,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.navy,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Email',
                                            labelStyle: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.navy.withValues(
                                                  alpha: 0.08,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.mail_rounded,
                                                color: AppTheme.navy,
                                              ),
                                            ),
                                            prefixIconConstraints:
                                                const BoxConstraints(
                                                  minWidth: 52,
                                                  minHeight: 52,
                                                ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: isCompact ? 14 : 18,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: BorderSide(
                                                color: AppTheme.navy.withValues(
                                                  alpha: 0.12,
                                                ),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: BorderSide(
                                                color: AppTheme.navy.withValues(
                                                  alpha: 0.12,
                                                ),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: const BorderSide(
                                                color: AppTheme.teal,
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: isCompact ? 10 : 12),
                                        TextField(
                                          controller: _passC,
                                          obscureText: _obscurePass,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.navy,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Senha',
                                            labelStyle: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.navy.withValues(
                                                  alpha: 0.08,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.lock_rounded,
                                                color: AppTheme.navy,
                                              ),
                                            ),
                                            prefixIconConstraints:
                                                const BoxConstraints(
                                                  minWidth: 52,
                                                  minHeight: 52,
                                                ),
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(
                                                  () => _obscurePass =
                                                      !_obscurePass,
                                                );
                                              },
                                              icon: Icon(
                                                _obscurePass
                                                    ? Icons.visibility_rounded
                                                    : Icons
                                                          .visibility_off_rounded,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: isCompact ? 14 : 18,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: BorderSide(
                                                color: AppTheme.navy.withValues(
                                                  alpha: 0.12,
                                                ),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: BorderSide(
                                                color: AppTheme.navy.withValues(
                                                  alpha: 0.12,
                                                ),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: const BorderSide(
                                                color: AppTheme.teal,
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: isCompact ? 8 : 10),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _remember,
                                              onChanged: (v) => setState(
                                                () => _remember = v ?? true,
                                              ),
                                            ),
                                            const Expanded(
                                              child: Text(
                                                'Lembrar minha senha',
                                                style: TextStyle(
                                                  color: AppTheme.textMuted,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isCompact ? 6 : 8),
                                        FilledButton(
                                          onPressed: _loading ? null : _login,
                                          style: FilledButton.styleFrom(
                                            minimumSize: Size.fromHeight(
                                              isCompact ? 48 : 54,
                                            ),
                                            backgroundColor: AppTheme.teal,
                                            foregroundColor: Colors.white,
                                            elevation: 8,
                                            shadowColor: AppTheme.teal
                                                .withValues(alpha: 0.35),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            _loading ? 'Entrando...' : 'Entrar',
                                          ),
                                        ),
                                        SizedBox(height: isCompact ? 8 : 10),
                                        OutlinedButton.icon(
                                          onPressed: _loading
                                              ? null
                                              : _loginTestNoData,
                                          icon: const Icon(Icons.bolt_rounded),
                                          label: const Text(
                                            'Entrar sem dados (teste)',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: Size.fromHeight(
                                              isCompact ? 44 : 48,
                                            ),
                                            side: BorderSide(
                                              color: AppTheme.teal.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
                                            foregroundColor: AppTheme.teal,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: isCompact ? 8 : 10),
                                        OutlinedButton(
                                          onPressed: _loading
                                              ? null
                                              : widget.onFirstAccess,
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: Size.fromHeight(
                                              isCompact ? 46 : 50,
                                            ),
                                            side: BorderSide(
                                              color: AppTheme.navy.withValues(
                                                alpha: 0.22,
                                              ),
                                            ),
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.72),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text('Primeiro acesso'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: isCompact ? 8 : 12),
                                const Text(
                                  'Desenvolvido por Inove Dev',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha email e senha.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<AppState>().loginWithEmail(
      email: email,
      password: pass,
      remember: _remember,
    );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email ou senha inválidos.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loginTestNoData() async {
    if (_loading) return;
    setState(() => _loading = true);
    final s = context.read<AppState>();
    final demo = UserProfile(
      usingGlp1: true,
      medicationLine: 'Mounjaro®',
      doseLabel: '2.5 mg',
      frequencyDays: 7,
      sex: 'f',
      age: 33,
      heightCm: 166,
      startWeightKg: 88,
      goalWeightKg: 72,
      activityKey: 'light',
      name: 'Demo',
      email: null,
      password: null,
    );
    await s.completeOnboarding(demo, acceptTerms: true);
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entrou com perfil de teste.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _orb({
    double? left,
    double? top,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
