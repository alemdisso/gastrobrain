// lib/core/services/localized_error_messages.dart

/// Static localized error messages for services that don't have access to BuildContext.
/// These are used for logging and debugging purposes.
/// 
/// For user-facing errors, UI components should catch exceptions and display
/// localized messages using AppLocalizations.of(context).
class LocalizedErrorMessages {
  // English messages (for logging/debugging)
  static const Map<String, String> en = {
    'recommendationCountMustBePositive': 'Recommendation count must be positive',
    'noRecommendationFactorsRegistered': 'No recommendation factors registered',
    'errorGeneratingRecommendations': 'Error generating recommendations',
    'errorGettingCandidateRecipes': 'Error getting candidate recipes',
    'errorGettingRecipeProteinTypes': 'Error getting recipe protein types',
    'errorGettingLastCookedDates': 'Error getting last cooked dates',
    'errorGettingMealCounts': 'Error getting meal counts',
    'errorGettingRecentMeals': 'Error getting recent meals',
    'errorGettingRecipesWithStats': 'Error getting recipes with statistics',
    'errorGettingRecentlyCookedRecipeIds': 'Error getting recently cooked recipe IDs',
    'errorGettingRecentlyCookedProteinsByDate': 'Error getting recently cooked proteins by date',
    'errorCalculatingProteinPenaltyStrategy': 'Error calculating protein penalty strategy',
    'errorGettingProteinTypesForRecipes': 'Error getting protein types for recipes',
    'errorGeneratingDetailedRecommendations': 'Error generating detailed recommendations',
  };

  // Portuguese messages (for reference)
  static const Map<String, String> pt = {
    'recommendationCountMustBePositive': 'O número de recomendações deve ser positivo',
    'noRecommendationFactorsRegistered': 'Nenhum fator de recomendação registrado',
    'errorGeneratingRecommendations': 'Erro ao gerar recomendações',
    'errorGettingCandidateRecipes': 'Erro ao obter receitas candidatas',
    'errorGettingRecipeProteinTypes': 'Erro ao obter tipos de proteína das receitas',
    'errorGettingLastCookedDates': 'Erro ao obter datas da última preparação',
    'errorGettingMealCounts': 'Erro ao obter contagem de refeições',
    'errorGettingRecentMeals': 'Erro ao obter refeições recentes',
    'errorGettingRecipesWithStats': 'Erro ao obter receitas com estatísticas',
    'errorGettingRecentlyCookedRecipeIds': 'Erro ao obter IDs de receitas cozinhadas recentemente',
    'errorGettingRecentlyCookedProteinsByDate': 'Erro ao obter proteínas cozinhadas recentemente por data',
    'errorCalculatingProteinPenaltyStrategy': 'Erro ao calcular estratégia de penalidade de proteína',
    'errorGettingProteinTypesForRecipes': 'Erro ao obter tipos de proteína para receitas',
    'errorGeneratingDetailedRecommendations': 'Erro ao gerar recomendações detalhadas',
  };

  /// Get error message in English (for logging/debugging)
  static String getMessage(String key) {
    return en[key] ?? 'Unknown error';
  }

  /// Get Portuguese error message (for reference)
  static String getPortugueseMessage(String key) {
    return pt[key] ?? 'Erro desconhecido';
  }

  /// Get formatted error message for factors
  static String factorNotFound(String factorId) {
    return 'Factor not found: $factorId';
  }

  /// Get formatted error message for unknown weight profile
  static String unknownWeightProfile(String profileName) {
    return 'Unknown weight profile: $profileName';
  }
}