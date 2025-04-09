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
  final CyclePhasePredictor cyclePhasePredictor = CyclePhasePredictor();
  DateTime minDate = DateTime.now().subtract(const Duration(days: 60));
  DateTime maxDate = DateTime.now().add(const Duration(days: 60));

  @override
  void initState() {
    super.initState();
    updatePredictions();
  }

  void updatePredictions() {
    setState(() {
      // Der Predictor sollte selbst mit leeren Daten umgehen können
      allData = cyclePhasePredictor.predictFutureCyclePhases(temperatureData, 3);
      
      if (allData.isNotEmpty) {
        allData.sort((a, b) => a.date.compareTo(b.date));
        minDate = allData.first.date;
        maxDate = allData.last.date;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: PagedVerticalCalendar(
                scrollController: ModalScrollController.of(context),
                minDate: minDate,
                initialDate: DateTime.now(),
                maxDate: maxDate,
                dayBuilder: (context, date) {
                  final dayData = allData.firstWhere(
                    (element) => element.date.isSameDay(date), 
                    orElse: () {
                      return TemperatureDay(
                        date: date,
                        temperature: 0.0,
                        cyclePhase: CyclePhaseType.uncertain
                      );
                    }
                  );

                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: dayData.cyclePhase.getColor().withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: date.isSameDay(DateTime.now()) ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}