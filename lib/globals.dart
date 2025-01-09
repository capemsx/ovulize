import 'dart:ui';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ovulize/backend/providers/cyclephasepredictor.dart';
import 'package:ovulize/backend/providers/dataprovider.dart';
import 'package:ovulize/backend/providers/thermoprovider.dart';
import 'package:ovulize/backend/types/cycle.dart';
import 'package:ovulize/backend/types/cyclephase.dart';

Color primaryColor = Color(0xFFFF4596);
Color backgroundColor = Color.fromARGB(255, 255, 247, 250);
Color backgroundOverlayColor = Color(0xFFFFE3FC);
Color barColor = Color.fromARGB(255, 255, 252, 255);

//CYCLE COLORS
Color menstruationColor = primaryColor.withOpacity(.35);
Color follicularColor = Color.fromARGB(255, 215, 57, 255).withOpacity(.35);
Color ovulationColor = Color.fromARGB(255, 110, 127, 255).withOpacity(.35);
Color lutealColor = Color.fromARGB(255, 82, 223, 255).withOpacity(.35);

//CONSTANTS
double appBarHeight = 60;

//PROVIDERS
CyclePhasePredictor cyclePhasePredictor = CyclePhasePredictor();
DataProvider dataProvider = DataProvider();
ThermoProvider thermoProvider = ThermoProvider();

List<TemperatureDay> temperatureData = [];
