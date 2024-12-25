import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:ovulize/frontend/widgets/appbar.dart';
import 'package:ovulize/frontend/widgets/cyclecalendar.dart';
import 'package:ovulize/frontend/widgets/cyclewheel.dart';
import 'package:ovulize/globals.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
            preferredSize:
                Size(MediaQuery.of(context).size.width, appBarHeight),
            child: AppBarWidget(
              title: "Dashboard",
              replacement: Image.asset("assets/images/logo_font_primary.png"),
              showPhaseBar: true,
              leading: IconButton(
                icon: Icon(LineIcons.calendar),
                onPressed: () {
                  showCalendar();
                },
              ),
            )),
        backgroundColor: backgroundColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CycleWheelWidget()],
        ));
  }

  void showCalendar() {
    showBarModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isDismissible: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: CycleCalendarWidget()),
      );
  }
}
