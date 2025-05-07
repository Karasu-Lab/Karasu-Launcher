import 'package:flutter/material.dart';

class SideMenuAnimation {
  final AnimationController controller;
  late final Animation<double> widthAnimation;

  SideMenuAnimation({required this.controller}) {
    widthAnimation = Tween<double>(
      begin: 0.05,
      end: 0.2,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  bool get isMenuOpen => controller.value > 0.5;

  double calculateMenuWidth() {
    const double iconWidth = 44.0;
    const double expandedWidth = 180.0;

    return isMenuOpen
        ? iconWidth +
            (expandedWidth - iconWidth) * ((controller.value - 0.5) * 2)
        : iconWidth;
  }

  double getTextOpacity() {
    if (controller.value < 0.7) return 0;
    return (controller.value - 0.7) * 3.3;
  }

  void openMenu() {
    controller.forward();
  }

  void closeMenu() {
    controller.reverse();
  }

  void setMenuState(bool isOpen) {
    if (isOpen) {
      openMenu();
    } else {
      closeMenu();
    }
  }
}
