enum InjectionSite {
  leftAbdomen,
  rightAbdomen,
  upperLeftAbdomen,
  upperRightAbdomen,
  leftThigh,
  rightThigh,
  leftArm,
  rightArm,
  other,
}

extension InjectionSiteX on InjectionSite {
  String get labelKey {
    switch (this) {
      case InjectionSite.leftAbdomen:
        return 'Abdômen esquerdo (inferior)';
      case InjectionSite.rightAbdomen:
        return 'Abdômen direito (inferior)';
      case InjectionSite.upperLeftAbdomen:
        return 'Abdômen esquerdo (superior)';
      case InjectionSite.upperRightAbdomen:
        return 'Abdômen direito (superior)';
      case InjectionSite.leftThigh:
        return 'Coxa esquerda';
      case InjectionSite.rightThigh:
        return 'Coxa direita';
      case InjectionSite.leftArm:
        return 'Braço esquerdo';
      case InjectionSite.rightArm:
        return 'Braço direito';
      case InjectionSite.other:
        return 'Outro local';
    }
  }
}
