import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app/widgets/app_logo.dart';
import '../app/widgets/modern_card.dart';
import '../app/widgets/training_modality_catalog.dart';
import '../app/widgets/training_modality_grid.dart';
import '../core/data/medications.dart';
import '../core/models/training_plan.dart';
import '../core/models/user_profile.dart';
import '../core/services/app_state.dart';
import '../core/services/training_ai.dart';
import '../core/theme/app_theme.dart';
import 'onboarding_data.dart';
import 'onboarding_header.dart';

const int kOnboardSteps = 19;

class FirstAccessFlow extends StatefulWidget {
  const FirstAccessFlow({super.key});

  @override
  State<FirstAccessFlow> createState() => _FirstAccessFlowState();
}

class _FirstAccessFlowState extends State<FirstAccessFlow> {
  final _data = OnboardingData();
  final _pc = PageController();
  int _page = 0;
  bool _loadingScheduled = false;
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _picker = ImagePicker();
  String? _onboardingPhotoPath;
  late final FixedExtentScrollController _ageScroll;
  late final FixedExtentScrollController _heightScroll;

  @override
  void initState() {
    super.initState();
    _data.syncDoseToMedication();
    _ageScroll = FixedExtentScrollController(initialItem: _data.age - 15);
    _heightScroll = FixedExtentScrollController(
      initialItem: _data.heightCm - 120,
    );
  }

  @override
  void dispose() {
    _ageScroll.dispose();
    _heightScroll.dispose();
    _pc.dispose();
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  ButtonStyle get _obPrimaryBtn => FilledButton.styleFrom(
        backgroundColor: AppTheme.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      );

  Future<void> _go(int page) async {
    if (!mounted) return;
    await _pc.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPage(int p) {
    setState(() {
      _page = p;
      if (p != 15) _loadingScheduled = false;
    });
    if (p == 15 && !_loadingScheduled) {
      _loadingScheduled = true;
      Future<void>.delayed(const Duration(milliseconds: 4300), () {
        if (!mounted) return;
        if (_page != 15) return;
        unawaited(_go(16));
      });
    }
  }

  UserProfile _profileDraft() {
    return UserProfile(
      usingGlp1: _data.usingGlp1,
      medicationLine: _data.medicationLine,
      doseLabel: _data.doseLabel,
      frequencyDays: _data.frequencyDays,
      sex: _data.sex,
      age: _data.age,
      heightCm: _data.heightCm,
      startWeightKg: _data.weightCurrent,
      goalWeightKg: _data.weightGoal,
      activityKey: _data.activityKey,
      name: _nameC.text.trim().isEmpty ? _data.displayName : _nameC.text.trim(),
      email: _emailC.text.trim().isEmpty ? null : _emailC.text.trim(),
      password: _passC.text.trim().isEmpty ? null : _passC.text.trim(),
    );
  }

  Future<void> _finish() async {
    final app = context.read<AppState>();
    var p = _profileDraft();
    final em = _emailC.text.trim();
    if (em.isNotEmpty) {
      p = UserProfile(
        usingGlp1: p.usingGlp1,
        medicationLine: p.medicationLine,
        doseLabel: p.doseLabel,
        frequencyDays: p.frequencyDays,
        sex: p.sex,
        age: p.age,
        heightCm: p.heightCm,
        startWeightKg: p.startWeightKg,
        goalWeightKg: p.goalWeightKg,
        activityKey: p.activityKey,
        name: p.name,
        email: em,
        password: _passC.text.trim().isEmpty ? p.password : _passC.text.trim(),
        proteinTargetG: p.proteinTargetG,
        fiberTargetG: p.fiberTargetG,
        waterTargetL: p.waterTargetL,
        carbTargetG: p.carbTargetG,
      );
    }
    if (p.name.isEmpty) {
      return;
    }
    await app.completeOnboarding(
      p,
      acceptTerms: true,
      trainingPreferences: _data.trainingPreferences,
    );
    if (_onboardingPhotoPath != null && _onboardingPhotoPath!.trim().isNotEmpty) {
      await app.setProfilePhotoPath(_onboardingPhotoPath);
    }
  }

  Future<void> _pickOnboardingPhoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (src == null || !mounted) return;
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
        src == ImageSource.camera) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No desktop, use a galeria para escolher a foto.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final x = await _picker.pickImage(
        source: src,
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (x == null || !mounted) return;
      setState(() => _onboardingPhotoPath = x.path);
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plugin de imagem não carregou. Reinicie o app com flutter run.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir câmera/galeria.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.teal.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.navy.withValues(alpha: 0.08),
                ),
              ),
            ),
            Column(
              children: [
                if (_page > 0)
                  OnboardingHeader(
                    stepIndex: _page,
                    totalSteps: kOnboardSteps,
                    onBack: _page > 0
                        ? () {
                            if (_page == 0) {
                              return;
                            }
                            unawaited(_go(_page - 1));
                          }
                        : null,
                  )
                else
                  const SizedBox(height: 8),
                Expanded(
                  child: PageView(
                    controller: _pc,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: _onPage,
                    children: [
                      _buildStep(0, _welcome()),
                      _buildStep(1, _glpQ()),
                      _buildStep(2, _medList()),
                      _buildStep(3, _dose()),
                      _buildStep(4, _freq()),
                      _buildStep(5, _features()),
                      _buildStep(6, _sex()),
                      _buildStep(7, _age()),
                      _buildStep(8, _heightP()),
                      _buildStep(9, _wCur()),
                      _buildStep(10, _wGoal()),
                      _buildStep(11, _motive()),
                      _buildStep(12, _activity()),
                      _buildStep(13, _name()),
                      _buildStep(14, _trainingPreferencesStep()),
                      _buildStep(15, _loading()),
                      _buildStep(16, _plan()),
                      _buildStep(17, _trainingPreview()),
                      _buildStep(18, _account()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step, Widget child) {
    final active = _page == step;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      opacity: active ? 1 : 0.4,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        offset: active ? Offset.zero : const Offset(0.05, 0),
        child: child,
      ),
    );
  }

  Widget _welcome() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F2847),
                        Color(0xFF1A4C6A),
                        Color(0xFF0DB9A3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.navy.withValues(alpha: 0.18),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: AppLogo(size: 200, borderRadius: 44),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bem-vindo ao Inove GLP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Controle os efeitos colaterais e aprenda a manter os resultados com apoio no dia a dia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.navy.withValues(alpha: 0.65),
                    height: 1.45,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  style: _obPrimaryBtn.copyWith(
                    minimumSize: const WidgetStatePropertyAll(
                      Size.fromHeight(56),
                    ),
                  ),
                  onPressed: () => unawaited(_go(1)),
                  child: const Text('Começar'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => unawaited(context.read<AppState>().logout()),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(
                      color: AppTheme.navy.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Voltar para o login'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tirzepatida, Mounjaro e muito mais.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.navy.withValues(alpha: 0.35),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _glpQ() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vaccines_rounded,
                  color: AppTheme.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Informação importante para personalizar sua jornada',
                  style: TextStyle(
                    color: AppTheme.navy.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Você está usando alguma caneta no momento?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.2,
            color: AppTheme.navy,
          ),
        ),
        Text(
          '💉 Escolha sua situação atual',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 22),
        SelectablePill(
          title: 'Já estou usando GLP-1',
          subtitle: 'Estou em uso e quero otimizar resultados',
          onTap: () {
            setState(() => _data.usingGlp1 = true);
            unawaited(_go(2));
          },
        ),
        const SizedBox(height: 12),
        SelectablePill(
          title: 'Quero começar GLP-1',
          subtitle: 'Ainda vou iniciar o tratamento',
          onTap: () {
            setState(() => _data.usingGlp1 = false);
            unawaited(_go(2));
          },
        ),
      ],
    );
  }

  Widget _medList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
      children: [
        Text(
          'Qual medicamento GLP-1 você vai usar?',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            height: 1.25,
            color: AppTheme.navy.withValues(alpha: 0.96),
          ),
        ),
        Text(
          '💉 Escolha a linha do tratamento',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 14),
        ...kMedicationLines.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ModernCard(
              onTap: () {
                setState(() {
                  _data.medicationLine = e;
                  _data.syncDoseToMedication();
                });
                unawaited(_go(3));
              },
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vaccines_rounded,
                      color: AppTheme.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.3,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.navy.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dose() {
    final opts = doseLabelsForMedication(_data.medicationLine);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text(
          'Qual dose você vai iniciar tomando?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Doses disponíveis para ${_data.medicationLine.split("®").first}®',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            for (final d in opts)
              ModernCard(
                onTap: () {
                  setState(() => _data.doseLabel = d);
                  unawaited(_go(4));
                },
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Center(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _freq() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text(
          'Com que frequência você vai aplicar?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Quantos dias entre cada aplicação',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 20),
        SelectablePill(
          title: 'Diariamente',
          subtitle: '1 dia entre aplicações',
          onTap: () {
            setState(() => _data.frequencyDays = 1);
            unawaited(_go(5));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'A cada 7 dias',
          subtitle: 'Padrão semanal',
          onTap: () {
            setState(() => _data.frequencyDays = 7);
            unawaited(_go(5));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'A cada 15 dias',
          subtitle: 'Aplicação quinzenal',
          onTap: () {
            setState(() => _data.frequencyDays = 15);
            unawaited(_go(5));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'A cada mês',
          subtitle: 'Aplicação mensal',
          onTap: () {
            setState(() => _data.frequencyDays = 30);
            unawaited(_go(5));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'Ainda não sei',
          subtitle: 'Definir depois (usaremos semanal)',
          onTap: () {
            setState(() => _data.frequencyDays = 7);
            unawaited(_go(5));
          },
        ),
      ],
    );
  }

  Widget _features() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      children: [
        ModernCard(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'primeiro_acesso/6.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (c, e, st) => const Icon(Icons.sensors, size: 64),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Seja lembrada(o) da sua próxima dose',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            height: 1.25,
            color: AppTheme.navy.withValues(alpha: 0.96),
          ),
        ),
        const SizedBox(height: 20),
        _checkRow(
          'Registre cada aplicação',
          'Histórico com datas e doses',
          Icons.event,
        ),
        const SizedBox(height: 10),
        _checkRow(
          'Lembretes inteligentes',
          'Notificações no momento certo',
          Icons.notifications,
        ),
        const SizedBox(height: 10),
        _checkRow(
          'Acompanhe seu progresso',
          'Peso, metas e jornada',
          Icons.show_chart,
        ),
        const SizedBox(height: 20),
        const Text(
          'Milhares de pessoas acompanhando o tratamento com clareza.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: _obPrimaryBtn,
          onPressed: () => unawaited(_go(6)),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _checkRow(String t, String s, IconData i) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppTheme.teal.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(i, color: AppTheme.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  s,
                  style: TextStyle(
                    color: AppTheme.navy.withValues(alpha: 0.62),
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: AppTheme.success, size: 20),
        ],
      ),
    );
  }

  Widget _sex() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.purple.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: AppTheme.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Usamos esse dado só para cálculos metabólicos.',
                  style: TextStyle(
                    color: AppTheme.navy.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Qual seu sexo?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Para cálculos nutricionais mais precisos',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        _sexOptionCard(
          title: 'Feminino',
          subtitle: 'Parâmetros de cálculo feminino',
          icon: Icons.female_rounded,
          accent: const Color(0xFFEC4899),
          light: const Color(0xFFFCE7F3),
          onTap: () {
            setState(() => _data.sex = 'f');
            unawaited(_go(7));
          },
        ),
        const SizedBox(height: 12),
        _sexOptionCard(
          title: 'Masculino',
          subtitle: 'Parâmetros de cálculo masculino',
          icon: Icons.male_rounded,
          accent: const Color(0xFF2563EB),
          light: const Color(0xFFDBEAFE),
          onTap: () {
            setState(() => _data.sex = 'm');
            unawaited(_go(7));
          },
        ),
      ],
    );
  }

  Widget _sexOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Color light,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, light],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.18),
                ),
                child: Icon(icon, size: 32, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.navy.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: accent.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _age() {
    return _wheelPage(
      title: 'Qual é a sua idade?',
      sub: 'Deslize para selecionar',
      valueLabel: '${_data.age} anos',
      child: CupertinoPicker(
        scrollController: _ageScroll,
        itemExtent: 40,
        onSelectedItemChanged: (i) {
          setState(() => _data.age = 15 + i);
        },
        children: List.generate(76, (i) {
          return Center(
            child: Text(
              '${15 + i}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
          );
        }),
      ),
      onNext: () => unawaited(_go(8)),
    );
  }

  Widget _heightP() {
    return _wheelPage(
      title: 'Qual é sua altura?',
      sub: 'Deslize para selecionar',
      valueLabel: '${_data.heightCm} cm',
      child: CupertinoPicker(
        scrollController: _heightScroll,
        itemExtent: 40,
        onSelectedItemChanged: (i) {
          setState(() => _data.heightCm = 120 + i);
        },
        children: List.generate(101, (i) {
          return Center(
            child: Text(
              '${120 + i} cm',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          );
        }),
      ),
      onNext: () => unawaited(_go(9)),
    );
  }

  Widget _wheelPage({
    required String title,
    required String sub,
    required String valueLabel,
    required Widget child,
    required VoidCallback onNext,
  }) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.navy,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Text(
          valueLabel,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppTheme.teal,
            letterSpacing: -0.8,
          ),
        ),
        ModernCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SizedBox(height: 210, child: child),
        ),
        const Spacer(),
        FilledButton(
          style: _obPrimaryBtn,
          onPressed: onNext,
          child: const Text('Continuar'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _wCur() {
    return _weightPage(
      title: 'Qual é seu peso atual?',
      sub:
          'Isso ajuda a personalizar o acompanhamento. (Você pode alterar depois.)',
      value: _data.weightCurrent,
      onChange: (v) => setState(() => _data.weightCurrent = v),
      onNext: () => unawaited(_go(10)),
    );
  }

  Widget _wGoal() {
    final d = _data.weightCurrent - _data.weightGoal;
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'Qual sua meta de peso atual?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Recalcularemos seu progresso e timeline',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Text(
          '${_data.weightGoal.toStringAsFixed(1)} kg',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w500),
        ),
        if (d > 0) ...[
          Text(
            '-${d.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE65100),
            ),
          ),
          Text(
            'para perder',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
        Slider(
          value: _data.weightGoal.clamp(40, _data.weightCurrent - 0.1),
          min: 40,
          max: (_data.weightCurrent - 0.1).clamp(41, 250),
          onChanged: (v) {
            setState(() => _data.weightGoal = v);
          },
        ),
        const Spacer(),
        FilledButton(
          style: _obPrimaryBtn,
          onPressed: () => unawaited(_go(11)),
          child: const Text('Continuar'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _weightPage({
    required String title,
    required String sub,
    required double value,
    required ValueChanged<double> onChange,
    required VoidCallback onNext,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textMuted,
            height: 1.35,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${value.toStringAsFixed(1)} kg',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
          ),
        ),
        Slider(
          value: value.clamp(40, 250),
          min: 40,
          max: 250,
          onChanged: onChange,
        ),
        FilledButton(
          style: _obPrimaryBtn,
          onPressed: onNext,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _motive() {
    final d = _data.weightCurrent - _data.weightGoal;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        if (d > 0)
          Text(
            '${d.toStringAsFixed(1)} kg',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: AppTheme.teal,
            ),
          ),
        const SizedBox(height: 6),
        Text(
          d > 0
              ? 'Vamos conquistar esses ${d.toStringAsFixed(1)} kg juntos'
              : 'Boa! Vamos acompanhar sua jornada com segurança',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Com o Inove GLP, você pode:',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
        _miniTip(Icons.shield_outlined, 'Preservar sua massa muscular'),
        _miniTip(Icons.favorite_border, 'Garantir nutrientes essenciais'),
        _miniTip(
          Icons.trending_down,
          'Acompanhar a perda de gordura com dados',
        ),
        _miniTip(Icons.bolt, 'Manter energia no dia a dia'),
        const SizedBox(height: 20),
        FilledButton(
          style: _obPrimaryBtn,
          onPressed: () => unawaited(_go(12)),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _miniTip(IconData i, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEAF8F6),
              AppTheme.teal.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(i, color: AppTheme.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activity() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const Text(
          'Quantas vezes na semana você se exercita? 💪',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Seu nível de atividade física',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 16),
        SelectablePill(
          title: 'Sedentário',
          subtitle: 'Pouco ou nenhum exercício',
          onTap: () {
            setState(() => _data.activityKey = 'sedentary');
            unawaited(_go(13));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'Levemente ativo',
          subtitle: 'Exercício leve 1-3x/semana',
          onTap: () {
            setState(() => _data.activityKey = 'light');
            unawaited(_go(13));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'Moderado',
          subtitle: '3-5 dias por semana',
          onTap: () {
            setState(() => _data.activityKey = 'moderate');
            unawaited(_go(13));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'Intenso',
          subtitle: '6-7 dias por semana',
          onTap: () {
            setState(() => _data.activityKey = 'intense');
            unawaited(_go(13));
          },
        ),
      ],
    );
  }

  Widget _name() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const Text(
          'Como podemos te chamar? 👋',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Vamos personalizar a sua experiência',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.teal.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.teal.withValues(alpha: 0.18),
                backgroundImage: _onboardingPhotoPath != null
                    ? FileImage(File(_onboardingPhotoPath!))
                    : null,
                child: _onboardingPhotoPath == null
                    ? const Icon(Icons.person_rounded, color: AppTheme.teal, size: 30)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _onboardingPhotoPath == null
                      ? 'Adicione uma foto de perfil (opcional)'
                      : 'Foto selecionada',
                  style: TextStyle(
                    color: AppTheme.navy.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: _pickOnboardingPhoto,
                child: Text(_onboardingPhotoPath == null ? 'Inserir' : 'Trocar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'NOME',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameC,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Ex: Maria',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: _obPrimaryBtn,
          onPressed: _nameC.text.trim().isEmpty
              ? null
              : () {
                  _data.displayName = _nameC.text.trim();
                  unawaited(_go(14));
                },
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _loading() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 4000),
      builder: (context, v, _) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: v.clamp(0, 1),
                      strokeWidth: 7,
                      color: AppTheme.teal,
                      backgroundColor: AppTheme.teal.withValues(alpha: 0.12),
                    ),
                  ),
                  Text(
                    '${(v * 100).round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppTheme.navy,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Calculando seu plano nutricional e treino com IA…',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _loadLine('Analisando perfil de saúde', v > 0.08),
            _loadLine(
              'Calculando métricas personalizadas',
              v > 0.22,
              bold: true,
            ),
            _loadLine('Definindo objetivos', v > 0.38),
            _loadLine('Preparando seu plano de metas diárias', v > 0.52),
            _loadLine(
              'Gerando treino personalizado por IA',
              v > 0.66,
              bold: true,
            ),
            _loadLine('Finalizando recomendações inteligentes', v > 0.82),
          ],
        );
      },
    );
  }

  Widget _loadLine(String t, bool ok, {bool bold = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ok ? AppTheme.teal.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ok
              ? AppTheme.teal.withValues(alpha: 0.3)
              : AppTheme.navy.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          AnimatedScale(
            scale: ok ? 1 : 0.9,
            duration: const Duration(milliseconds: 260),
            child: Icon(
              ok ? Icons.check_circle : Icons.radio_button_unchecked,
              color: ok ? AppTheme.success : Colors.grey.shade300,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: ok
                    ? AppTheme.navy
                    : AppTheme.navy.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plan() {
    final draft = _profileDraft();
    final p = AppState.buildNutrients(draft);
    final mealsWithProtein = (p.proteinTargetG / 25).ceil().clamp(2, 8);
    final bmiNow = p.bmi;
    final bmiGoal = p.bmiGoal;
    final kgToLose = p.kgToLose > 0 ? p.kgToLose : 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const SizedBox(height: 4),
        Text(
          '${_firstName(p.name)}, seu plano está pronto!',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Criamos metas iniciais com base no seu perfil.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        _tagRow(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.navy,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${p.sex == "f" ? "Feminino" : "Masculino"} · ${p.age} anos · ${p.heightCm}cm',
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.medication, color: AppTheme.teal),
                  title: Text(
                    p.medicationLine,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${p.doseLabel} · a cada ${p.frequencyDays} dia(s)',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sua meta de peso',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _colKpi('Peso', p.startWeightKg.toStringAsFixed(1), 'inicial'),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                _colKpi(
                  'Meta',
                  p.goalWeightKg.toStringAsFixed(1),
                  'kg',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Metas diárias recomendadas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _targetTile(
              title: 'Água',
              value: '${p.waterTargetL.toStringAsFixed(1)}L',
              subtitle: 'hidratação diária',
              icon: Icons.water_drop_outlined,
              color: AppTheme.hydrationTeal,
            ),
            _targetTile(
              title: 'Proteína',
              value: '${p.proteinTargetG.toStringAsFixed(0)}g',
              subtitle: '$mealsWithProtein refeições ricas',
              icon: Icons.fitness_center_outlined,
              color: AppTheme.navy,
            ),
            _targetTile(
              title: 'Fibras',
              value: '${p.fiberTargetG.toStringAsFixed(0)}g',
              subtitle: 'saúde intestinal',
              icon: Icons.eco_outlined,
              color: AppTheme.success,
            ),
            _targetTile(
              title: 'Carboidratos',
              value: '${p.carbTargetG.toStringAsFixed(0)}g',
              subtitle: 'energia e adesão',
              icon: Icons.grain_outlined,
              color: AppTheme.purple,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Indicadores do seu perfil',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _colKpi('IMC atual', bmiNow.toStringAsFixed(1), ''),
                _colKpi('IMC meta', bmiGoal.toStringAsFixed(1), ''),
                _colKpi('Redução', kgToLose.toStringAsFixed(1), 'kg'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: _obPrimaryBtn,
          onPressed: () => unawaited(_go(17)),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _targetTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.navy.withValues(alpha: 0.62),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _colKpi(String l, String v, String s, {Color? color}) {
    return Column(
      children: [
        Text(l, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        Text(
          v,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color ?? AppTheme.navy,
          ),
        ),
        if (s.isNotEmpty) Text(s, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _tagRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip('Personalizado', Icons.person, Colors.green),
        const SizedBox(width: 8),
        _chip('Base científica', Icons.science, AppTheme.purple),
      ],
    );
  }

  Widget _chip(String t, IconData i, Color c) {
    return Chip(
      side: BorderSide(color: c.withValues(alpha: 0.25)),
      backgroundColor: c.withValues(alpha: 0.1),
      avatar: Icon(i, size: 16, color: c),
      label: Text(t),
    );
  }

  Widget _account() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text(
          'Salve seu progresso',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.navy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailC,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.email_outlined),
            hintText: 'Seu e-mail',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            filled: true,
            fillColor: Color(0xFFF5F5F5),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passC,
          obscureText: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.lock_outline),
            hintText: 'Crie uma senha (mín. 6 caracteres)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            filled: true,
            fillColor: Color(0xFFF5F5F5),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.navy,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          onPressed: () {
            final e = _emailC.text.trim();
            if (e.isNotEmpty && _passC.text.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('A senha precisa de pelo menos 6 caracteres.'),
                ),
              );
              return;
            }
            if (e.isNotEmpty) {
              unawaited(_finish());
            }
          },
          child: const Text('Continuar com e-mail'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => unawaited(_finish()),
          child: const Text('Entrar sem criar conta agora (demo)'),
        ),
      ],
    );
  }

  Widget _trainingPreview() {
    final profile = AppState.buildNutrients(_profileDraft());
    final plan = TrainingAi.generate(
      profile: profile,
      id: 'onboarding-preview',
      now: DateTime.now(),
      preferredActivities: _data.trainingPreferences,
    );
    final first = _firstName(profile.name);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppTheme.brandHeaderGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.navy.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFDE047),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$first, seu treino com IA está pronto',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Montamos sessões alinhadas ao seu perfil, medicamento e preferências.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _aiStatTile(
                icon: Icons.calendar_month_rounded,
                color: AppTheme.teal,
                value: '${plan.sessionsPerWeek}×',
                label: 'por semana',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _aiStatTile(
                icon: Icons.timer_rounded,
                color: AppTheme.purple,
                value: '${plan.averageSessionMinutes} min',
                label: 'média por treino',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _aiStatTile(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEA580C),
                value: '${plan.weeklyCaloriesTarget} kcal',
                label: 'gasto semanal alvo',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _aiStatTile(
                icon: Icons.flag_rounded,
                color: AppTheme.success,
                value: '${plan.estimatedWeeksToGoal} sem',
                label: '${plan.estimatedDaysToGoal} dias estimados',
              ),
            ),
          ],
        ),
        if (plan.rationale.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text(
            'Por que esse plano',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.purple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.purple.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < plan.rationale.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        size: 20,
                        color: AppTheme.purple,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          plan.rationale[i],
                          style: TextStyle(
                            height: 1.4,
                            fontSize: 13,
                            color: AppTheme.navy.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (i < plan.rationale.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            const Icon(Icons.calendar_view_week_rounded, color: AppTheme.teal),
            const SizedBox(width: 8),
            const Text(
              'Sua semana de treinos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Toque em continuar para salvar esse plano no app.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        ...plan.sessions.map(_aiSessionCard),
        const SizedBox(height: 16),
        FilledButton(
          style: _obPrimaryBtn.copyWith(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 17),
            ),
          ),
          onPressed: () => unawaited(_go(18)),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  TrainingModalityDef _modalityForKey(String key) {
    for (final m in kTrainingModalities) {
      if (m.key == key) {
        return m;
      }
    }
    return kTrainingModalities.last;
  }

  Widget _aiStatTile({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softCardShadow,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 19,
              height: 1,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiSessionCard(TrainingSessionPlan session) {
    final m = _modalityForKey(session.modalityKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: AppTheme.surfaceCard,
          boxShadow: AppTheme.softCardShadow,
          border: Border.all(color: m.accent.withValues(alpha: 0.14)),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      m.accent,
                      m.accent.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: m.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                session.dayLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: m.accent,
                                ),
                              ),
                            ),
                          ),
                          Icon(m.icon, color: m.accent, size: 26),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        session.focus,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppTheme.navy,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _miniStatChip(
                            icon: Icons.timer_rounded,
                            text: '${session.estimatedMinutes} min',
                            color: m.accent,
                          ),
                          _miniStatChip(
                            icon: Icons.local_fire_department_rounded,
                            text: '${session.estimatedCalories} kcal',
                            color: const Color(0xFFEA580C),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final exercise in session.exercises.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: AppTheme.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  exercise,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: AppTheme.navy.withValues(
                                      alpha: 0.86,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trainingPreferencesStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text(
          'Que tipo de treino você prefere?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.navy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Combine modalidades tocando nos blocos. '
          'A primeira da lista pesa mais no plano.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textMuted,
            height: 1.4,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        TrainingModalityGrid(
          selectedKeys: _data.trainingPreferences,
          onChanged: (v) => setState(() => _data.trainingPreferences = v),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: _obPrimaryBtn,
          onPressed: () => unawaited(_go(15)),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Gerar treino com IA'),
        ),
      ],
    );
  }
}

String _firstName(String s) {
  final p = s.trim().split(' ').where((e) => e.isNotEmpty).toList();
  if (p.isEmpty) {
    return 'Olá';
  }
  return p.first;
}
