import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ovulize/backend/misc/functions.dart';
import 'package:ovulize/frontend/pages/main/barwrapper.dart';
import 'package:ovulize/frontend/pages/main/dashboard.dart';
import 'package:ovulize/frontend/pages/main/launcher.dart';
import 'package:ovulize/globals.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ovulize',
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
