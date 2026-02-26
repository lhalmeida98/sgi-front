import 'package:flutter/foundation.dart';

import '../../../utils/app_responsive.dart';

@immutable
class SideMenuLayoutTokens {
  const SideMenuLayoutTokens._({
    required this.headerHeightExpanded,
    required this.headerHeightCollapsed,
    required this.headerHorizontalPaddingExpanded,
    required this.headerHorizontalPaddingCollapsed,
    required this.logoHeightExpanded,
    required this.logoHeightCollapsed,
    required this.logoTextGap,
    required this.groupHeaderHorizontalPadding,
    required this.groupHeaderTopPadding,
    required this.groupHeaderBottomPadding,
    required this.collapsedGroupSpacer,
    required this.tileTitleGapExpanded,
    required this.tileHorizontalPaddingExpanded,
    required this.tileHorizontalPaddingCollapsed,
    required this.tileIconSize,
  });

  factory SideMenuLayoutTokens.fromResponsive(AppResponsive responsive) {
    if (responsive.isDesktop) {
      return const SideMenuLayoutTokens._(
        headerHeightExpanded: 88,
        headerHeightCollapsed: 64,
        headerHorizontalPaddingExpanded: 16,
        headerHorizontalPaddingCollapsed: 12,
        logoHeightExpanded: 42,
        logoHeightCollapsed: 34,
        logoTextGap: 10,
        groupHeaderHorizontalPadding: 16,
        groupHeaderTopPadding: 16,
        groupHeaderBottomPadding: 6,
        collapsedGroupSpacer: 8,
        tileTitleGapExpanded: 12,
        tileHorizontalPaddingExpanded: 16,
        tileHorizontalPaddingCollapsed: 14,
        tileIconSize: 16,
      );
    }

    if (responsive.isTablet) {
      return const SideMenuLayoutTokens._(
        headerHeightExpanded: 84,
        headerHeightCollapsed: 64,
        headerHorizontalPaddingExpanded: 14,
        headerHorizontalPaddingCollapsed: 12,
        logoHeightExpanded: 40,
        logoHeightCollapsed: 34,
        logoTextGap: 8,
        groupHeaderHorizontalPadding: 14,
        groupHeaderTopPadding: 14,
        groupHeaderBottomPadding: 6,
        collapsedGroupSpacer: 8,
        tileTitleGapExpanded: 10,
        tileHorizontalPaddingExpanded: 14,
        tileHorizontalPaddingCollapsed: 12,
        tileIconSize: 17,
      );
    }

    return const SideMenuLayoutTokens._(
      headerHeightExpanded: 80,
      headerHeightCollapsed: 64,
      headerHorizontalPaddingExpanded: 14,
      headerHorizontalPaddingCollapsed: 12,
      logoHeightExpanded: 38,
      logoHeightCollapsed: 32,
      logoTextGap: 8,
      groupHeaderHorizontalPadding: 14,
      groupHeaderTopPadding: 14,
      groupHeaderBottomPadding: 6,
      collapsedGroupSpacer: 8,
      tileTitleGapExpanded: 10,
      tileHorizontalPaddingExpanded: 14,
      tileHorizontalPaddingCollapsed: 12,
      tileIconSize: 18,
    );
  }

  final double headerHeightExpanded;
  final double headerHeightCollapsed;
  final double headerHorizontalPaddingExpanded;
  final double headerHorizontalPaddingCollapsed;
  final double logoHeightExpanded;
  final double logoHeightCollapsed;
  final double logoTextGap;
  final double groupHeaderHorizontalPadding;
  final double groupHeaderTopPadding;
  final double groupHeaderBottomPadding;
  final double collapsedGroupSpacer;
  final double tileTitleGapExpanded;
  final double tileHorizontalPaddingExpanded;
  final double tileHorizontalPaddingCollapsed;
  final double tileIconSize;

  double headerHeight(bool isCollapsed) {
    return isCollapsed ? headerHeightCollapsed : headerHeightExpanded;
  }

  double headerHorizontalPadding(bool isCollapsed) {
    return isCollapsed
        ? headerHorizontalPaddingCollapsed
        : headerHorizontalPaddingExpanded;
  }

  double logoHeight(bool isCollapsed) {
    return isCollapsed ? logoHeightCollapsed : logoHeightExpanded;
  }

  double tileTitleGap(bool isCollapsed) {
    return isCollapsed ? 0 : tileTitleGapExpanded;
  }

  double tileHorizontalPadding(bool isCollapsed) {
    return isCollapsed
        ? tileHorizontalPaddingCollapsed
        : tileHorizontalPaddingExpanded;
  }
}
