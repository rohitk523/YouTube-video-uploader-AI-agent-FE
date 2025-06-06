import 'package:flutter/material.dart';

class UIConstants {
  // Screen Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;
  
  // Spacing
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0);
  
  // Sizes
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  
  // Icons
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;
  
  // Text Sizes
  static const double caption = 12.0;
  static const double body2 = 14.0;
  static const double body1 = 16.0;
  static const double subtitle2 = 16.0;
  static const double subtitle1 = 18.0;
  static const double headline6 = 20.0;
  static const double headline5 = 24.0;
  static const double headline4 = 28.0;
  static const double headline3 = 32.0;
  static const double headline2 = 36.0;
  static const double headline1 = 40.0;
  
  // Radius
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(16.0));
  
  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 4.0,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 10.0,
      offset: Offset(0, 4),
    ),
  ];
  
  // Grid
  static const int mobileGridCrossAxisCount = 1;
  static const int tabletGridCrossAxisCount = 2;
  static const int desktopGridCrossAxisCount = 3;
  
  // Upload Area
  static const double uploadAreaHeight = 200.0;
  static const double uploadAreaMinHeight = 150.0;
  
  // Progress Indicators
  static const double progressIndicatorSize = 120.0;
  static const double progressLineWidth = 8.0;
  
  // Video Player
  static const double videoPlayerAspectRatio = 16 / 9;
  static const double shortsAspectRatio = 9 / 16;
  
  // Bottom Sheet
  static const double bottomSheetBorderRadius = 16.0;
  static const double bottomSheetMaxHeight = 0.9;
} 