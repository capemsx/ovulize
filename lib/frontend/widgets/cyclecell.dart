import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:ovulize/backend/types/cycle.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/globals.dart';

class CycleCellWidget extends StatefulWidget {
  late DateTime date;
  late CyclePhaseType phase;
  late double temperature;
  late bool trailingSeperator;
  CycleCellWidget({required this.date, required this.phase, required this.temperature, required this.trailingSeperator});

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
              Text(DateFormat("MMM").format(widget.date).toUpperCase(), style: TextStyle(color: Colors.black45, fontSize: 12, letterSpacing: 2),),
              GestureDetector(
                onTap: () {

                },
                child: Stack(
                  children: [
                    Text("Hallo"),
                    Container(
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                    )
                  ],
                ),
              ),
              
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.phase.getColor()),
                width: 30,
                height: 30,
                child: Text(widget.date.day.toString()),
              ),
            ],
          )
        ),
      ),
    );
  }


}
