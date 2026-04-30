import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/food_presets.dart';

const _geminiDefine = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'AIzaSyA7nORjvTR_tVjFLcKlm0JcAChbbxPAK0M',
);
const _kGeminiRuntimeKey = 'inove_gemini_runtime_api_key';
const _geminiCandidateModels = <String>['gemini-2.0-flash', 'gemini-2.0-flash-lite'];

class FoodVisionEstimate {
  const FoodVisionEstimate({
    required this.label,
    required this.proteinG,
    required this.fiberG,
    required this.carbG,
    required this.manualKcalHint,
    this.aiGenerated = false,
  });

  final String label;
  final double proteinG;
  final double fiberG;
  final double carbG;
  final double manualKcalHint;
  final bool aiGenerated;
  static String? _lastGeminiError;
  static String? get lastGeminiError => _lastGeminiError;

  static Uri _modelUrl(String model, String key) {
    return Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${Uri.encodeQueryComponent(key)}',
    );
  }

  static Future<List<String>> _discoverModels(String key) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=${Uri.encodeQueryComponent(key)}',
      );
      final res = await http.get(url);
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final models = (map['models'] as List<dynamic>? ?? const []);
      final names = <String>[];
      for (final item in models) {
        final m = item as Map<String, dynamic>;
        final methods = (m['supportedGenerationMethods'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toSet();
        if (!methods.contains('generateContent')) continue;
        final name = (m['name'] as String?) ?? '';
        if (!name.startsWith('models/')) continue;
        final short = name.substring('models/'.length).trim();
        if (short.isEmpty) continue;
        if (!short.contains('gemini')) continue;
        names.add(short);
      }
      return names;
    } catch (_) {
      return const [];
    }
  }

  static List<String> _orderedModelCandidates(List<String> discovered) {
    final merged = <String>[];
    for (final m in _geminiCandidateModels) {
      if (!merged.contains(m)) merged.add(m);
    }
    for (final m in discovered) {
      if (!merged.contains(m)) merged.add(m);
    }
    merged.sort((a, b) {
      final af = (a.contains('flash') ? 0 : 1) + (a.contains('2.0') ? 0 : 1);
      final bf = (b.contains('flash') ? 0 : 1) + (b.contains('2.0') ? 0 : 1);
      if (af != bf) return af.compareTo(bf);
      return a.compareTo(b);
    });
    return merged;
  }

  static FoodVisionEstimate fromHeuristic(String text, {String extraLabel = ''}) {
    final raw = '${text.trim()} ${extraLabel.trim()}'.trim().toLowerCase();
    if (raw.isEmpty) {
      return FoodVisionEstimate(
        label:
            '${extraLabel.trim().isNotEmpty ? '${extraLabel.trim()} · ' : ''}Porção média',
        proteinG: 18,
        fiberG: 4,
        carbG: 42,
        manualKcalHint: 25,
        aiGenerated: false,
      );
    }
    var bestScore = 0.0;
    FoodPreset best = kFoodPresets[(kFoodPresets.length ~/ 3).clamp(0, kFoodPresets.length - 1)];
    for (final f in kFoodPresets) {
      final nm = f.name.toLowerCase();
      var s = 0.0;
      for (final w in raw.split(RegExp(r'[\s,;.]+'))) {
        if (w.length < 3) {
          continue;
        }
        if (nm.contains(w)) {
          s += w.length.toDouble().clamp(2, 8);
        }
      }
      for (final m in nm.split(RegExp(r'[\s(,]+'))) {
        if (m.length < 4) continue;
        if (raw.contains(m)) {
          s += 3;
        }
      }
      if (s > bestScore) {
        bestScore = s;
        best = f;
      }
    }
    if (bestScore < 5) {
      final p =
          raw.contains(RegExp(r'(?:doce|bolo|açúcar)')) ? 6.0 : (raw.contains('carne') ? 28.0 : 14.0);
      final fg = raw.contains(RegExp(r'(?:salada|veget|folha)')) ? 8.0 : 5.0;
      final cg = raw.contains(RegExp(r'(?:arroz|macarrão|massa|pão)'))
          ? 65.0
          : raw.contains(RegExp(r'(?:doce|sobremesa|refrigerante)'))
              ? 55.0
              : 30.0;
      return FoodVisionEstimate(
        label:
            '${extraLabel.trim().isNotEmpty ? '${extraLabel.trim()} · ' : ''}Combinação (est.)',
        proteinG: p,
        fiberG: fg,
        carbG: cg,
        manualKcalHint: 40,
        aiGenerated: false,
      );
    }
    final prefix = extraLabel.trim().isNotEmpty ? '${extraLabel.trim()} · ' : '';
    return FoodVisionEstimate(
      label: '$prefix${best.name} (similar)',
      proteinG: best.proteinG,
      fiberG: best.fiberG,
      carbG: best.carbG,
      manualKcalHint:
          (((best.proteinG * 4) + (best.carbG * 4) + (best.fiberG * 2)) * 0.08).clamp(0, 90),
      aiGenerated: false,
    );
  }

  static Future<FoodVisionEstimate?> fromGeminiVision({
    required List<int> imageBytes,
    required String mime,
    required String caption,
    String? apiKey,
  }) async {
    _lastGeminiError = null;
    final key = (apiKey ?? await configuredApiKey()).trim();
    if (key.isEmpty) {
      _lastGeminiError = 'Chave Gemini ausente.';
      return null;
    }
    if (imageBytes.isEmpty) {
      _lastGeminiError = 'Imagem vazia.';
      return null;
    }

    final b64 = base64Encode(imageBytes);

    final prompt =
        '''You analyze a meal photo for a nutrition app in Portuguese context (Brazil).
Optional user caption: ${caption.trim().isEmpty ? 'none' : caption}

Respond ONLY compact JSON UTF-8, no markdown:
{"label":"short PT name","proteinG":number,"fiberG":number,"carbG":number,"kcalExtras":number}

kcalExtras = extra kcal beyond 4P+4Carb+2Fiber from fats/oils, 0 if unknown.
Reasonable portions.''';

    try {
      final discovered = await _discoverModels(key);
      final candidates = _orderedModelCandidates(discovered);
      http.Response? successResponse;
      String? lastModelError;
      for (final model in candidates) {
        final url = _modelUrl(model, key);
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: utf8.encode(
            jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inline_data': {'mime_type': mime, 'data': b64},
                    },
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.25},
            }),
          ),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          successResponse = res;
          break;
        }
        try {
          final em = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final e = em['error'] as Map<String, dynamic>?;
          final msg = (e?['message'] as String?)?.trim();
          if (msg != null && msg.isNotEmpty) {
            lastModelError = '$model: $msg';
          } else {
            lastModelError = '$model: HTTP ${res.statusCode}';
          }
        } catch (_) {
          lastModelError = '$model: HTTP ${res.statusCode}';
        }
      }
      if (successResponse == null) {
        _lastGeminiError = lastModelError ?? 'Nenhum modelo Gemini compatível respondeu.';
        return null;
      }

      final map = jsonDecode(utf8.decode(successResponse.bodyBytes)) as Map<String, dynamic>;
      final cands = map['candidates'] as List<dynamic>?;
      if (cands == null || cands.isEmpty) {
        _lastGeminiError = 'Resposta sem candidates.';
        return null;
      }
      final parts =
          (((cands.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?) ??
                  const {})['parts'] as List<dynamic>? ??
              [];
      if (parts.isEmpty) {
        _lastGeminiError = 'Resposta sem parts.';
        return null;
      }
      final text = (parts.first as Map<String, dynamic>)['text'] as String? ?? '';
      var stripped =
          text.replaceAll(RegExp(r'```(?:json)?\s*'), '').replaceAll('```', '').trim();
      final start = stripped.indexOf('{');
      final end = stripped.lastIndexOf('}');
      if (start < 0 || end <= start) {
        _lastGeminiError = 'Resposta sem JSON válido.';
        return null;
      }
      stripped = stripped.substring(start, end + 1);
      final jmap = jsonDecode(stripped) as Map<String, dynamic>;
      final lbl = (jmap['label'] as String?)?.trim() ?? 'Refeição';
      final pg = ((jmap['proteinG'] as num?) ?? 0)
          .toDouble()
          .clamp(0.0, 250.0)
          .toDouble();
      final fg =
          ((jmap['fiberG'] as num?) ?? 0).toDouble().clamp(0.0, 120.0).toDouble();
      final cg =
          ((jmap['carbG'] as num?) ?? 0).toDouble().clamp(0.0, 420.0).toDouble();
      final ke = ((jmap['kcalExtras'] as num?) ?? 0)
          .toDouble()
          .clamp(0.0, 2000.0)
          .toDouble();
      return FoodVisionEstimate(
        label: lbl,
        proteinG: pg,
        fiberG: fg,
        carbG: cg,
        manualKcalHint: ke,
        aiGenerated: true,
      );
    } catch (e) {
      _lastGeminiError = 'Falha de leitura Gemini: $e';
      return null;
    }
  }

  static Future<String?> testGeminiConnection() async {
    final key = (await configuredApiKey()).trim();
    if (key.isEmpty) return 'Chave Gemini não configurada.';
    try {
      final discovered = await _discoverModels(key);
      final candidates = _orderedModelCandidates(discovered);
      if (candidates.isEmpty) return 'Nenhum modelo disponível para generateContent na sua chave.';
      String? lastError;
      for (final model in candidates) {
        final url = _modelUrl(model, key);
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': 'Reply ONLY: OK'},
                ],
              },
            ],
            'generationConfig': {'temperature': 0},
          }),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) return null;
        try {
          final em = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final e = em['error'] as Map<String, dynamic>?;
          final m = (e?['message'] as String?)?.trim();
          if (m != null && m.isNotEmpty) {
            lastError = '$model: $m';
          } else {
            lastError = '$model: HTTP ${res.statusCode}';
          }
        } catch (_) {
          lastError = '$model: HTTP ${res.statusCode}';
        }
      }
      return lastError ?? 'Erro desconhecido na validação da chave.';
    } catch (e) {
      return 'Falha de rede ao testar Gemini: $e';
    }
  }

  static Future<String> configuredApiKey() async {
    final p = await SharedPreferences.getInstance();
    final runtime = (p.getString(_kGeminiRuntimeKey) ?? '').trim();
    if (runtime.isNotEmpty) return runtime;
    return _geminiDefine.trim();
  }

  static Future<void> setRuntimeApiKey(String? key) async {
    final p = await SharedPreferences.getInstance();
    final v = key?.trim() ?? '';
    if (v.isEmpty) {
      await p.remove(_kGeminiRuntimeKey);
      return;
    }
    await p.setString(_kGeminiRuntimeKey, v);
  }

  static Future<bool> hasAnyApiKey() async {
    final k = await configuredApiKey();
    return k.trim().isNotEmpty;
  }
}
