import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:the_cookbook/database/database_helper.dart';
import 'package:the_cookbook/localization/app_translations.dart';
import 'package:the_cookbook/models/Ingredient.dart';
import 'package:the_cookbook/models/recipe.dart';
import 'package:the_cookbook/models/step.dart' as RecipeStep;
import 'package:the_cookbook/pages/cookbook/recipe/create_recipe_cover_page.dart';
import 'package:the_cookbook/pages/cookbook/recipe/step/create_recipe_steps_page.dart';
import 'package:the_cookbook/storage/create_recipe_storage.dart';

// ignore: must_be_immutable
class CreateRecipe extends StatefulWidget {

  int cookbookId;
  Function getRecipes;
  Recipe recipe;
  bool isNewRecipe = false;

  CreateRecipe(this.cookbookId, this.getRecipes, {this.recipe});

  @override
  State<StatefulWidget> createState() {
    return _CreateRecipeState();
  }

}

class _CreateRecipeState extends State<CreateRecipe>{

  int _currentIndex = 0;
  CreateRecipeCover coverPage;
  CreateRecipeSteps stepsPage;
  List<Widget> _children;

  final PageStorageBucket bucket = PageStorageBucket();

  final PageStorageKey mykey = new PageStorageKey("CreateRecipePageKey");

  @override
  void initState() {

    if(widget.recipe == null){
      widget.isNewRecipe = true;
    }

    CreateRecipeStorage.initialize();

    coverPage = CreateRecipeCover(this.callback ,key: PageStorageKey('CoverPage'), bucket: bucket, recipe: widget.recipe, isNewRecipe: widget.isNewRecipe);
    stepsPage = CreateRecipeSteps(key: PageStorageKey('StepsPage'), bucket: bucket, recipe: widget.recipe);

    _children = [coverPage,stepsPage];

    super.initState();
  }

  void callback() {
    setState(() {});
  }

  @override
  void dispose() {
    CreateRecipeStorage.getSteps().clear();
    CreateRecipeStorage.getStepImages().clear();
    CreateRecipeStorage.getIngredients().clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        _showCancelDialog(context);
      },
      child: Scaffold(
        floatingActionButton: bucket.readState(context,identifier: "recipeName") != null &&
            !(bucket.readState(context,identifier: "recipeName").toString().trim().isEmpty) ?
        FloatingActionButton(
          onPressed: () {
              if(_validateFields()){
                _saveRecipe();
              }else{
                print("Complete all required fields");
              }
            },
          child: Icon(Icons.save)
        ) :
        null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        body: Stack(
          children: <Widget>[
            PageStorage(
              child: _children[_currentIndex],
              bucket: bucket,
              key: mykey,
            ),
            _renderBackButton(context),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 10.0
              )
            ]
          ),
          child: BottomNavigationBar(
            onTap: onTabTapped,
            currentIndex: _currentIndex,
            items: [
              BottomNavigationBarItem(
                icon: new Icon(Icons.restaurant),
                title: new Text(AppTranslations.of(context).text("key_recipe_cover_tab_text")),
              ),
              BottomNavigationBarItem(
                icon: new Icon(Icons.format_list_numbered),
                title: new Text(AppTranslations.of(context).text("key_recipe_steps_tab_text")),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  bool _validateFields() {
    if(bucket.readState(context,identifier: "recipeName").toString().trim().isEmpty || bucket.readState(context,identifier: "recipeName") == null) {
      return false;
    }else{
      return true;
    }
  }

  void _saveRecipe() async {
    var db = new DatabaseHelper();

    //UPDATE
    if(widget.recipe != null){
      await db.updateRecipe(widget.recipe).then((recipeId){
        _saveIngredients(db, CreateRecipeStorage.getIngredients(), widget.recipe.recipeId);
        _saveSteps(db, CreateRecipeStorage.getSteps(), CreateRecipeStorage.getStepImages(), widget.recipe.recipeId);
      });
    }
    //INSERT
    else{

      //Prepare Recipe
      var recipe = new Recipe(
        widget.cookbookId,
        bucket.readState(context,identifier: "recipeName").toString().trim(),
        bucket.readState(context,identifier: "recipeSummary").toString().trim().isEmpty ? "" : bucket.readState(context,identifier: "recipeSummary").toString().trim(),
        _encodeBgPhoto(),
        bucket.readState(context,identifier: "selectedDifficulty").toString().trim(),
        int.parse(
            bucket.readState(context,identifier: "selectedMinutes") != null ?
            bucket.readState(context,identifier: "selectedMinutes").toString().trim() :
            "987654321"
        ),
        0
      );
      // Save Recipe and when it finished, save Steps
      await db.saveRecipe(recipe).then((recipeId){
        _saveIngredients(db, CreateRecipeStorage.getIngredients(), recipeId);
        _saveSteps(db, CreateRecipeStorage.getSteps(), CreateRecipeStorage.getStepImages() , recipeId);
      });

    }

  }

  void _saveSteps(DatabaseHelper db, List<RecipeStep.Step> steps, Map<int,File> stepImages, int recipeId) async {

    // IN CASE OF UPDATE
    if(widget.recipe != null){
      db.deleteStepsForRecipe(recipeId);
    }
    String base64Image;

    for(int i = 0; i < steps.length; i++){

      base64Image = "DEFAULT";

      if(stepImages[i] != null){
        List<int> imageBytes = stepImages[i].readAsBytesSync();
        base64Image = base64Encode(imageBytes);
      }

      steps[i].photoBase64Encoded = base64Image;
      steps[i].recipeId = recipeId;
      db.saveStep(steps[i]);
    }


    widget.getRecipes();
    Navigator.pop(context);
  }

  String _encodeBgPhoto() {
    String base64Image = "DEFAULT";
    var _image = bucket.readState(context,identifier: "bgPhoto");
    if(_image != null){
      base64Image = _image;//base64Encode(imageBytes);
    }
    return base64Image;
  }

  void _saveIngredients(DatabaseHelper db, ingredients, int recipeId) {

    // IN CASE OF UPDATE
    if(widget.recipe != null){
      db.deleteIngredientsForRecipe(widget.recipe.recipeId);
    }

    for(TextFieldAndController ingredient in ingredients){
      Ingredient ing = new Ingredient(recipeId, ingredient.textField.controller.text);
      db.saveIngredient(ing);
    }

  }

  _renderBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, left: 8.0),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios,color: Colors.white),
          onPressed: () {
            _showCancelDialog(context);
          },
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(widget.isNewRecipe ? AppTranslations.of(context).text("key_recipe_cancel_creation_dialog_title") : AppTranslations.of(context).text("key_recipe_cancel_update_dialog_title")),
          content: new Text(widget.isNewRecipe ? AppTranslations.of(context).text("key_recipe_cancel_creation_dialog_text") : AppTranslations.of(context).text("key_recipe_cancel_update_dialog_text")),
          actions: <Widget>[
            new FlatButton(
              child: new Text(AppTranslations.of(context).text("key_dialog_delete_accept")),
              onPressed: () {
                Navigator.pop(context);
                _closePage();
              },
            ),
            new FlatButton(
              child: new Text(AppTranslations.of(context).text("key_dialog_delete_cancel")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _closePage() {
    Navigator.pop(context);
  }

}