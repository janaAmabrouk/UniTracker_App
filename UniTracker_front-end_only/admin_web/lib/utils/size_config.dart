import 'package:flutter/material.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double defaultSize;
  static late Orientation orientation;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;

    // Initialize default size based on screen width
    defaultSize = orientation == Orientation.landscape
        ? screenHeight * 0.024
        : screenWidth * 0.024;
  }
}

double getProportionateScreenWidth(double inputWidth) {
  return (inputWidth / 375.0) * SizeConfig.screenWidth;
}

double getProportionateScreenHeight(double inputHeight) {
  return (inputHeight / 812.0) * SizeConfig.screenHeight;
}
