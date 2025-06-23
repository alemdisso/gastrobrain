// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Gastrobrain';

  @override
  String get recipes => 'Receitas';

  @override
  String get mealPlan => 'Planejamento';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get deleteRecipe => 'Excluir Receita';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get sortOptions => 'Opções de Ordenação';

  @override
  String get name => 'Nome';

  @override
  String get rating => 'Avaliação';

  @override
  String get difficulty => 'Dificuldade';

  @override
  String get filterRecipes => 'Filtrar Receitas';

  @override
  String deleteConfirmation(String recipeName) {
    return 'Tem certeza que deseja excluir \"$recipeName\"?';
  }

  @override
  String get sortRecipes => 'Ordenar receitas';

  @override
  String get filterRecipesTooltip => 'Filtrar receitas';

  @override
  String get minimumRating => 'Avaliação Mínima';

  @override
  String get cookingFrequency => 'Frequência de Preparo';

  @override
  String get category => 'Categoria';

  @override
  String get any => 'Qualquer';

  @override
  String get clear => 'Limpar';

  @override
  String get apply => 'Aplicar';

  @override
  String get addRecipe => 'Adicionar Receita';

  @override
  String get addNewRecipe => 'Adicionar Nova Receita';

  @override
  String get recipeName => 'Nome da Receita';

  @override
  String get desiredFrequency => 'Frequência Desejada';

  @override
  String get difficultyLevel => 'Nível de Dificuldade';

  @override
  String get preparationTime => 'Tempo de Preparo';

  @override
  String get cookingTime => 'Tempo de Cozimento';

  @override
  String get notes => 'Observações';

  @override
  String get minutes => 'minutos';

  @override
  String get add => 'Adicionar';

  @override
  String get noIngredientsAdded => 'Nenhum ingrediente adicionado ainda';

  @override
  String get saveRecipe => 'Salvar Receita';

  @override
  String get loading => 'Carregando...';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get pleaseEnterRecipeName => 'Por favor, insira o nome da receita';

  @override
  String get pleaseEnterValidTime => 'Por favor, insira um tempo válido';

  @override
  String get errorSavingRecipe => 'Erro ao salvar receita:';

  @override
  String get unexpectedError => 'Ocorreu um erro inesperado';

  @override
  String get editRecipe => 'Editar Receita';

  @override
  String get saveChanges => 'Salvar Alterações';

  @override
  String get errorUpdatingRecipe => 'Erro ao atualizar receita:';

  @override
  String get errorLoadingIngredients => 'Erro ao carregar ingredientes:';

  @override
  String get unexpectedErrorLoadingIngredients =>
      'Ocorreu um erro inesperado ao carregar os ingredientes';

  @override
  String get unexpectedErrorDeletingIngredient =>
      'Ocorreu um erro inesperado ao excluir o ingrediente';

  @override
  String get anErrorOccurred => 'Ocorreu um erro';

  @override
  String get deleteIngredient => 'Excluir Ingrediente';

  @override
  String deleteIngredientConfirmation(String ingredientName) {
    return 'Tem certeza que deseja excluir $ingredientName?';
  }

  @override
  String get ingredientDeletedSuccessfully =>
      'Ingrediente excluído com sucesso';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get addIngredient => 'Adicionar Ingrediente';

  @override
  String get searchIngredients => 'Buscar ingredientes...';

  @override
  String get refresh => 'Atualizar';

  @override
  String get edit => 'Editar';

  @override
  String historyTitle(String recipeName) {
    return 'Histórico: $recipeName';
  }

  @override
  String get errorLoadingMeals => 'Erro ao carregar refeições:';

  @override
  String get unexpectedErrorLoadingMeals =>
      'Ocorreu um erro inesperado ao carregar as refeições';

  @override
  String get noMealsRecorded => 'Nenhuma refeição registrada ainda';

  @override
  String get mealUpdatedSuccessfully => 'Refeição atualizada com sucesso';

  @override
  String get errorEditingMeal => 'Erro ao editar refeição:';

  @override
  String recipesCount(int count) {
    return '$count receitas';
  }

  @override
  String get editMeal => 'Editar refeição';

  @override
  String get cookNow => 'Cozinhar Agora';

  @override
  String get fromMealPlan => 'Do planejamento de refeições';

  @override
  String actualTimes(String prepTime, String cookTime) {
    return 'Tempos reais - Preparo: ${prepTime}min, Cozimento: ${cookTime}min';
  }

  @override
  String get weeklyMealPlan => 'Planejamento Semanal de Refeições';

  @override
  String weekOf(String date) {
    return 'Semana de $date';
  }

  @override
  String get thisWeekRelative => 'Esta semana';

  @override
  String get nextWeekRelative => '+1 semana';

  @override
  String get previousWeekRelative => '-1 semana';

  @override
  String futureWeeksRelative(int count) {
    return '+$count semanas';
  }

  @override
  String pastWeeksRelative(int count) {
    return '$count semanas';
  }

  @override
  String additionalRecipesCount(int count) {
    return intl.Intl.plural(
      count,
      one: '$count receita',
      other: '$count receitas',
      locale: localeName,
    );
  }

  @override
  String get sunday => 'Domingo';

  @override
  String get monday => 'Segunda-feira';

  @override
  String get tuesday => 'Terça-feira';

  @override
  String get wednesday => 'Quarta-feira';

  @override
  String get thursday => 'Quinta-feira';

  @override
  String get friday => 'Sexta-feira';

  @override
  String get saturday => 'Sábado';

  @override
  String get lunch => 'Almoço';

  @override
  String get dinner => 'Jantar';

  @override
  String get today => 'Hoje';

  @override
  String get addMeal => 'Adicionar refeição';

  @override
  String get searchRecipesHint => 'Buscar receitas...';

  @override
  String get noIngredientsAddedYet => 'Nenhum ingrediente adicionado ainda';

  @override
  String get ingredientCategoryVegetable => 'Vegetal';

  @override
  String get ingredientCategoryFruit => 'Fruta';

  @override
  String get ingredientCategoryProtein => 'Proteína';

  @override
  String get ingredientCategoryDairy => 'Laticínios';

  @override
  String get ingredientCategoryGrain => 'Cereal';

  @override
  String get ingredientCategoryPulse => 'Leguminosa';

  @override
  String get ingredientCategoryNutsAndSeeds => 'Nozes e Sementes';

  @override
  String get ingredientCategorySeasoning => 'Tempero';

  @override
  String get ingredientCategorySugarProducts => 'Produtos Açucarados';

  @override
  String get ingredientCategoryOil => 'Óleo';

  @override
  String get ingredientCategoryOther => 'Outro';

  @override
  String get measurementUnitCup => 'Xícara';

  @override
  String get measurementUnitPiece => 'Unidade';

  @override
  String get measurementUnitSlice => 'Fatia';

  @override
  String get measurementUnitTablespoon => 'Colher de sopa';

  @override
  String get measurementUnitTeaspoon => 'Colher de chá';

  @override
  String get unitOptional => 'Unidade (Opcional)';

  @override
  String get noUnit => 'Sem unidade';

  @override
  String get editIngredient => 'Editar Ingrediente';

  @override
  String get newIngredient => 'Novo Ingrediente';

  @override
  String get ingredientName => 'Nome do Ingrediente';

  @override
  String get pleaseEnterIngredientName => 'Por favor, insira o nome do ingrediente';

  @override
  String get categoryLabel => 'Categoria';

  @override
  String get proteinTypeLabel => 'Tipo de Proteína';

  @override
  String get pleaseSelectProteinType => 'Por favor, selecione um tipo de proteína';

  @override
  String get notesOptional => 'Notas (Opcional)';

  @override
  String get anyAdditionalInformation => 'Qualquer informação adicional';

  @override
  String get addRecipeTitle => 'Adicionar Receita';

  @override
  String get remove => 'Remover';

  @override
  String get numberOfServings => 'Número de Porções';

  @override
  String get pleaseEnterNumberOfServings => 'Por favor, insira o número de porções';

  @override
  String get pleaseEnterValidNumber => 'Por favor, insira um número válido';

  @override
  String get prepTimeMin => 'Tempo de Preparo (min)';

  @override
  String get cookTimeMin => 'Tempo de Cozimento (min)';

  @override
  String get enterValidTime => 'Insira um tempo válido';

  @override
  String get wasItSuccessful => 'Foi bem-sucedido?';

  @override
  String editMealTitle(String recipeName) {
    return 'Editar $recipeName';
  }

  @override
  String get errorLoadingRecipes => 'Erro ao carregar receitas:';

  @override
  String get errorSelectingDate => 'Erro ao selecionar data';

  @override
  String get noAdditionalRecipesAvailable => 'Nenhuma receita adicional disponível.';

  @override
  String get errorPrefix => 'Erro:';

  @override
  String get errorLoadingData => 'Erro ao carregar dados:';

  @override
  String get errorRefreshingRecommendations => 'Erro ao atualizar recomendações:';

  @override
  String get selectIngredient => 'Selecionar Ingrediente';

  @override
  String get quantity => 'Quantidade';

  @override
  String get unit => 'Unidade';

  @override
  String get preparationNotesOptional => 'Notas de Preparo (Opcional)';

  @override
  String get typeToSearch => 'Digite para buscar...';

  @override
  String get preparationNotesHint => 'ex: finamente picado, em cubos, etc.';

  @override
  String get actualPrepTimeMin => 'Tempo Real de Preparo (min)';

  @override
  String get actualCookTimeMin => 'Tempo Real de Cozimento (min)';

  @override
  String get previousWeek => 'Semana Anterior';

  @override
  String get nextWeek => 'Próxima Semana';

  @override
  String get tapToJumpToCurrentWeek => 'Toque para ir para a semana atual';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get mealOptions => 'Opções de Refeição';

  @override
  String get viewRecipeDetails => 'Ver Detalhes da Receita';

  @override
  String get changeRecipe => 'Trocar Receita';

  @override
  String get manageRecipes => 'Gerenciar Receitas';

  @override
  String get markAsCooked => 'Marcar como Cozinhada';

  @override
  String get editCookedMeal => 'Editar Refeição Cozinhada';

  @override
  String get manageSideDishes => 'Gerenciar Acompanhamentos';

  @override
  String get removeFromPlan => 'Remover do Planejamento';

  @override
  String get plannedMealNotFound => 'Refeição planejada não encontrada';

  @override
  String get recipeNotFound => 'Receita não encontrada';

  @override
  String get mainDish => 'Prato principal';

  @override
  String get sideDish => 'Acompanhamento';

  @override
  String get mealMarkedAsCooked => 'Refeição marcada como cozinhada';

  @override
  String get mealNotFoundOrNotCooked =>
      'Refeição não encontrada ou ainda não cozinhada';

  @override
  String get couldNotFindCookedMeal =>
      'Não foi possível encontrar o registro da refeição cozinhada';

  @override
  String get sideDishesUpdatedSuccessfully =>
      'Acompanhamentos atualizados com sucesso';

  @override
  String get mealRecipesUpdatedSuccessfully =>
      'Receitas da refeição atualizadas com sucesso';

  @override
  String get noPrimaryRecipeFound => 'Nenhuma receita principal encontrada';

  @override
  String get addSideDishes => 'Adicionar Acompanhamentos';

  @override
  String get selectRecipe => 'Selecionar Receita';

  @override
  String get tryThis => 'Experimente';

  @override
  String get allRecipes => 'Todas as Receitas';

  @override
  String get noRecommendationsAvailable => 'Nenhuma recomendação disponível';

  @override
  String get save => 'Salvar';

  @override
  String get addThisRecipeToMealPlan =>
      'Adicionar esta receita ao planejamento de refeições';

  @override
  String get addMoreRecipesToThisMeal =>
      'Adicionar mais receitas a esta refeição';

  @override
  String get chooseDifferentRecipe => 'Escolher uma receita diferente';

  @override
  String get back => 'Voltar';

  @override
  String get addSideDish => 'Adicionar Acompanhamento';

  @override
  String get saveMeal => 'Salvar Refeição';

  @override
  String get recommendationCountMustBePositive =>
      'O número de recomendações deve ser positivo';

  @override
  String get noRecommendationFactorsRegistered =>
      'Nenhum fator de recomendação registrado';

  @override
  String unknownWeightProfile(String profileName) {
    return 'Perfil de peso desconhecido: $profileName';
  }

  @override
  String get errorGeneratingRecommendations => 'Erro ao gerar recomendações';

  @override
  String get errorGettingCandidateRecipes =>
      'Erro ao obter receitas candidatas';

  @override
  String get errorGettingRecipeProteinTypes =>
      'Erro ao obter tipos de proteína das receitas';

  @override
  String get errorGettingLastCookedDates =>
      'Erro ao obter datas da última preparação';

  @override
  String get errorGettingMealCounts => 'Erro ao obter contagem de refeições';

  @override
  String get errorGettingRecentMeals => 'Erro ao obter refeições recentes';

  @override
  String factorNotFound(String factorId) {
    return 'Fator não encontrado: $factorId';
  }

  @override
  String get weightProfileBalanced => 'Equilibrado';

  @override
  String get weightProfileFrequencyFocused => 'Focado em Frequência';

  @override
  String get weightProfileVarietyFocused => 'Focado em Variedade';

  @override
  String get weightProfileWeekday => 'Dia de Semana';

  @override
  String get weightProfileWeekend => 'Final de Semana';

  @override
  String get errorGettingRecipesWithStats =>
      'Erro ao obter receitas com estatísticas';

  @override
  String get errorGettingRecentlyCookedRecipeIds =>
      'Erro ao obter IDs de receitas cozinhadas recentemente';

  @override
  String get errorGettingRecentlyCookedProteinsByDate =>
      'Erro ao obter proteínas cozinhadas recentemente por data';

  @override
  String get errorCalculatingProteinPenaltyStrategy =>
      'Erro ao calcular estratégia de penalidade de proteína';

  @override
  String get errorGettingProteinTypesForRecipes =>
      'Erro ao obter tipos de proteína para receitas';

  @override
  String get frequencyDaily => 'Diário';

  @override
  String get frequencyWeekly => 'Semanal';

  @override
  String get frequencyBiweekly => 'Quinzenal';

  @override
  String get frequencyMonthly => 'Mensal';

  @override
  String get frequencyBimonthly => 'Bimestral';

  @override
  String get frequencyRarely => 'Raramente';

  @override
  String get proteinBeef => 'Carne Bovina';

  @override
  String get proteinChicken => 'Frango';

  @override
  String get proteinPork => 'Carne Suína';

  @override
  String get proteinFish => 'Peixe';

  @override
  String get proteinSeafood => 'Frutos do Mar';

  @override
  String get proteinLamb => 'Cordeiro';

  @override
  String get proteinCharcuterie => 'Charcutaria';

  @override
  String get proteinOffal => 'Miúdos';

  @override
  String get proteinPlantBased => 'À Base de Plantas';

  @override
  String get proteinOther => 'Outro';

  @override
  String get categoryMainDishes => 'Pratos principais';

  @override
  String get categorySideDishes => 'Acompanhamentos';

  @override
  String get categorySandwiches => 'Sanduíches';

  @override
  String get categoryCompleteMeals => 'Refeições completas';

  @override
  String get categoryBreakfastItems => 'Itens de café da manhã';

  @override
  String get categoryDesserts => 'Sobremesas';

  @override
  String get categorySoupsStews => 'Sopas/ensopados';

  @override
  String get categorySalads => 'Saladas';

  @override
  String get categorySauces => 'Molhos';

  @override
  String get categoryDips => 'Patês/molhos para mergulhar';

  @override
  String get categorySnacks => 'Petiscos';

  @override
  String get categoryUncategorized => 'Sem categoria';

  @override
  String get timeContextPast => 'Passado';

  @override
  String get timeContextCurrent => 'Atual';

  @override
  String get timeContextFuture => 'Futuro';

  @override
  String get timeContextPastDescription => 'Semana anterior';

  @override
  String get timeContextCurrentDescription => 'Esta semana';

  @override
  String get timeContextFutureDescription => 'Próxima semana';

  @override
  String get cookedOn => 'Cozinhado em';

  @override
  String get plannedFor => 'Planejado para';

  @override
  String get pleaseSelectAnIngredient => 'Por favor, selecione um ingrediente';

  @override
  String get createNewIngredient => 'Criar Novo Ingrediente';

  @override
  String get pleaseEnterQuantity => 'Por favor, insira uma quantidade';

  @override
  String get overrideDefaultUnit => 'Substituir unidade padrão';

  @override
  String get fromDatabase => 'Do Banco de Dados';

  @override
  String get custom => 'Personalizado';
}
