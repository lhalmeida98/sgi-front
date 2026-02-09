import 'package:flutter/material.dart';

import '../routing/app_sections.dart';

class MenuAppController extends ChangeNotifier {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppSection _activeSection = AppSection.dashboard;

  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;
  AppSection get activeSection => _activeSection;

  void setSection(AppSection section) {
    if (_activeSection == section) {
      return;
    }
    _activeSection = section;
    notifyListeners();
  }

  void controlMenu() {
    if (!_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.openDrawer();
    }
  }
}
