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
    cycleWheelController.animateToPage(pastDayPreview, duration: Duration(milliseconds: 500), curve: Curves.easeOutCubic);
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
                for (int i = 0; i != pastDayPreview + futureDayPreview; i++)
                  CycleCellWidget(
                    date: DateTime.now().copyWith(day: DateTime.now().day - pastDayPreview + i),
                    phase: CyclePhaseType.menstruation,
                    temperature: Random().nextDouble() * 36.6,
                    trailingSeperator: i != pastDayPreview + futureDayPreview,
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
            currentCyclePhase.type.toString(),
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
    int daysSinceStart = now.difference(currentOvulationCycle.startDate).inDays;
    int daysSincePhaseStart = 0;

    for (CyclePhase phase in currentOvulationCycle.phases) {
      if (phase.type == currentCyclePhase.type) {
        int daysIntoCurrentPhase = daysSinceStart - daysSincePhaseStart;
        return phase.durationDays - daysIntoCurrentPhase;
      }
      daysSincePhaseStart += phase.durationDays;
    }

    return 0; // Return 0 if we're at the end of the cycle
  }

  int getTotalCycleDays() {
    int totalDays = 0;
    for (CyclePhase phase in currentOvulationCycle.phases) {
      totalDays += phase.durationDays;
    }
    return totalDays;
  }

  int getCurrentCycleDay() {
    DateTime now = DateTime.now();
    int daysSinceStart = now.difference(currentOvulationCycle.startDate).inDays;
    return daysSinceStart + 1;
  }

  int getDayCountForPhase(CyclePhaseType phaseType) {
    for (CyclePhase phase in currentOvulationCycle.phases) {
      if (phase.type == phaseType) {
        return phase.durationDays;
      }
    }
    return 0;
  }
}
