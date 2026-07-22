import 'package:flutter/foundation.dart';

enum GemstoneType { life, benefic, bhagya, dasha }

class GemstoneRecommendation {
  final String planet;
  final String primaryGemstone;
  final List<String> substituteGemstones;
  final GemstoneType type;
  final String metal;
  final String finger;
  final String dayToWear;
  final String weightRecommendation;
  final String keyBenefits;
  final bool isSafeToWear;
  final String cautionNote;

  const GemstoneRecommendation({
    required this.planet,
    required this.primaryGemstone,
    required this.substituteGemstones,
    required this.type,
    required this.metal,
    required this.finger,
    required this.dayToWear,
    required this.weightRecommendation,
    required this.keyBenefits,
    required this.isSafeToWear,
    this.cautionNote = '',
  });
}

class PlanetaryRemedy {
  final String planet;
  final String afflictionReason;
  final String beejMantra;
  final int mantraRecitationCount;
  final String rudrakshaMukhi;
  final String fastingDay;
  final String charityItems;
  final String deityToWorship;
  final String favorableDirection;
  final String favorableColor;

  const PlanetaryRemedy({
    required this.planet,
    required this.afflictionReason,
    required this.beejMantra,
    required this.mantraRecitationCount,
    required this.rudrakshaMukhi,
    required this.fastingDay,
    required this.charityItems,
    required this.deityToWorship,
    required this.favorableDirection,
    required this.favorableColor,
  });
}

class CompleteRemediesProfile {
  final List<GemstoneRecommendation> gemstones;
  final List<PlanetaryRemedy> planetaryRemedies;
  final String primaryRudraksha;
  final String overallGuidanceNote;

  const CompleteRemediesProfile({
    required this.gemstones,
    required this.planetaryRemedies,
    required this.primaryRudraksha,
    required this.overallGuidanceNote,
  });
}
