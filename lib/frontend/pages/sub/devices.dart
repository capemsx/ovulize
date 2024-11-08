
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:menstrual_cycle_widget/ui/menstrual_cycle_phase_view.dart';
import 'package:ovulize/globals.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});



  @override
  State<DevicesPage> createState() => DevicesPageState();
}

class DevicesPageState extends State<DevicesPage> {

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
