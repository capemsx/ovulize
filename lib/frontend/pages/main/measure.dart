
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:menstrual_cycle_widget/ui/menstrual_cycle_phase_view.dart';
import 'package:ovulize/globals.dart';

class MeasurePage extends StatefulWidget {
  const MeasurePage({super.key});



  @override
  State<MeasurePage> createState() => MeasurePageState();
}

class MeasurePageState extends State<MeasurePage> {

  @override
  void initState() {
    super.initState();

  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        child: Column(
          children: [
        ],),
      )
    );
  }
}
