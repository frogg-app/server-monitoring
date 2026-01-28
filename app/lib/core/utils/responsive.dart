import 'package:flutter/material.dart';

/// Responsive breakpoints for the app
class Breakpoints {
  Breakpoints._();

  /// Mobile breakpoint (phones)
  static const double mobile = 600;

  /// Tablet breakpoint
  static const double tablet = 900;

  /// Desktop breakpoint
  static const double desktop = 1200;
}

/// Extension on BuildContext for responsive checks
extension ResponsiveContext on BuildContext {
  /// Get the current screen width
  double get width => MediaQuery.of(this).size.width;

  /// Get the current screen height
  double get height => MediaQuery.of(this).size.height;

  /// Check if the current screen is mobile (< 600dp)
  bool get isMobile => width < Breakpoints.mobile;

  /// Check if the current screen is tablet (600-900dp)
  bool get isTablet => width >= Breakpoints.mobile && width < Breakpoints.tablet;

  /// Check if the current screen is desktop (>= 900dp)
  bool get isDesktop => width >= Breakpoints.tablet;

  /// Check if the current screen is large desktop (>= 1200dp)
  bool get isLargeDesktop => width >= Breakpoints.desktop;

  /// Get responsive padding based on screen size
  EdgeInsets get responsivePadding {
    if (isMobile) {
      return const EdgeInsets.all(16);
    } else if (isTablet) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding {
    if (isMobile) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  /// Get responsive card border radius
  double get responsiveCardRadius {
    return isMobile ? 12 : 16;
  }

  /// Get number of grid columns based on screen size
  int getGridColumns({int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isMobile) return mobile;
    if (isTablet) return tablet;
    return desktop;
  }
}

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop && desktop != null) {
      return desktop!(context);
    } else if (context.isTablet && tablet != null) {
      return tablet!(context);
    } else {
      return mobile(context);
    }
  }
}
