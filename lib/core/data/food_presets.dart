class FoodPreset {
  const FoodPreset({
    required this.name,
    required this.proteinG,
    required this.fiberG,
    required this.carbG,
  });

  final String name;
  final double proteinG;
  final double fiberG;
  final double carbG;
}

const kFoodPresets = <FoodPreset>[
  FoodPreset(name: 'Ovo cozido (2un)', proteinG: 12, fiberG: 0, carbG: 1),
  FoodPreset(name: 'Peito de frango 100g grelhado', proteinG: 31, fiberG: 0, carbG: 0),
  FoodPreset(name: 'Iogurte grego 170g', proteinG: 17, fiberG: 0, carbG: 6),
  FoodPreset(name: 'Atum 100g (água)', proteinG: 25, fiberG: 0, carbG: 0),
  FoodPreset(name: 'Salada + azeite (porção)', proteinG: 3, fiberG: 4, carbG: 8),
  FoodPreset(name: 'Arroz + feijão (prato padrão)', proteinG: 10, fiberG: 8, carbG: 55),
  FoodPreset(name: 'Banana média', proteinG: 1, fiberG: 3, carbG: 27),
  FoodPreset(name: 'Pão integral (2 fatias)', proteinG: 8, fiberG: 4, carbG: 28),
];
