import 'package:flutter/foundation.dart';

import '../../resource/theme/dimens.dart';
import '../../utils/app_responsive.dart';

@immutable
class DashboardLayoutTokens {
  const DashboardLayoutTokens._({
    required this.pagePadding,
    required this.sectionGap,
    required this.sectionGapLarge,
    required this.statsGridSpacing,
    required this.statsCardAspectDesktop,
    required this.statsCardAspectDefault,
    required this.statsCardRadius,
    required this.statsCardShadowBlur,
    required this.statsCardShadowOffsetY,
    required this.statsIconBoxSize,
    required this.statsIconRadius,
    required this.statsLabelGap,
    required this.statsValueGap,
    required this.cashflowChartHeight,
    required this.quickActionRadius,
    required this.quickActionHorizontalPadding,
    required this.quickActionVerticalPadding,
    required this.quickActionIconSize,
    required this.quickActionIconGap,
    required this.dashboardCardPadding,
    required this.dashboardCardRadius,
    required this.dashboardCardShadowBlur,
    required this.dashboardCardShadowOffsetY,
    required this.tableCellVerticalPadding,
    required this.rowBottomSpacing,
    required this.smallGap,
    required this.statusChipHorizontalPadding,
    required this.statusChipVerticalPadding,
    required this.statusChipRadius,
  });

  factory DashboardLayoutTokens.fromResponsive(AppResponsive responsive) {
    if (responsive.isDesktop) {
      return const DashboardLayoutTokens._(
        pagePadding: defaultPadding * 1.1,
        sectionGap: defaultPadding,
        sectionGapLarge: defaultPadding * 1.5,
        statsGridSpacing: defaultPadding,
        statsCardAspectDesktop: 2.6,
        statsCardAspectDefault: 2.2,
        statsCardRadius: 16,
        statsCardShadowBlur: 18,
        statsCardShadowOffsetY: 8,
        statsIconBoxSize: 44,
        statsIconRadius: 12,
        statsLabelGap: 6,
        statsValueGap: 4,
        cashflowChartHeight: 170,
        quickActionRadius: 24,
        quickActionHorizontalPadding: 18,
        quickActionVerticalPadding: 10,
        quickActionIconSize: 18,
        quickActionIconGap: 8,
        dashboardCardPadding: defaultPadding,
        dashboardCardRadius: 16,
        dashboardCardShadowBlur: 12,
        dashboardCardShadowOffsetY: 6,
        tableCellVerticalPadding: 10,
        rowBottomSpacing: 12,
        smallGap: 6,
        statusChipHorizontalPadding: 10,
        statusChipVerticalPadding: 4,
        statusChipRadius: 20,
      );
    }

    if (responsive.isTablet) {
      return const DashboardLayoutTokens._(
        pagePadding: defaultPadding,
        sectionGap: defaultPadding,
        sectionGapLarge: defaultPadding * 1.5,
        statsGridSpacing: defaultPadding,
        statsCardAspectDesktop: 2.4,
        statsCardAspectDefault: 2.1,
        statsCardRadius: 15,
        statsCardShadowBlur: 16,
        statsCardShadowOffsetY: 7,
        statsIconBoxSize: 42,
        statsIconRadius: 11,
        statsLabelGap: 6,
        statsValueGap: 4,
        cashflowChartHeight: 160,
        quickActionRadius: 24,
        quickActionHorizontalPadding: 18,
        quickActionVerticalPadding: 10,
        quickActionIconSize: 18,
        quickActionIconGap: 8,
        dashboardCardPadding: defaultPadding,
        dashboardCardRadius: 16,
        dashboardCardShadowBlur: 12,
        dashboardCardShadowOffsetY: 6,
        tableCellVerticalPadding: 10,
        rowBottomSpacing: 12,
        smallGap: 6,
        statusChipHorizontalPadding: 10,
        statusChipVerticalPadding: 4,
        statusChipRadius: 20,
      );
    }

    return const DashboardLayoutTokens._(
      pagePadding: defaultPadding * 0.9,
      sectionGap: defaultPadding * 0.85,
      sectionGapLarge: defaultPadding * 1.2,
      statsGridSpacing: defaultPadding * 0.85,
      statsCardAspectDesktop: 2.3,
      statsCardAspectDefault: 1.95,
      statsCardRadius: 14,
      statsCardShadowBlur: 14,
      statsCardShadowOffsetY: 6,
      statsIconBoxSize: 40,
      statsIconRadius: 10,
      statsLabelGap: 5,
      statsValueGap: 4,
      cashflowChartHeight: 148,
      quickActionRadius: 22,
      quickActionHorizontalPadding: 16,
      quickActionVerticalPadding: 9,
      quickActionIconSize: 17,
      quickActionIconGap: 7,
      dashboardCardPadding: defaultPadding * 0.9,
      dashboardCardRadius: 14,
      dashboardCardShadowBlur: 10,
      dashboardCardShadowOffsetY: 5,
      tableCellVerticalPadding: 8,
      rowBottomSpacing: 10,
      smallGap: 5,
      statusChipHorizontalPadding: 9,
      statusChipVerticalPadding: 4,
      statusChipRadius: 18,
    );
  }

  final double pagePadding;
  final double sectionGap;
  final double sectionGapLarge;
  final double statsGridSpacing;
  final double statsCardAspectDesktop;
  final double statsCardAspectDefault;
  final double statsCardRadius;
  final double statsCardShadowBlur;
  final double statsCardShadowOffsetY;
  final double statsIconBoxSize;
  final double statsIconRadius;
  final double statsLabelGap;
  final double statsValueGap;
  final double cashflowChartHeight;
  final double quickActionRadius;
  final double quickActionHorizontalPadding;
  final double quickActionVerticalPadding;
  final double quickActionIconSize;
  final double quickActionIconGap;
  final double dashboardCardPadding;
  final double dashboardCardRadius;
  final double dashboardCardShadowBlur;
  final double dashboardCardShadowOffsetY;
  final double tableCellVerticalPadding;
  final double rowBottomSpacing;
  final double smallGap;
  final double statusChipHorizontalPadding;
  final double statusChipVerticalPadding;
  final double statusChipRadius;

  int statsCrossAxisCount({
    required double width,
    required AppResponsive responsive,
  }) {
    if (width < 650) {
      return 1;
    }
    if (responsive.isMobile) {
      return 2;
    }
    return 4;
  }

  double statsAspectRatio(AppResponsive responsive) {
    return responsive.isDesktop
        ? statsCardAspectDesktop
        : statsCardAspectDefault;
  }
}
