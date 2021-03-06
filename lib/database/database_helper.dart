import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:the_cookbook/models/Ingredient.dart';
import 'package:the_cookbook/models/cookbook.dart';
import 'package:the_cookbook/models/recipe.dart';
import 'package:the_cookbook/models/step.dart';

class DatabaseHelper  {

  static final DatabaseHelper _instance = new DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;
  static Database _db;
  String path;

  Future<Database> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  DatabaseHelper.internal();

  initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    path = join(documentsDirectory.path, "TheCookbook.db");
    var theCookbookDb = await openDatabase(path, version: 2, onCreate: _onCreate);
    return theCookbookDb;
  }


  Future _onCreate(Database db, int version) async {
    await db.execute(
      "PRAGMA foreign_keys=ON"
    );
    await db.execute(
      "CREATE TABLE Cookbooks ("
        "cookbookId INTEGER PRIMARY KEY,"
        "name TEXT,"
        "coverBase64Encoded TEXT"
      ");"
    );
    await db.execute(
      "CREATE TABLE Recipes ("
        "recipeId INTEGER PRIMARY KEY,"
        "cookbookId INTEGER,"
        "name TEXT,"
        "coverBase64Encoded TEXT,"
        "summary TEXT,"
        "durationInMinutes INTEGER,"
        "isFavourite INTEGER,"
        "level TEXT,"
        "CONSTRAINT cookbookId "
          "FOREIGN KEY (cookbookId) REFERENCES Cookbooks(cookbookId) "
          "ON DELETE CASCADE"
      ");"
    );
    await db.execute(
      "CREATE TABLE Ingredients ("
        "ingredientId INTEGER PRIMARY KEY,"
        "recipeId INTEGER,"
        "description TEXT,"
        "CONSTRAINT recipeId "
          "FOREIGN KEY (recipeId) REFERENCES Recipes(recipeId) "
          "ON DELETE CASCADE"
      ");"
    );
    await db.execute(
      "CREATE TABLE Steps ("
        "stepId INTEGER PRIMARY KEY,"
        "recipeId INTEGER,"
        "title TEXT,"
        "photoBase64Encoded TEXT,"
        "description TEXT,"
        "CONSTRAINT recipeId "
          "FOREIGN KEY (recipeId) REFERENCES Recipes(recipeId) "
          "ON DELETE CASCADE"
      ");"
    );
  }

  // Cookbook CRUD

  Future<int> saveCookbook(Cookbook cookbook) async {
    var theCookbookDb = await db;
    int res = await theCookbookDb.insert("Cookbooks", cookbook.toMap());
    return res;
  }

  Future<List<Cookbook>> getCookbooks() async {
    var dbTheCookbook = await db;
    List<Map> list = await dbTheCookbook.rawQuery('SELECT * FROM Cookbooks');
    List<Cookbook> cookbooks = new List();
    for (int i = 0; i < list.length; i++) {
      var cookbook = new Cookbook(list[i]["name"], list[i]["coverBase64Encoded"]);
      cookbook.setCookbookId(list[i]["cookbookId"]);
      cookbooks.add(cookbook);
    }
    print("Cookbooks: " + cookbooks.length.toString());
    return cookbooks;
  }

  Future<int> deleteCookbook(Cookbook cookbook) async {
    var theCookbookDb = await db;
    theCookbookDb.rawDelete('DELETE FROM Steps '
        'WHERE Steps.recipeId IN ('
          'SELECT Recipes.recipeId '
          'FROM Recipes '
          'INNER JOIN Cookbooks '
            'ON Cookbooks.cookbookId = Recipes.cookbookId '
          'WHERE Recipes.cookbookId = ?'
        ')', [cookbook.cookbookId]
    );
    theCookbookDb.rawDelete(
        'DELETE FROM Ingredients '
        'WHERE Ingredients.recipeId IN ( '
          'SELECT Recipes.recipeId FROM Recipes '
          'INNER JOIN Cookbooks '
            'ON Cookbooks.cookbookId = Recipes.cookbookId '
          'WHERE Recipes.cookbookId = ?'
        ')', [cookbook.cookbookId]
    );
    theCookbookDb.rawDelete('DELETE FROM Recipes WHERE cookbookId = ?', [cookbook.cookbookId]);
    int res = await theCookbookDb.rawDelete('DELETE FROM Cookbooks WHERE cookbookId = ?', [cookbook.cookbookId]);
    return res;
  }

  Future<bool> updateCookbook(Cookbook cookbook) async {
    var theCookbookDb = await db;
    int res =   await theCookbookDb.update("Cookbooks", cookbook.toMap(),
        where: "cookbookId = ?", whereArgs: <int>[cookbook.cookbookId]);
    return res > 0 ? true : false;
  }

  // Recipe CRUD

  Future<int> saveRecipe(Recipe recipe) async {
    var theCookbookDb = await db;
    int res = await theCookbookDb.insert("Recipes", recipe.toMap());
    return res;
  }

  Future<List<Recipe>> getRecipes(int cookbookId) async {
    var dbTheCookbook = await db;
    List<Map> list = await dbTheCookbook.rawQuery('SELECT * FROM Recipes WHERE cookbookId = ?', [cookbookId]);
    List<Recipe> recipes = new List();
    for (int i = 0; i < list.length; i++) {
      var recipe = new Recipe(
        list[i]["cookbookId"],
        list[i]["name"],
        list[i]["summary"],
        list[i]["coverBase64Encoded"],
        list[i]["level"],
        list[i]["durationInMinutes"],
        list[i]["isFavourite"]
      );
      recipe.setRecipeId(list[i]["recipeId"]);
      recipes.add(recipe);
    }
    print("Recipes: " + recipes.length.toString());
    return recipes;
  }

  Future<int> deleteRecipe(Recipe recipe) async {
    var theCookbookDb = await db;
    int res = await theCookbookDb.rawDelete('DELETE FROM Recipes WHERE recipeId = ?', [recipe.recipeId]);
    await theCookbookDb.rawDelete('DELETE FROM Steps WHERE recipeId = ?', [recipe.recipeId]);
    await theCookbookDb.rawDelete('DELETE FROM Ingredients WHERE recipeId = ?', [recipe.recipeId]);
    return res;
  }

  Future<bool> updateRecipe(Recipe recipe) async {
    var theCookbookDb = await db;
    int res =   await theCookbookDb.update("Recipes", recipe.toMap(),
        where: "recipeId = ?", whereArgs: <int>[recipe.recipeId]);
    return res > 0 ? true : false;
  }

  Future<List<Recipe>> getFavouriteRecipes() async {
    var dbTheCookbook = await db;
    List<Map> list = await dbTheCookbook.rawQuery('SELECT * FROM Recipes WHERE isFavourite = 1');
    List<Recipe> recipes = new List();
    for (int i = 0; i < list.length; i++) {
      var recipe = new Recipe(
          list[i]["cookbookId"],
          list[i]["name"],
          list[i]["summary"],
          list[i]["coverBase64Encoded"],
          list[i]["level"],
          list[i]["durationInMinutes"],
          list[i]["isFavourite"]
      );
      recipe.setRecipeId(list[i]["recipeId"]);
      recipes.add(recipe);
    }
    print("Recipes: " + recipes.length.toString());
    return recipes;
  }

  // Step CRUD

  Future<int> saveStep(Step step) async {
    var theCookbookDb = await db;
    int res = await theCookbookDb.insert("Steps", step.toMap());
    return res;
  }

  Future<List<Step>> getSteps(int cookbookId, int recipeId) async {
    var dbTheCookbook = await db;
    List<Map> list = await dbTheCookbook.rawQuery(
        'SELECT * FROM Steps '
        'INNER JOIN Recipes ON Steps.recipeId = Recipes.recipeId '
        'INNER JOIN Cookbooks ON Cookbooks.cookbookId = Recipes.cookbookId '
        'WHERE Recipes.recipeId = ? AND Cookbooks.cookbookId = ?',
        [recipeId, cookbookId]
    );
    List<Step> steps = new List();
    for (int i = 0; i < list.length; i++) {
      var step = new Step(
          list[i]["recipeId"],
          list[i]["title"],
          list[i]["description"],
          list[i]["photoBase64Encoded"]
      );
      step.setStepId(list[i]["stepId"]);
      steps.add(step);
    }
    print("Steps:" + steps.length.toString());
    return steps;
  }

  Future<int> deleteStep(Step step) async {
    var theCookbookDb = await db;
    int res = await theCookbookDb.rawDelete('DELETE FROM Steps WHERE stepId = ?', [step.stepId]);
    return res;
  }

  Future<bool> updateStep(Step step) async {
    var theCookbookDb = await db;
    int res =   await theCookbookDb.update("Steps", step.toMap(),
        where: "stepId = ?", whereArgs: <int>[step.stepId]);
    return res > 0 ? true : false;
  }

  // Step Ingredient

  Future<int> saveIngredient(Ingredient ingredient) async {
    var theCookbookDb = await db;
    int res = await theCookbookDb.insert("Ingredients", ingredient.toMap());
    return res;
  }

  Future<List<Ingredient>> getIngredients(int cookbookId, int recipeId) async {
    var dbTheCookbook = await db;
    List<Map> list = await dbTheCookbook.rawQuery(
        'SELECT * FROM Ingredients '
            'INNER JOIN Recipes ON Ingredients.recipeId = Recipes.recipeId '
            'INNER JOIN Cookbooks ON Cookbooks.cookbookId = Recipes.cookbookId '
            'WHERE Recipes.recipeId = ? AND Cookbooks.cookbookId = ?',
        [recipeId, cookbookId]
    );
    List<Ingredient> ingredients = new List();
    for (int i = 0; i < list.length; i++) {
      var ingredient = new Ingredient(
          list[i]["recipeId"],
          list[i]["description"]
      );
      ingredient.setIngredientId(list[i]["ingredientId"]);
      ingredients.add(ingredient);
    }
    print("Ingredients:" + ingredients.length.toString());
    return ingredients;
  }

  Future<int> deleteIngredient(Ingredient ingredient) async {
    var theCookbookDb = await db;
    int res = await theCookbookDb.rawDelete('DELETE FROM Ingredients WHERE ingredientId = ?', [ingredient.ingredientId]);
    return res;
  }

  Future<bool> updateIngredient(Ingredient ingredient) async {
    var theCookbookDb = await db;
    int res =   await theCookbookDb.update("Ingredients", ingredient.toMap(),
        where: "ingredientId = ?", whereArgs: <int>[ingredient.ingredientId]);
    return res > 0 ? true : false;
  }

  Future<int> deleteIngredientsForRecipe(int recipeId) async {
    var theCookbookDb = await db;
    int res = await theCookbookDb.rawDelete('DELETE FROM Ingredients WHERE recipeId = ?', [recipeId]);
    return res;
  }

  Future<int> deleteStepsForRecipe(int recipeId) async {
    var theCookbookDb = await db;
    int res = await theCookbookDb.rawUpdate('DELETE FROM Steps WHERE recipeId = ?', [recipeId]);
    return res;
  }

  backUpDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    path = join(documentsDirectory.path, "TheCookbook.db");

    File dbPath = File(path);
    Directory externalStorageDirectory = await getExternalStorageDirectory();

    new Directory("${externalStorageDirectory.path}/The_Cookbook_DB_Backup").create(recursive: true)
    // The created directory is returned as a Future.
        .then((Directory directory) {

      dbPath.copy(join(directory.path,"/The_Cookbook_DB_Backup/TheCookbook.db"));

    });


  }

}