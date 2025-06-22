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
}
