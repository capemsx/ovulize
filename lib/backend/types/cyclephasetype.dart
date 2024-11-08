import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ovulize/globals.dart';

enum CyclePhaseType {
  menstruation,
  follicular,
  ovulation,
  luteal,
  test;

  @override
  String toString() {
    switch (this) {
      case CyclePhaseType.menstruation:
        return 'Menstruation';
      case CyclePhaseType.follicular:
        return 'Follicular phase';
      case CyclePhaseType.ovulation:
        return 'Ovulation';
      case CyclePhaseType.test:
        return 'Test';
      case CyclePhaseType.luteal:
        return 'Luteal phase';
    }
  }

  Color getColor() {
    switch (this) {
      case CyclePhaseType.menstruation:
        return menstruationColor;
      case CyclePhaseType.follicular:
        return follicularColor;
      case CyclePhaseType.ovulation:
        return ovulationColor;
      case CyclePhaseType.luteal:
        return lutealColor;
      case CyclePhaseType.test:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
