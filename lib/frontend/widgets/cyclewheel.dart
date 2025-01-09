import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ovulize/backend/types/cycle.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/frontend/widgets/cyclecell.dart';
import 'package:ovulize/globals.dart';
import 'package:paged_vertical_calendar/utils/date_utils.dart';

class CycleWheelWidget extends StatefulWidget {
  const CycleWheelWidget({super.key});

  @override
  State<CycleWheelWidget> createState() => CycleWheelWidgetState();
}

class CycleWheelWidgetState extends State<CycleWheelWidget> {
  int pastDayPreview = 30;
  int futureDayPreview = 30;
  PageController cycleWheelController = PageController(
      viewportFraction: 60 /
          MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width);
  int currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    cycleWheelController.addListener(() {
      int newDayIndex = cycleWheelController.page?.round() ?? 0;
      if (newDayIndex != currentDayIndex) {
        setState(() {
          currentDayIndex = newDayIndex;
        });
        HapticFeedback.heavyImpact();
      }
    });
    animateToCurrentDay();
  }

  void animateToCurrentDay() async {
    await Future.delayed(Duration(milliseconds: 50)); //wait for visibility of animation to user
    int pastDays = temperatureData.indexWhere((element) => element.date.isSameDay(DateTime.now()));
    cycleWheelController.animateToPage(pastDays, duration: Duration(milliseconds: 500), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Icon(
          LineIcons.alternateLongArrowDown,
          color: Colors.black45,
        ),
        SizedBox(
          height: 100,
          width: MediaQuery.of(context).size.width,
          child: ShaderMask(
            shaderCallback: (Rect rect) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  backgroundColor,
                  Colors.transparent,
                  Colors.transparent,
                  backgroundColor
                ],
                stops: [
                  0.0,
                  0.2,
                  0.8,
                  1.0
                ], // 10% purple, 80% transparent, 10% purple
              ).createShader(rect);
            },
            blendMode: BlendMode.dstOut,
            child: PageView(
              controller: cycleWheelController,
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i != temperatureData.length; i++)
                  CycleCellWidget(
                    temperatureDay: temperatureData[i],
                  )
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Widget buildTextDescriptor() {
    return Container(
      child: Column(
        children: [
          Text(
            temperatureData.firstWhere((element) => element.date.isSameDay(DateTime.now())).cyclePhase.toString(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            getLeftDaysOfCurrentPhase().toString() + " days left",
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  int getLeftDaysOfCurrentPhase() {

    DateTime now = DateTime.now();
    CyclePhaseType currentPhase = temperatureData.firstWhere((element) => element.date.isSameDay(now)).cyclePhase;
    int currentPhaseDayCount = getDayCountForPhase(currentPhase);
    int currentCycleDay = getCurrentCycleDay();
    return currentPhaseDayCount - (currentCycleDay % currentPhaseDayCount);
  }

  int getTotalCycleDays() {
    return temperatureData.length;
  }

  int getCurrentCycleDay() {
    DateTime now = DateTime.now();
    return temperatureData.indexWhere((element) => element.date.isSameDay(now)) + 1;
  }

  int getDayCountForPhase(CyclePhaseType phaseType) {
    return temperatureData.where((element) => element.cyclePhase == phaseType).length;
  }

}
