import 'package:flutter/widgets.dart';

/// Global responsive helper to reuse adaptive values across screens.
@immutable
class AppResponsive {
  const AppResponsive._(this.width);

  static const double mobileBreakpoint = 850;
  static const double desktopBreakpoint = 1100;

  final double width;

  static AppResponsive of(BuildContext context) {
    return AppResponsive._(MediaQuery.sizeOf(context).width);
  }

  bool get isMobile => width < mobileBreakpoint;
  bool get isTablet => width >= mobileBreakpoint && width < desktopBreakpoint;
  bool get isDesktop => width >= desktopBreakpoint;

  T pick<T>({
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop) {
      return desktop;
    }
    if (isTablet) {
      return tablet ?? desktop;
    }
    return mobile;
  }

  double size({
    required double mobile,
    double? tablet,
    required double desktop,
  }) {
    return pick(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
