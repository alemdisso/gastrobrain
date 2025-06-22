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
}
