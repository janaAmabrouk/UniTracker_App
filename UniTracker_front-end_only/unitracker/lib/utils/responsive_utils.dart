import 'package:flutter/material.dart';

class ResponsiveScreen extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const ResponsiveScreen({
    Key? key,
    required this.child,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure SizeConfig is initialized with current context
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SizeConfig {
  static MediaQueryData? _mediaQueryData;
  static double screenWidth = 0;
  static double screenHeight = 0;
  static double defaultSize = 0;
  static Orientation? orientation;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData?.size.width ?? 0;
    screenHeight = _mediaQueryData?.size.height ?? 0;
    orientation = _mediaQueryData?.orientation;
    defaultSize = orientation == Orientation.landscape
        ? screenHeight * 0.024
        : screenWidth * 0.024;
  }
}

double getProportionateScreenHeight(double inputHeight) {
  if (SizeConfig.screenHeight == 0) return inputHeight;
  return (inputHeight / 812.0) * SizeConfig.screenHeight;
}

double getProportionateScreenWidth(double inputWidth) {
  if (SizeConfig.screenWidth == 0) return inputWidth;
  return (inputWidth / 375.0) * SizeConfig.screenWidth;
}
