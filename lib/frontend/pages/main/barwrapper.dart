import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ovulize/backend/types/tabpage.dart';
import 'package:ovulize/frontend/pages/main/dashboard.dart';
import 'package:ovulize/frontend/pages/main/measure.dart';
import 'package:ovulize/frontend/pages/sub/devices.dart';
import 'package:ovulize/frontend/pages/main/settings.dart';
import 'package:ovulize/frontend/widgets/appbar.dart';
import 'package:ovulize/globals.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class BarWrapper extends StatefulWidget {
  const BarWrapper({super.key});

  @override
  State<BarWrapper> createState() => BarWrapperState();
}

class BarWrapperState extends State<BarWrapper> {
  int selectedIndex = 0;
  List<TabPage> pages = <TabPage>[
    TabPage(title: "Dashboard", icon: LineIcons.home, page: DashboardPage()),
    TabPage(title: "Settings", icon: LineIcons.cog, page: SettingsPage()),
  ];



  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PersistentTabView(
          tabs: [
            for (TabPage page in pages)
              PersistentTabConfig(
                screen: page.page,
                item: ItemConfig(
                    icon: Icon(page.icon),
                    title: page.title,
                    activeForegroundColor: primaryColor,
                    inactiveForegroundColor: primaryColor.withOpacity(0.3)),
              )
          ],
          floatingActionButton: Container(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  color: primaryColor.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 15),
            ], borderRadius: BorderRadius.circular(12)),
            child: FloatingActionButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // <-- Radius
                ),
                elevation: 0,
                child: Icon(
                  LineIcons.thermometer34Full,
                  color: primaryColor,
                ),
                onPressed: () {}),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          backgroundColor: barColor,
          navBarBuilder: (navBarConfig) => Style10BottomNavBar(
                navBarConfig: navBarConfig,
              )),
    );
  }
}
