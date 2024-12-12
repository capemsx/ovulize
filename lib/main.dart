import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget_base.dart';
import 'package:ovulize/backend/misc/functions.dart';
import 'package:ovulize/frontend/pages/main/barwrapper.dart';
import 'package:ovulize/frontend/pages/main/dashboard.dart';
import 'package:ovulize/frontend/pages/main/launcher.dart';
import 'package:ovulize/globals.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MenstrualCycleWidget.init(
      secretKey: "11a1215l0119a140409p0919", ivKey: "23a1dfr5lyhd9a1404845001");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ovulize',
      
      theme: ThemeData(
          iconTheme: IconThemeData(color: primaryColor),
          primaryIconTheme: IconThemeData(color: primaryColor),
          iconButtonTheme: IconButtonThemeData(
              style: ButtonStyle(
                  iconColor: MaterialStateProperty.all(primaryColor))),
          colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
          primarySwatch: getMaterialColor(primaryColor),
          textTheme: GoogleFonts.interTextTheme()),
      home: const LauncherPage(),
    );
  }
}
