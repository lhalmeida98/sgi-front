import 'package:flutter/foundation.dart';

import '../../resource/theme/dimens.dart';
import '../../utils/app_responsive.dart';

@immutable
class LoginLayoutTokens {
  const LoginLayoutTokens._({
    required this.pagePadding,
    required this.maxWidth,
    required this.tabletPanelGap,
    required this.desktopPanelGap,
    required this.panelPadding,
    required this.cardRadius,
    required this.sectionGap,
    required this.inlineGap,
    required this.chipVerticalPadding,
    required this.logoHeight,
    required this.topBlobOffset,
    required this.topBlobSize,
    required this.bottomBlobOffset,
    required this.bottomBlobSize,
    required this.cardShadowBlur,
    required this.cardShadowOffsetY,
    required this.loadingSize,
  });

  factory LoginLayoutTokens.fromResponsive(AppResponsive responsive) {
    if (responsive.isDesktop) {
      return const LoginLayoutTokens._(
        pagePadding: defaultPadding * 1.5,
        maxWidth: 1100,
        tabletPanelGap: defaultPadding * 1.25,
        desktopPanelGap: defaultPadding * 2,
        panelPadding: defaultPadding * 2,
        cardRadius: 24,
        sectionGap: defaultPadding,
        inlineGap: 12,
        chipVerticalPadding: 6,
        logoHeight: 42,
        topBlobOffset: 120,
        topBlobSize: 260,
        bottomBlobOffset: 140,
        bottomBlobSize: 300,
        cardShadowBlur: 30,
        cardShadowOffsetY: 18,
        loadingSize: 16,
      );
    }

    if (responsive.isTablet) {
      return const LoginLayoutTokens._(
        pagePadding: defaultPadding,
        maxWidth: 1100,
        tabletPanelGap: defaultPadding,
        desktopPanelGap: defaultPadding * 1.5,
        panelPadding: defaultPadding * 1.5,
        cardRadius: 20,
        sectionGap: defaultPadding,
        inlineGap: 10,
        chipVerticalPadding: 6,
        logoHeight: 38,
        topBlobOffset: 100,
        topBlobSize: 220,
        bottomBlobOffset: 120,
        bottomBlobSize: 260,
        cardShadowBlur: 24,
        cardShadowOffsetY: 14,
        loadingSize: 16,
      );
    }

    return const LoginLayoutTokens._(
      pagePadding: defaultPadding,
      maxWidth: 600,
      tabletPanelGap: defaultPadding,
      desktopPanelGap: defaultPadding,
      panelPadding: defaultPadding * 1.25,
      cardRadius: 18,
      sectionGap: defaultPadding * 0.9,
      inlineGap: 8,
      chipVerticalPadding: 5,
      logoHeight: 34,
      topBlobOffset: 80,
      topBlobSize: 170,
      bottomBlobOffset: 96,
      bottomBlobSize: 210,
      cardShadowBlur: 18,
      cardShadowOffsetY: 10,
      loadingSize: 14,
    );
  }

  final double pagePadding;
  final double maxWidth;
  final double tabletPanelGap;
  final double desktopPanelGap;
  final double panelPadding;
  final double cardRadius;
  final double sectionGap;
  final double inlineGap;
  final double chipVerticalPadding;
  final double logoHeight;
  final double topBlobOffset;
  final double topBlobSize;
  final double bottomBlobOffset;
  final double bottomBlobSize;
  final double cardShadowBlur;
  final double cardShadowOffsetY;
  final double loadingSize;
}
