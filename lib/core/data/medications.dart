const kMedicationLines = <String>[
  'Mounjaro® (Tirzepatida)',
  'Ozempic® (Semaglutida)',
  'Wegovy® (Semaglutida)',
  'Saxenda® (Liraglutida)',
  'Victoza® (Liraglutida)',
  'Rybelsus® (Semaglutida Oral)',
  'Zepbound® (Tirzepatida)',
  'Trulicity® (Dulaglutida)',
  'Byetta® (Exenatida)',
  'Bydureon® (Exenatida ER)',
  'Adlyxin® (Lixisenatida)',
  'Tanzeum® (Albiglutida)',
];

List<String> doseLabelsForMedication(String line) {
  final l = line.toLowerCase();
  if (l.contains('tirzepatida') || l.contains('mounjaro') || l.contains('zepbound')) {
    return const ['2.5mg', '5mg', '7.5mg', '10mg', '12.5mg', '15mg'];
  }
  if (l.contains('semaglutida') && !l.contains('oral')) {
    return const ['0.25mg', '0.5mg', '1mg', '1.7mg', '2.4mg'];
  }
  if (l.contains('rybelsus') || l.contains('oral')) {
    return const ['3mg', '7mg', '14mg'];
  }
  if (l.contains('liraglutida') || l.contains('saxenda') || l.contains('victoza')) {
    return const ['0.6mg', '1.2mg', '1.8mg', '2.4mg', '3mg'];
  }
  if (l.contains('dulaglutida') || l.contains('trulicity')) {
    return const ['0.75mg', '1.5mg', '3mg', '4.5mg'];
  }
  if (l.contains('exenatida')) {
    return const ['5µg', '10µg'];
  }
  if (l.contains('lixisenatida')) {
    return const ['10µg', '20µg'];
  }
  if (l.contains('albiglutida')) {
    return const ['30mg', '50mg'];
  }
  return const ['Conforme prescrição'];
}
