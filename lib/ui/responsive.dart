import 'package:flutter/material.dart';

/// Responsive design utilities for the Pitch game
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= ResponsiveBreakpoints.tablet) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= ResponsiveBreakpoints.mobile) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

extension ResponsiveHelper on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < ResponsiveBreakpoints.mobile;
  bool get isTablet => MediaQuery.of(this).size.width >= ResponsiveBreakpoints.mobile && 
                      MediaQuery.of(this).size.width < ResponsiveBreakpoints.tablet;
  bool get isDesktop => MediaQuery.of(this).size.width >= ResponsiveBreakpoints.tablet;
  
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}