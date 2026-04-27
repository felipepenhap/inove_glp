enum SubscriptionTier { free, pro }

extension SubscriptionTierX on SubscriptionTier {
  bool get isPro => this == SubscriptionTier.pro;
}
