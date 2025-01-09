import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:ovulize/backend/providers/cyclephasepredictor.dart';
import 'package:ovulize/backend/types/cycle.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/globals.dart';

class CycleCellWidget extends StatefulWidget {
  late TemperatureDay temperatureDay;
  CycleCellWidget({required this.temperatureDay});

  @override
  State<CycleCellWidget> createState() => CycleCellWidgetState();
}

class CycleCellWidgetState extends State<CycleCellWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(width: 0.2))),
      child: Container(
        width: 40,
        height: 100,
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(DateFormat("MMM").format(widget.temperatureDay.date).toUpperCase(), style: TextStyle(color: Colors.black45, fontSize: 12, letterSpacing: 2),),

              
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.temperatureDay.cyclePhase.getColor()),
                width: 30,
                height: 30,
                child: Text(widget.temperatureDay.date.day.toString()),
              ),
              Spacer(),
               Text(widget.temperatureDay.cyclePhase.toString().toUpperCase().substring(0, 3), style: TextStyle(color: Colors.black45, fontSize: 12, letterSpacing: 2),),
               Spacer(),
            ],
          )
        ),
      ),
    );
  }


}
