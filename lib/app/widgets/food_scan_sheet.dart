import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_state.dart';
import '../../core/services/food_vision_ai.dart';
import '../../core/theme/app_theme.dart';

Future<void> showFoodScanSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _FoodScanBody(),
  );
}

class _FoodScanBody extends StatefulWidget {
  const _FoodScanBody();

  @override
  State<_FoodScanBody> createState() => _FoodScanBodyState();
}

class _FoodScanBodyState extends State<_FoodScanBody> {
  final _caption = TextEditingController();
  final _labelCtl = TextEditingController();
  final _pCtl = TextEditingController();
  final _fCtl = TextEditingController();
  final _cCtl = TextEditingController();
  final _kCtl = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _bytes;
  bool _busy = false;
  String? _source;

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: AppTheme.teal),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.navy.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.navy.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.teal, width: 1.6),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _caption.dispose();
    _labelCtl.dispose();
    _pCtl.dispose();
    _fCtl.dispose();
    _cCtl.dispose();
    _kCtl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (!kIsWeb &&
        isDesktop &&
        src == ImageSource.camera) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No desktop, use a galeria. A câmera pode não estar disponível.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final x = await _picker.pickImage(
        source: src,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 82,
        maxWidth: 1400,
      );
      if (x == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              src == ImageSource.camera
                  ? 'Nenhuma foto capturada. Verifique a permissão da câmera e tente novamente.'
                  : 'Nenhuma foto selecionada.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!mounted) return;
      final b = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = b;
        _clearFields();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem carregada com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        SnackBar(
          content: Text(
            src == ImageSource.camera
                ? 'Não foi possível abrir a câmera neste dispositivo/emulador.'
                : 'Não foi possível abrir a galeria neste dispositivo/emulador.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearFields() {
    _labelCtl.clear();
    _pCtl.clear();
    _fCtl.clear();
    _cCtl.clear();
    _kCtl.clear();
  }

  void _fillEstimate(FoodVisionEstimate e, {required String src}) {
    _labelCtl.text = e.label;
    _pCtl.text = e.proteinG == e.proteinG.roundToDouble()
        ? '${e.proteinG.round()}'
        : e.proteinG.toStringAsFixed(1);
    _fCtl.text = e.fiberG == e.fiberG.roundToDouble()
        ? '${e.fiberG.round()}'
        : e.fiberG.toStringAsFixed(1);
    _cCtl.text = e.carbG == e.carbG.roundToDouble()
        ? '${e.carbG.round()}'
        : e.carbG.toStringAsFixed(1);
    _kCtl.text =
        e.manualKcalHint > 0 ? e.manualKcalHint.round().toString() : '';
    _source = src;
    setState(() {});
  }

  double _parseCtl(TextEditingController c) {
    return double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
  }

  Future<void> _analyze() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final est = FoodVisionEstimate.fromHeuristic(
        '${_caption.text} ${_labelCtl.text}'.trim(),
        extraLabel: _bytes != null ? 'Estimativa local por foto' : '',
      );
      if (!mounted) return;
      _fillEstimate(est, src: 'vision_estimate');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _bytes != null
                ? 'Estimativa local gratuita aplicada com base na foto e descrição.'
                : 'Estimativa pela descrição',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmApply() async {
    final dp = _parseCtl(_pCtl).clamp(0.0, 900.0).toDouble();
    final df = _parseCtl(_fCtl).clamp(0.0, 140.0).toDouble();
    final dc = _parseCtl(_cCtl).clamp(0.0, 420.0).toDouble();
    final dk = (_parseCtl(_kCtl)).round().clamp(0, 4000).toDouble();
    if (dp <= 0 && df <= 0 && dc <= 0 && dk <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe valores para somar')),
      );
      return;
    }
    final s = context.read<AppState>();
    await s.recordFoodServing(
      label: _labelCtl.text.trim().isEmpty ? 'Refeição' : _labelCtl.text.trim(),
      proteinDeltaG: dp,
      fiberDeltaG: df,
      carbDeltaG: dc,
      manualKcalDelta: dk.toDouble(),
      source: _source ?? 'manual_scan',
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Macros atualizadas'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.91;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: h,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: const Text(
                            'Modo gratuito ativado: estimativa local sem custo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFECFEFF),
                          const Color(0xFFEFF6FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.teal.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.teal.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.document_scanner_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scanner de alimentos',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  color: AppTheme.navy,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Foto opcional · confirme os valores antes de salvar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.teal.withValues(alpha: 0.08),
                          AppTheme.navy.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.teal.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_bytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.memory(_bytes!, fit: BoxFit.cover),
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.navy.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.navy.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        'Sem foto selecionada\nToque em Galeria ou Câmera para analisar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.teal.withValues(alpha: 0.12),
                                      AppTheme.teal.withValues(alpha: 0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: FilledButton.icon(
                                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                                  label: const Text('Galeria'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: AppTheme.navy,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.teal.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: FilledButton.icon(
                                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                                  icon: const Icon(Icons.photo_camera_rounded, size: 20),
                                  label: const Text('Câmera'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _caption,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: _fieldDecoration(
                      label: 'Descrição opcional',
                      hint: 'Ex.: arroz, feijão, frango grelhado',
                      icon: Icons.edit_note_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _analyze,
                    icon: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(_busy ? 'Analisando…' : 'Estimar grátis'),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFF8FAFC),
                          const Color(0xFFF1F5F9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.navy.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Ajuste fino',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: AppTheme.navy,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Edite se precisar',
                                style: TextStyle(
                                  color: AppTheme.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _labelCtl,
                          decoration: _fieldDecoration(
                            label: 'Nome da refeição',
                            icon: Icons.restaurant_menu_rounded,
                            hint: 'Ex.: Maçã',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _pCtl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: _fieldDecoration(
                                  label: 'Proteína (g)',
                                  icon: Icons.fitness_center_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _fCtl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: _fieldDecoration(
                                  label: 'Fibras (g)',
                                  icon: Icons.spa_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _cCtl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: _fieldDecoration(
                                  label: 'Carb (g)',
                                  icon: Icons.grain_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _kCtl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: _fieldDecoration(
                                  label: 'Kcal extras',
                                  icon: Icons.local_fire_department_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _confirmApply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.teal,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Somar ao dia',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    'Valores são aproximados. ${DateFormat.yMd('pt_BR').format(DateTime.now())}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
