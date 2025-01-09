import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: 
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: PagedVerticalCalendar(
            scrollController: ModalScrollController.of(context),
            minDate: temperatureData.first.date,
            initialDate: DateTime.now(),
            maxDate: temperatureData.last.date,
            dayBuilder: (context, date) {
              return Text(date.day.toString(), textAlign: TextAlign.center, style: TextStyle(color: temperatureData.where((element) => element.date.isSameDay(date)).firstOrNull?.cyclePhase.getColor() ?? Colors.grey),);
            },
          ),
        ),
    );
  }

}
