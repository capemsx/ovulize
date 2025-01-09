import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/globals.dart';
import 'package:paged_vertical_calendar/utils/date_utils.dart';

class AppBarWidget extends StatefulWidget {
  const AppBarWidget(
      {required this.title,
      this.subtitle,
      this.showPhaseBar = false,
      this.replacement,
      this.leading});
  final String title;
  final String? subtitle;
  final bool showPhaseBar;
  final Widget? replacement;
  final Widget? leading;

  @override
  State<AppBarWidget> createState() => AppBarWidgetState();
}

class AppBarWidgetState extends State<AppBarWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: appBarHeight,
      decoration: BoxDecoration(color: barColor, boxShadow: [
        widget.showPhaseBar ? BoxShadow(spreadRadius: 2, blurRadius: 2, color: temperatureData.firstWhere((element) => element.date.isSameDay(DateTime.now())).cyclePhase.getColor()) : BoxShadow(spreadRadius: 0.5, blurRadius: 1, color: Colors.grey)
      ]),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.replacement == null
                  ? Text(
                      widget.title,
                      style: TextStyle(fontSize: 16),
                    )
                  : SizedBox(
                    width: MediaQuery.of(context).size.width / 4,
                    child: widget.replacement!
                  ),
              Visibility(
                visible: widget.subtitle != null,
                child: Text(
                  widget.subtitle ?? "",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: widget.leading,
            ),
          )
        ],
      ),
    );
  }
}
