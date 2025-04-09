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
  final Function(CyclePhaseType phase, int cycleDay, int totalDays, int daysRemaining)? onItemChanged;
  final Function(CycleWheelWidgetState)? cycleWheelStateCallback;

  const CycleWheelWidget({
    super.key, 
    this.onItemChanged,
    this.cycleWheelStateCallback,
  });

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
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (widget.cycleWheelStateCallback != null) {
      widget.cycleWheelStateCallback!(this);
    }
  });
  
  cycleWheelController.addListener(() {
    int newDayIndex = cycleWheelController.page?.round() ?? 0;
    if (newDayIndex != currentDayIndex) {
      setState(() {
        currentDayIndex = newDayIndex;
      });
      
      if (widget.onItemChanged != null && newDayIndex < temperatureData.length && newDayIndex >= 0) {
        final selectedDay = temperatureData[newDayIndex];
        widget.onItemChanged!(
          selectedDay.cyclePhase,
          newDayIndex + 1, // Damit es bei 1 anfängt statt bei 0
          temperatureData.length,
          getLeftDaysOfCurrentPhase()
        );
      }
      
      HapticFeedback.heavyImpact();
    }
  });
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    animateToCurrentDay();
  });
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

 void animateToCurrentDay() async {
    await Future.delayed(Duration(milliseconds: 50)); //wait for visibility of animation to user
    int pastDays = temperatureData.indexWhere((element) => element.date.isSameDay(DateTime.now()));
    cycleWheelController.animateToPage(pastDays, duration: Duration(milliseconds: 500), curve: Curves.easeOutCubic);
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
  CyclePhaseType getCurrentPhase() {
    if (temperatureData.isEmpty) return CyclePhaseType.uncertain;
    
    int todayIndex = temperatureData.indexWhere((element) => element.date.isSameDay(DateTime.now()));
    if (todayIndex == -1) {
      // Falls heutiger Tag nicht vorhanden, nimm den nächsten Tag
      temperatureData.sort((a, b) => a.date.compareTo(b.date));
      int closestIndex = 0;
      DateTime now = DateTime.now();
      int smallestDiff = 9999;
      
      for (int i = 0; i < temperatureData.length; i++) {
        int diff = (temperatureData[i].date.difference(now).inDays).abs();
        if (diff < smallestDiff) {
          smallestDiff = diff;
          closestIndex = i;
        }
      }
      
      return temperatureData[closestIndex].cyclePhase;
    }
    
    return temperatureData[todayIndex].cyclePhase;
  }
}
