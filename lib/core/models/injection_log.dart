import 'injection_site.dart';

class InjectionLog {
  const InjectionLog({
    required this.id,
    required this.at,
    required this.site,
    this.doseMcg,
    this.doseLabel,
    this.note,
  });

  final String id;
  final DateTime at;
  final InjectionSite site;
  final double? doseMcg;
  final String? doseLabel;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'site': site.name,
        'doseMcg': doseMcg,
        'doseLabel': doseLabel,
        'note': note,
      };

  static InjectionLog fromJson(Map<String, dynamic> m) {
    return InjectionLog(
      id: m['id'] as String,
      at: DateTime.parse(m['at'] as String),
      site: InjectionSite.values.firstWhere(
        (e) => e.name == m['site'],
        orElse: () => InjectionSite.other,
      ),
      doseMcg: (m['doseMcg'] as num?)?.toDouble(),
      doseLabel: m['doseLabel'] as String?,
      note: m['note'] as String?,
    );
  }
}
