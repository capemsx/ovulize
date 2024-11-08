import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:menstrual_cycle_widget/ui/menstrual_cycle_phase_view.dart';
import 'package:ovulize/backend/types/cycle.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/globals.dart';

class CycleWheelWidget extends StatefulWidget {
  const CycleWheelWidget({super.key});

  @override
  State<CycleWheelWidget> createState() => CycleWheelWidgetState();
}

class CycleWheelWidgetState extends State<CycleWheelWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: MenstrualCyclePhaseView(
            viewType: MenstrualCycleViewType.circleText,
            centralCircleBackgroundColor: backgroundColor,
            phaseTextBoundaries: PhaseTextBoundaries.outside,
            outsideTextCharSpace: 3,
            arcStrokeWidth: 200,
            size: 300,
            centralCircleSize: 110,
            selectedDayCircleSize: 23,
            totalCycleDays: getTotalCycleDays(),
            selectedDay: getCurrentCycleDay(),
            follicularDayCount: getDayCountForPhase(CyclePhaseType.follicular),
            menstruationDayCount: getDayCountForPhase(CyclePhaseType.menstruation),
            ovulationDayCount: getDayCountForPhase(CyclePhaseType.ovulation),
            ovulationBackgroundColor: ovulationColor,
            follicularBackgroundColor: follicularColor,
            menstruationBackgroundColor: menstruationColor,
            lutealPhaseBackgroundColor: lutealColor,
            ovulationTextColor: ovulationColor,
            follicularTextColor: follicularColor,
            menstruationTextColor: menstruationColor,
            lutealPhaseTextColor: lutealColor,
            
            //luteal day count represents the difference between total day count and the sum of the other phases
          ),
        ),
        buildTextDescriptor()
      ],
    );
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
