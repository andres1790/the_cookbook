import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_cookbook/models/recipe.dart';
import 'package:the_cookbook/models/step.dart' as RecipeStep;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:the_cookbook/utils/separator.dart';

// ignore: must_be_immutable
class RecipeStepsPage extends StatelessWidget {

  Recipe recipe;

  RecipeStepsPage({this.recipe});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
          backgroundColor: Colors.blue,
          body: _renderBody(context)
      ), onWillPop: () {
      Navigator.pop(context);
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    },
    );
  }

  Widget _renderBody(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: <Widget>[
          _renderCarousel(context),
          _renderBackButton(context),
        ],
      ),
    );
  }

  Widget _renderCarousel(BuildContext context) {
    return CarouselSlider(
      height: MediaQuery.of(context).size.height,
      aspectRatio: 16/9,
      enlargeCenterPage: true,
      items: recipe.steps.map((i) {
        return Builder(
          builder: (BuildContext context) {
            return _renderStepSlide(context, i);
          },
        );
      }).toList(),
    );
  }

  Widget _renderBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
            SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
          },
        ),
      ),
    );
  }

  Widget _renderStepSlide(BuildContext context, RecipeStep.Step step) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(horizontal: 3.0),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                _renderStepTitle(step),
                new Separator(width: 64.0, heigth: 1.0, color: Colors.cyan),
                _renderStepPhoto(context, step),
                new Separator(width: 64.0, heigth: 1.0, color: Colors.cyan),
                _renderStepDescription(step)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderStepTitle(RecipeStep.Step step){
    return Text(
      step.title,
      style: TextStyle(
        color: Colors.black,
        fontSize: 24.0,
        fontFamily: 'Muli',
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _renderStepPhoto(BuildContext context, RecipeStep.Step step){
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 248,
      child: Image.network(
        step.photo,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _renderStepDescription(RecipeStep.Step step){
    return Text(
        step.description,
        style: TextStyle(
            fontSize: 18.0,
            fontFamily: 'Muli'
        )
    );
  }

}