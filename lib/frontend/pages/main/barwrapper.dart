import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ovulize/backend/types/tabpage.dart';
import 'package:ovulize/frontend/pages/main/dashboard.dart';
import 'package:ovulize/frontend/pages/sub/measure.dart';
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
    return SafeArea(
      child: Expanded(
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
            floatingActionButton: FittedBox(
              child: ListenableBuilder(
                  listenable: thermoProvider.foundOvulizeSensors,
                  builder: (context, wdg) {
                    return Stack(
                      alignment: Alignment(1.4, -1.5),
                      children: [
                        FloatingActionButton(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12), // <-- Radius
                            ),
                            elevation: 0,
                            child: Icon(
                              LineIcons.thermometer34Full,
                              color: primaryColor,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => MeasurePage()));
                            }),
                        Visibility(
                          visible:
                              thermoProvider.foundOvulizeSensors.value.isNotEmpty,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(
                              // This is your Badge
                              padding: EdgeInsets.all(8),
                              height: 5,
                              width: 5,
                              decoration: BoxDecoration(
                                // This controls the shadow
                                boxShadow: [
                                  BoxShadow(
                                      color: primaryColor.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 15),
                                ],
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.green.withOpacity(
                                    0.6), // This would be color of the Badge
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            backgroundColor: backgroundColor,
            gestureNavigationEnabled: true,
            navBarBuilder: (navBarConfig) => Style10BottomNavBar(
                  navBarDecoration: NavBarDecoration(color: barColor, boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 15),
                  ]),
                  navBarConfig: navBarConfig,
                )),
      ),
    );
  }
}
