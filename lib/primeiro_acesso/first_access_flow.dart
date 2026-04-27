import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/data/medications.dart';
import '../core/models/user_profile.dart';
import '../core/services/app_state.dart';
import '../core/theme/app_theme.dart';
import 'onboarding_data.dart';
import 'onboarding_header.dart';

const int kOnboardSteps = 17;

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
  late final FixedExtentScrollController _ageScroll;
  late final FixedExtentScrollController _heightScroll;

  @override
  void initState() {
    super.initState();
    _data.syncDoseToMedication();
    _ageScroll = FixedExtentScrollController(initialItem: _data.age - 15);
    _heightScroll = FixedExtentScrollController(initialItem: _data.heightCm - 120);
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
      if (p != 14) _loadingScheduled = false;
    });
    if (p == 14 && !_loadingScheduled) {
      _loadingScheduled = true;
      Future<void>.delayed(const Duration(milliseconds: 2400), () {
        if (!mounted) return;
        if (_page != 14) return;
        unawaited(_go(15));
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
    );
  }

  Future<void> _finish() async {
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
        proteinTargetG: p.proteinTargetG,
        fiberTargetG: p.fiberTargetG,
        waterTargetL: p.waterTargetL,
        carbTargetG: p.carbTargetG,
      );
    }
    if (p.name.isEmpty) {
      return;
    }
    await context.read<AppState>().completeOnboarding(p, acceptTerms: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                  _welcome(),
                  _glpQ(),
                  _medList(),
                  _dose(),
                  _freq(),
                  _features(),
                  _sex(),
                  _age(),
                  _heightP(),
                  _wCur(),
                  _wGoal(),
                  _motive(),
                  _activity(),
                  _name(),
                  _loading(),
                  _plan(),
                  _account(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Image.asset(
            'assets/logo.png',
            height: 120,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'primeiro_acesso/1.png',
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (c, e, st) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => unawaited(_go(1)),
          child: const Text('Começar'),
        ),
        const SizedBox(height: 12),
        Text(
          'Tirzepatida, Mounjaro e muito mais.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _glpQ() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text(
          'Você está usando alguma caneta no momento? 💉',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha sua situação atual',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 28),
        SelectablePill(
          title: 'Já estou usando GLP-1',
          subtitle: 'e quero resultados melhores',
          onTap: () {
            setState(() => _data.usingGlp1 = true);
            unawaited(_go(2));
          },
        ),
        const SizedBox(height: 12),
        SelectablePill(
          title: 'Quero começar GLP-1',
          subtitle: 'Iniciar meu tratamento',
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text(
          'Qual medicamento GLP-1 você vai usar? 💉',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...kMedicationLines.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _data.medicationLine = e;
                  _data.syncDoseToMedication();
                });
                unawaited(_go(3));
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  e,
                  style: const TextStyle(color: Colors.black87),
                ),
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Doses disponíveis para ${_data.medicationLine.split("®").first}®',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            for (final d in opts)
              OutlinedButton(
                onPressed: () {
                  setState(() => _data.doseLabel = d);
                  unawaited(_go(4));
                },
                child: Text(d),
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quantos dias entre cada aplicação',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 20),
        SelectablePill(
          title: 'Diariamente',
          onTap: () {
            setState(() => _data.frequencyDays = 1);
            unawaited(_go(5));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'A cada 7 dias',
          onTap: () {
            setState(() => _data.frequencyDays = 7);
            unawaited(_go(5));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'A cada 15 dias',
          onTap: () {
            setState(() => _data.frequencyDays = 15);
            unawaited(_go(5));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'A cada mês',
          onTap: () {
            setState(() => _data.frequencyDays = 30);
            unawaited(_go(5));
          },
        ),
        const SizedBox(height: 10),
        SelectablePill(
          title: 'Ainda não sei',
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'primeiro_acesso/6.png',
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (c, e, st) => const Icon(Icons.sensors, size: 64),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Seja lembrada(o) da sua próxima dose',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        _checkRow('Registre cada aplicação', 'Histórico com datas e doses', Icons.event),
        const SizedBox(height: 10),
        _checkRow('Lembretes inteligentes', 'Notificações no momento certo', Icons.notifications),
        const SizedBox(height: 10),
        _checkRow('Acompanhe seu progresso', 'Peso, metas e jornada', Icons.show_chart),
        const SizedBox(height: 20),
        Text(
          'Milhares de pessoas acompanhando o tratamento com clareza.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => unawaited(_go(6)),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _checkRow(String t, String s, IconData i) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
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
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
        ],
      ),
    );
  }

  Widget _sex() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text(
          'Qual seu sexo?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Para cálculos nutricionais mais precisos',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 28),
        SelectablePill(
          title: 'Feminino',
          onTap: () {
            setState(() => _data.sex = 'f');
            unawaited(_go(7));
          },
        ),
        const SizedBox(height: 12),
        SelectablePill(
          title: 'Masculino',
          onTap: () {
            setState(() => _data.sex = 'm');
            unawaited(_go(7));
          },
        ),
      ],
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
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Text(
          valueLabel,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(
          height: 220,
          child: child,
        ),
        const Spacer(),
        FilledButton(
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Recalcularemos seu progresso e timeline',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Text(
          '${_data.weightGoal.toStringAsFixed(1)} kg',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w500,
          ),
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
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, height: 1.3),
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Com o Inove GLP, você pode:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        _miniTip(Icons.shield_outlined, 'Preservar sua massa muscular'),
        _miniTip(Icons.favorite_border, 'Garantir nutrientes essenciais'),
        _miniTip(Icons.trending_down, 'Acompanhar a perda de gordura com dados'),
        _miniTip(Icons.bolt, 'Manter energia no dia a dia'),
        const SizedBox(height: 20),
        FilledButton(
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
          color: const Color(0xFFF0FAF9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(i, color: AppTheme.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Seu nível de atividade física',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Vamos personalizar a sua experiência',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        const Text('NOME', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
        duration: const Duration(seconds: 2),
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
                        value: (v * 0.4).clamp(0, 0.4),
                        strokeWidth: 6,
                        color: Colors.black87,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    Text('${(v * 100).round()}%'),
                  ],
                ),
              ),
              const Text(
                'Calculando necessidades nutricionais...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _loadLine('Analisando perfil de saúde', v > 0.1),
              _loadLine('Calculando métricas personalizadas', v > 0.3, bold: true),
              _loadLine('Definindo objetivos', v > 0.55),
              _loadLine('Preparando seu plano', v > 0.75),
            ],
          );
        },
    );
  }

  Widget _loadLine(String t, bool ok, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            color: ok ? Colors.green : Colors.grey.shade300,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: ok ? Colors.black87 : Colors.grey.shade400,
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const SizedBox(height: 4),
        Text(
          '${_firstName(p.name)}, seu plano está pronto!',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
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
                  subtitle: Text('${p.doseLabel} · a cada ${p.frequencyDays} dia(s)'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Sua meta de peso', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _colKpi('Peso', p.startWeightKg.toStringAsFixed(1), 'inicial'),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                _colKpi('Meta', p.goalWeightKg.toStringAsFixed(1), 'kg', color: Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Proteína alvo: ${p.proteinTargetG.toStringAsFixed(0)}g · Fibras: ${p.fiberTargetG.toStringAsFixed(0)}g · Água: ${p.waterTargetL.toStringAsFixed(1)}L',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => unawaited(_go(16)),
          child: const Text('Continuar'),
        ),
      ],
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
        Text(s, style: const TextStyle(fontSize: 11)),
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
            fontWeight: FontWeight.w800,
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
}

String _firstName(String s) {
  final p = s.trim().split(' ').where((e) => e.isNotEmpty).toList();
  if (p.isEmpty) {
    return 'Olá';
  }
  return p.first;
}
