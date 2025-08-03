import 'package:flutter/material.dart';

// Bootstrap-like breakpoints
class Breakpoints {
  static const double xs = 0;
  static const double sm = 576;
  static const double md = 768;
  static const double lg = 992;
  static const double xl = 1200;
  static const double xxl = 1400;
}

// Bootstrap-like responsive utilities
class ResponsiveUtils {
  static bool isXs(BuildContext context) => MediaQuery.of(context).size.width < Breakpoints.sm;
  static bool isSm(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.sm && MediaQuery.of(context).size.width < Breakpoints.md;
  static bool isMd(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.md && MediaQuery.of(context).size.width < Breakpoints.lg;
  static bool isLg(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.lg && MediaQuery.of(context).size.width < Breakpoints.xl;
  static bool isXl(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.xl && MediaQuery.of(context).size.width < Breakpoints.xxl;
  static bool isXxl(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.xxl;
  
  static bool isSmUp(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.sm;
  static bool isMdUp(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.md;
  static bool isLgUp(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.lg;
  static bool isXlUp(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.xl;
  static bool isXxlUp(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.xxl;
  
  // Mobile helper methods
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < Breakpoints.md;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.md && MediaQuery.of(context).size.width < Breakpoints.lg;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= Breakpoints.lg;
}

// Bootstrap-like container
class BootstrapContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool fluid;
  
  const BootstrapContainer({
    super.key,
    required this.child,
    this.padding,
    this.fluid = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    double maxWidth;
    if (fluid) {
      maxWidth = double.infinity;
    } else if (screenWidth >= Breakpoints.xxl) {
      maxWidth = 1320;
    } else if (screenWidth >= Breakpoints.xl) {
      maxWidth = 1140;
    } else if (screenWidth >= Breakpoints.lg) {
      maxWidth = 960;
    } else if (screenWidth >= Breakpoints.md) {
      maxWidth = 720;
    } else if (screenWidth >= Breakpoints.sm) {
      maxWidth = 540;
    } else {
      maxWidth = double.infinity;
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: padding,
      child: child,
    );
  }
}

// Bootstrap-like row
class BootstrapRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  
  const BootstrapRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveUtils.isXs(context)) {
          return Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          );
        }
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        );
      },
    );
  }
}

// Bootstrap-like column with responsive sizing
class BootstrapCol extends StatelessWidget {
  final Widget child;
  final int? xs, sm, md, lg, xl, xxl;
  final EdgeInsetsGeometry? padding;
  
  const BootstrapCol({
    super.key,
    required this.child,
    this.xs,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    int columns = 12;
    
    if (ResponsiveUtils.isXxl(context) && xxl != null) {
      columns = xxl!;
    } else if (ResponsiveUtils.isXl(context) && xl != null) {
      columns = xl!;
    } else if (ResponsiveUtils.isLg(context) && lg != null) {
      columns = lg!;
    } else if (ResponsiveUtils.isMd(context) && md != null) {
      columns = md!;
    } else if (ResponsiveUtils.isSm(context) && sm != null) {
      columns = sm!;
    } else if (xs != null) {
      columns = xs!;
    }

    return Expanded(
      flex: columns,
      child: Container(
        padding: padding ?? const EdgeInsets.all(15),
        child: child,
      ),
    );
  }
}

// Responsive spacing utility
class ResponsiveSpacing {
  static double getSpacing(BuildContext context, {
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    if (ResponsiveUtils.isXxl(context) && xxl != null) return xxl;
    if (ResponsiveUtils.isXl(context) && xl != null) return xl;
    if (ResponsiveUtils.isLg(context) && lg != null) return lg;
    if (ResponsiveUtils.isMd(context) && md != null) return md;
    if (ResponsiveUtils.isSm(context) && sm != null) return sm;
    return xs ?? 16;
  }
  
  static EdgeInsetsGeometry getPadding(BuildContext context, {
    EdgeInsetsGeometry? xs,
    EdgeInsetsGeometry? sm,
    EdgeInsetsGeometry? md,
    EdgeInsetsGeometry? lg,
    EdgeInsetsGeometry? xl,
    EdgeInsetsGeometry? xxl,
  }) {
    if (ResponsiveUtils.isXxl(context) && xxl != null) return xxl;
    if (ResponsiveUtils.isXl(context) && xl != null) return xl;
    if (ResponsiveUtils.isLg(context) && lg != null) return lg;
    if (ResponsiveUtils.isMd(context) && md != null) return md;
    if (ResponsiveUtils.isSm(context) && sm != null) return sm;
    return xs ?? const EdgeInsets.all(16);
  }
}

// Responsive text utility
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final double? xs, sm, md, lg, xl, xxl;
  final TextAlign? textAlign;
  
  const ResponsiveText(
    this.text, {
    super.key,
    this.baseStyle,
    this.xs,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    double fontSize = 16;
    
    if (ResponsiveUtils.isXxl(context) && xxl != null) {
      fontSize = xxl!;
    } else if (ResponsiveUtils.isXl(context) && xl != null) {
      fontSize = xl!;
    } else if (ResponsiveUtils.isLg(context) && lg != null) {
      fontSize = lg!;
    } else if (ResponsiveUtils.isMd(context) && md != null) {
      fontSize = md!;
    } else if (ResponsiveUtils.isSm(context) && sm != null) {
      fontSize = sm!;
    } else if (xs != null) {
      fontSize = xs!;
    }

    return Text(
      text,
      style: (baseStyle ?? const TextStyle()).copyWith(fontSize: fontSize),
      textAlign: textAlign,
    );
  }
}
