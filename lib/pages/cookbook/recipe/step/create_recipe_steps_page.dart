import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_cookbook/localization/app_translations.dart';
import 'package:the_cookbook/models/recipe.dart';
import 'package:the_cookbook/pages/cookbook/recipe/step/step_presenter.dart';
import 'package:the_cookbook/utils/image_picker_and_cropper.dart';
import 'package:the_cookbook/utils/separator.dart';
import 'package:the_cookbook/models/step.dart' as RecipeStep;
import 'package:the_cookbook/storage/create_recipe_storage.dart';

// ignore: must_be_immutable
class CreateRecipeSteps extends StatefulWidget{

  PageStorageBucket bucket;
  Recipe recipe;

  CreateRecipeSteps({Key key, this.bucket, this.recipe}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CreateRecipeStepsState();
  }

}

class _CreateRecipeStepsState extends State<CreateRecipeSteps>  implements StepContract{

  StepPresenter stepPresenter;

  var _currentPage = 0;

  PageController _pageController;

  int itemIndexSelected;

  ImagePickerAndCropper imagePickerAndCropper;

  void initState() {

    _currentPage = 0;

    _pageController = PageController(viewportFraction: 0.9);

    if(widget.recipe != null){
      _setRecipeDetails();
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void callback(int option){
    if(option != null && option == 1){
      imagePickerAndCropper.getImageFromCamera().then((file)=>{
      updatePage(file)
      });
    }else if(option != null && option == 2){
      imagePickerAndCropper.getImageFromGallery().then((file)=>{
      updatePage(file)
      });
    }
  }

  void updatePage(File croppedFile){
    setState(() {
      CreateRecipeStorage.setStepImage(itemIndexSelected,croppedFile);
      List<int> imageBytes = croppedFile.readAsBytesSync();
      CreateRecipeStorage.getSteps()[itemIndexSelected].photoBase64Encoded = base64Encode(imageBytes);
      print("Cropped file: " + croppedFile.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: <Widget>[
            _renderBody(),
          ],
        )
      );
  }

  Widget _renderBody(){
    return Container(
        key: PageStorageKey('scrollStepsPosition'),
        decoration: new BoxDecoration(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16.0), bottomRight: Radius.circular(16.0)),
            gradient: new LinearGradient(
                colors: [Color.fromRGBO(179,229,252, 1), Colors.blueAccent],
                begin: const FractionalOffset(0.0, 0.0),
                end: const FractionalOffset(0.5, 0.0),
                stops: [0.0, 1.0],
                tileMode: TileMode.clamp
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black,
                  blurRadius: 10.0
              )
            ]
        ),
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: <Widget>[
            _renderCarousel(context),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                CreateRecipeStorage.getSteps().length > 0 ?
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FloatingActionButton(
                        child: Icon(Icons.add),
                        backgroundColor: Colors.pinkAccent,
                        onPressed: () {_createNewStep();},
                        shape: new RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(96.0), bottomLeft: Radius.circular(96.0)),
                        ),
                      ),
                  ],
                ) :
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FloatingActionButton(
                        child: Icon(Icons.add),
                        backgroundColor: Colors.pinkAccent,
                        onPressed: () {_createNewStep();},
                      ),
                    )
                  ],
                ),
              ],
            )
          ],
        )
    );
  }

  Widget _renderCarousel(BuildContext context) {
    return PageView.builder(
      // store this controller in a State to save the carousel scroll position
      controller: _pageController,
      itemCount: CreateRecipeStorage.getSteps().length,
      itemBuilder: (BuildContext context, int itemIndex) {
        return _buildCarouselItem(context, _currentPage, itemIndex);
      },
    );
  }

  Widget _buildCarouselItem(BuildContext context, int carouselIndex, int itemIndex) {
    return Container(
      child: _renderStepSlide(context, CreateRecipeStorage.getStep(itemIndex), itemIndex),
    );
  }

  Widget _renderStepSlide(BuildContext context, RecipeStep.Step step, int itemIndex) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0, bottom: 16.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.5),
              offset: Offset(0.0, 3.0),
              blurRadius: 2.0,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Stack(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                    height: 72,
                    width: 72,
                    child: Material(
                      type: MaterialType.transparency,
                      child: IconButton(
                        color: Colors.black54,
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteSlide(context, step, itemIndex);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    _renderStepTitle(step),
                    new Separator(width: 64.0, heigth: 1.0, color: Colors.cyan),
                    _renderStepPhoto(context, itemIndex),
                    //new Separator(width: 64.0, heigth: 1.0, color: Colors.cyan),
                    _renderStepDescription(step, itemIndex)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderStepTitle(RecipeStep.Step step){
    return Text(
      "${AppTranslations.of(context).text("key_recipe_step")} ${step.title}",
      style: TextStyle(
        color: Colors.black,
        fontSize: 24.0,
        fontFamily: 'Muli',
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _renderStepPhoto(BuildContext context, int itemIndex){
    return Container(
      height: 248,
      child: Stack(
        children: <Widget>[
          _renderBackgroundImage(itemIndex),
          _renderBackgroundOpacity(),
          _renderCameraButton(itemIndex)
        ],
      ),
    );
  }

  Widget _renderCameraButton(int itemIndex){
    return Center(
      child: Material(
        type: MaterialType.transparency,
        color: Colors.transparent,
        child: IconButton(
          icon: Icon(Icons.camera_alt),
          color: Colors.white,
          iconSize: 64.0,
          tooltip: AppTranslations.of(context).text("key_tooltip_pick_image"),
          onPressed: () {
            this.itemIndexSelected = itemIndex;
            imagePickerAndCropper = new ImagePickerAndCropper();
            imagePickerAndCropper.showDialog(context, callback);
            //getImage(itemIndex);
          },
        ),
      ),
    );
  }

  Widget _renderBackgroundImage(int itemIndex) {
    RecipeStep.Step step = CreateRecipeStorage.getSteps()[itemIndex];
    return Container(
        width: MediaQuery.of(context).size.width,
        height: 248,
        child: step.photoBase64Encoded == null || step.photoBase64Encoded.trim().isEmpty ?
        Image.asset(
          "assets/images/food_pattern.png",
          fit: BoxFit.cover,
        ) :
        _itemThumnail(step)
    );
  }

  Widget _itemThumnail(RecipeStep.Step step) {
    var thumb;
    if(step.photoBase64Encoded == "DEFAULT"){
      thumb = SizedBox.expand(
          child: Image.asset(
            "assets/images/food_pattern.png",
            fit: BoxFit.cover,
          )
      );
    }else{
      Uint8List _bytesImage;
      _bytesImage = Base64Decoder().convert(step.photoBase64Encoded);
      thumb = SizedBox.expand(
          child: Image.memory(
            _bytesImage,
            fit: BoxFit.cover,
          )
      );
    }
    return thumb;
  }

  Widget _renderBackgroundOpacity() {
    return Container(
      color: Color.fromRGBO(0, 0, 0, 0.5),
    );
  }

  Widget _renderStepDescription(RecipeStep.Step step, int itemIndex){
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            AppTranslations.of(context).text("key_step_description"),
            style: TextStyle(
              color: Colors.black,
              fontSize: 24.0,
              fontFamily: 'Muli',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        new Separator(width: 64.0, heigth: 1.0, color: Colors.cyan),
        TextField(
          controller: TextEditingController(text: CreateRecipeStorage.getStep(itemIndex).description),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: AppTranslations.of(context).text("key_step_description_hint")
          ),
          onChanged: (value){
            CreateRecipeStorage.getStep(itemIndex).description = value;
          },
        ),
      ],
    );
  }

  void _createNewStep() {

    var nextStep = CreateRecipeStorage.getSteps().length + 1;

    RecipeStep.Step newStep = new RecipeStep.Step(0, "$nextStep", "", "DEFAULT");

    CreateRecipeStorage.setStep(newStep);

    setState(() {
      _pageController.animateToPage(
          nextStep,
          duration: Duration(milliseconds: 500),
          curve: Curves.linear);
    });

  }

  void _setRecipeDetails() {
    stepPresenter = new StepPresenter(this);
    stepPresenter.getSteps(widget.recipe.cookbookId, widget.recipe.recipeId).then((stepsList){
      widget.recipe.steps = stepsList;
      for(int i = 0; i<stepsList.length; i++){
        CreateRecipeStorage.setStep(stepsList[i]);
        if(stepsList[i].photoBase64Encoded == "DEFAULT"){
          CreateRecipeStorage.setStepImage(i, null);
        }else{
          Uint8List _bytesImage;
          _bytesImage = Base64Decoder().convert(stepsList[i].photoBase64Encoded);
          CreateRecipeStorage.setStepImage(i, File.fromRawPath(_bytesImage));
        }

      }
      setState(() {});
    });
  }

  @override
  void screenUpdate() {
    setState(() {});
  }

  void _deleteSlide(BuildContext context, RecipeStep.Step step, int itemIndex) {

    //ITEMS REMOVAL
    CreateRecipeStorage.getSteps().removeAt(itemIndex);
    CreateRecipeStorage.getStepImages().remove(itemIndex);

    //STEPS LIST UPDATE
    List<RecipeStep.Step> steps = CreateRecipeStorage.getSteps();
    if(steps.length>0){
      for(int i = 0; i<steps.length;i++){
        CreateRecipeStorage.getSteps()[i].title = "${i+1}";
      }
    }

    //STEPS IMAGES UPDATE
    Map<int,File> stepImages = CreateRecipeStorage.getStepImages();
    Map<int,File> newStepImages = new Map<int,File>();
    int i = 0;
    if(stepImages.length>0){
      stepImages.forEach((key,value){
        newStepImages[i]=value;
        i++;
      });
    }

    CreateRecipeStorage.setStepImages(newStepImages);

    setState(() {});
  }

}

