import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:ovulize/backend/providers/cyclephasepredictor.dart';
import 'package:ovulize/backend/types/cycle.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/frontend/widgets/appbar.dart';
import 'package:ovulize/globals.dart';
import 'package:paged_vertical_calendar/paged_vertical_calendar.dart';
import 'package:paged_vertical_calendar/utils/date_utils.dart';

class CycleCalendarWidget extends StatefulWidget {
  const CycleCalendarWidget({super.key});

  @override
  State<CycleCalendarWidget> createState() => CycleCalendarWidgetState();
}

class CycleCalendarWidgetState extends State<CycleCalendarWidget> {
  List<TemperatureDay> allData = [];

  @override
  void initState() {
    super.initState();
    updatePredictions();
  }

  void updatePredictions() {
    // Testdaten zum Validieren
    final testData = [
  TemperatureDay(
    date: DateTime.now().subtract(const Duration(days: 28)),
    temperature: 36.4,
    cyclePhase: CyclePhaseType.menstruation
  ),
  TemperatureDay(
    date: DateTime.now().subtract(const Duration(days: 25)),
    temperature: 36.5,
    cyclePhase: CyclePhaseType.menstruation
  ),
  TemperatureDay(
    date: DateTime.now().subtract(const Duration(days: 20)),
    temperature: 36.6,
    cyclePhase: CyclePhaseType.follicular
  ),
  TemperatureDay(
    date: DateTime.now().subtract(const Duration(days: 14)),
    temperature: 36.8,
    cyclePhase: CyclePhaseType.ovulation
  ),
  TemperatureDay(
    date: DateTime.now().subtract(const Duration(days: 7)),
    temperature: 37.0,
    cyclePhase: CyclePhaseType.luteal
  ),
  TemperatureDay(
    date: DateTime.now(),
    temperature: 36.9,
    cyclePhase: CyclePhaseType.luteal
  ),
];

    setState(() {
      allData = cyclePhasePredictor.predictFutureCyclePhases(
        testData, // Zum Testen testData statt temperatureData verwenden
        3
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: PagedVerticalCalendar(
              scrollController: ModalScrollController.of(context),
              minDate: temperatureData.first.date,
              initialDate: DateTime.now(),
              maxDate: temperatureData.last.date,
              dayBuilder: (context, date) {
                final dayData = allData.firstWhere(
                    (element) => element.date.isSameDay(date), orElse: () {
                  return TemperatureDay(
                      date: date,
                      temperature: 0.0,
                      cyclePhase: CyclePhaseType.uncertain);
                });

                return Text(
                  date.day.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: dayData.cyclePhase.getColor() ?? Colors.grey),
                );
              })),
    );
  }
}
