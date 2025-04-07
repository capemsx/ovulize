import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/frontend/pages/sub/measure.dart';
import 'package:ovulize/frontend/widgets/appbar.dart';
import 'package:ovulize/frontend/widgets/cyclecalendar.dart';
import 'package:ovulize/frontend/widgets/cyclewheel.dart';
import 'package:ovulize/globals.dart';
import 'package:ovulize/backend/providers/cyclephasepredictor.dart';
import 'package:paged_vertical_calendar/utils/date_utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  CycleWheelWidgetState? _cycleWheelState;
  CyclePhaseType currentPhase = CyclePhaseType.uncertain;
  int daysLeft = 0;
  int currentCycleDay = 0;
  int totalCycleDays = 28; // Standardwert, wird dynamisch aktualisiert
  bool isInitialized = false;
  int selectedDayIndex = -1; // Aktuell ausgewählter Tag im CycleWheel

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Verzögerte Initialisierung
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isInitialized = true;
          _animationController.forward(from: 0.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.of(context).size.height -
        appBarHeight -
        70; // 70 für TabBar + Sicherheit

    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size(MediaQuery.of(context).size.width, appBarHeight),
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
      body: CustomScrollView(
        physics: ClampingScrollPhysics(),
        slivers: [
          // Oberer Bereich - Aktuelle Phase
          SliverToBoxAdapter(
            child: Container(
              height: availableHeight * 0.38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isInitialized
                        ? currentPhase.getColor().withOpacity(0.8)
                        : Colors.grey.withOpacity(0.8),
                    backgroundColor,
                  ],
                ),
              ),
              child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isInitialized
                                    ? currentPhase.getColor().withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _getPhaseIcon(),
                              size: 40 *
                                  _animationController.value.clamp(0.1, 1.0),
                              color: isInitialized
                                  ? currentPhase.getColor()
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          isInitialized
                              ? currentPhase.toString()
                              : "Wird geladen...",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: isInitialized 
                                      ? daysLeft.toString() 
                                      : "?",
                                  style: TextStyle(
                                      color: isInitialized
                                          ? currentPhase.getColor()
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                TextSpan(
                                  text: daysLeft == 1 ? " day left in current phase" : " days left in current phase",
                                  style: TextStyle(
                                      color: Colors.black87, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 50),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: isInitialized && totalCycleDays > 0
                                  ? (currentCycleDay / totalCycleDays)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation(
                                isInitialized
                                    ? currentPhase.getColor()
                                    : Colors.grey,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                  
                      ],
                    );
                  }),
            ),
          ),

          // Cycle Wheel
          SliverToBoxAdapter(
            child: SizedBox(
              height: availableHeight * 0.3,
              child: CycleWheelWidget(
                onItemChanged: (phase, cycleDay, total, daysRemaining) {
                  setState(() {
                    currentPhase = phase;
                    currentCycleDay = cycleDay;
                    totalCycleDays = total > 0 ? total : 28;
                    
                    if (temperatureData.isNotEmpty && cycleDay > 0 && cycleDay <= temperatureData.length) {
                      selectedDayIndex = cycleDay - 1;
                      daysLeft = calculateDaysUntilPhaseChangeFromIndex(selectedDayIndex);
                    }
                    
                    isInitialized = true;
                    _animationController.forward(from: 0.0);
                  });
                },
                cycleWheelStateCallback: (state) {
                  _cycleWheelState = state;
                  
                  if (mounted && temperatureData.isNotEmpty) {
                    DateTime today = DateTime.now();
                    int todayIndex = temperatureData.indexWhere(
                      (element) => element.date.isSameDay(today)
                    );
                    
                    if (todayIndex == -1) {
                      int closestIndex = findClosestDateIndex(today);
                      if (closestIndex != -1) {
                        todayIndex = closestIndex;
                      } else {
                        todayIndex = 0; // Fallback zum ersten Tag
                      }
                    }
                    
                    setState(() {
                      selectedDayIndex = todayIndex;
                      currentPhase = temperatureData[todayIndex].cyclePhase;
                      currentCycleDay = todayIndex + 1;
                      
                      int cycleStartIndex = findCycleStartIndex();

                      if (cycleStartIndex != -1) {

                        totalCycleDays = findCycleLength(cycleStartIndex);
                      } else {

                        totalCycleDays = temperatureData.length > 28 ? 28 : temperatureData.length;
                      }
                      

                      daysLeft = calculateDaysUntilPhaseChangeFromIndex(todayIndex);
                      
                      isInitialized = true;
                      _animationController.forward(from: 0.0);
                    });
                  }
                },
              ),
            ),
          ),SliverToBoxAdapter(
  child: Visibility(
    visible: selectedDayIndex != -1 && !isCurrentDaySelected(),
    child: Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            if (_cycleWheelState != null) {
              _cycleWheelState!.animateToCurrentDay();
              
              DateTime today = DateTime.now();
              int todayIndex = temperatureData.indexWhere(
                (element) => element.date.isSameDay(today)
              );
              
              if (todayIndex == -1) {
                todayIndex = findClosestDateIndex(today);
              }
              
              if (todayIndex != -1) {
                setState(() {
                  selectedDayIndex = todayIndex;
                  currentPhase = temperatureData[todayIndex].cyclePhase;
                  currentCycleDay = todayIndex + 1;
                  daysLeft = calculateDaysUntilPhaseChangeFromIndex(todayIndex);
                  _animationController.forward(from: 0.0);
                });
              }
            }
          },
          icon: Icon(LineIcons.calendarCheck, color: Colors.white),
          label: Text("Today", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
          ),
        ),
      ),
    ),
  ),
),
          // Unterer Bereich - Messungsstatus
          SliverFillRemaining(
            hasScrollBody: false,
            fillOverscroll: true,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.only(
                    top: 20, left: 20, right: 20, bottom: 70),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, -2),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Your measurement",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        _buildMeasurementStatusIndicator(),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildMeasurementInfoCard(),
                    SizedBox(height: 15),
                    _buildNextMeasurementButton(),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Füge diese Methode zur DashboardPageState-Klasse hinzu
bool isCurrentDaySelected() {
  if (temperatureData.isEmpty || selectedDayIndex < 0 || selectedDayIndex >= temperatureData.length) {
    return false;
  }
  
  // Überprüfe, ob der ausgewählte Tag der heutige ist
  return temperatureData[selectedDayIndex].date.isSameDay(DateTime.now());
}

  int calculateDaysUntilPhaseChangeFromIndex(int index) {
    if (temperatureData.isEmpty || index < 0 || index >= temperatureData.length) {
      return 0;
    }
    
    CyclePhaseType currentPhase = temperatureData[index].cyclePhase;
    int daysUntilChange = 0;
    
    for (int i = index + 1; i < temperatureData.length; i++) {
      if (temperatureData[i].cyclePhase != currentPhase) {
        break;
      }
      daysUntilChange++;
    }
    
    return daysUntilChange;
  }
  
  int findCycleStartIndex() {
    if (temperatureData.isEmpty) return -1;
    
    for (int i = 0; i < temperatureData.length; i++) {
      if (temperatureData[i].cyclePhase == CyclePhaseType.menstruation) {
        if (i == 0 || temperatureData[i-1].cyclePhase != CyclePhaseType.menstruation) {
          return i;
        }
      }
    }
    
    return -1; 
  }
  
  int findCycleLength(int cycleStartIndex) {
    if (temperatureData.isEmpty || cycleStartIndex < 0) return 28;
    
    for (int i = cycleStartIndex + 1; i < temperatureData.length; i++) {
      if (temperatureData[i].cyclePhase == CyclePhaseType.menstruation &&
          (i == 0 || temperatureData[i-1].cyclePhase != CyclePhaseType.menstruation)) {
        return i - cycleStartIndex;
      }
    }
  
    return min(28, temperatureData.length - cycleStartIndex);
  }
  
  int findClosestDateIndex(DateTime date) {
    if (temperatureData.isEmpty) return -1;
    
    int closestIndex = 0;
    int smallestDiff = 9999;
    
    for (int i = 0; i < temperatureData.length; i++) {
      int diff = (temperatureData[i].date.difference(date).inDays).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        closestIndex = i;
      }
    }
    
    return closestIndex;
  }

  // Messungs-Statusindikator (grün wenn gemessen, gelb/rot wenn ausstehend)
  Widget _buildMeasurementStatusIndicator() {
    bool measuredToday = _hasMeasuredToday();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: measuredToday
            ? Colors.green.withOpacity(0.15)
            : Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: measuredToday ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (measuredToday ? Colors.green : Colors.orange)
                        .withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]),
          ),
          SizedBox(width: 6),
          Text(
            measuredToday ? "Done" : "Due",
            style: TextStyle(
              color: measuredToday
                  ? Colors.green.shade800
                  : Colors.orange.shade800,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Karte mit Informationen zur letzten Messung
  Widget _buildMeasurementInfoCard() {
    DateTime? lastMeasurement = _getLastMeasurementTime();
    DateTime nextMeasurement = _getNextMeasurementTime();
    bool isMeasurementDue = _isMeasurementDue();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isMeasurementDue ? Colors.orange.shade50 : Colors.blue.shade50,
            isMeasurementDue ? Colors.orange.shade100 : Colors.blue.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  lastMeasurement == null
                      ? LineIcons.exclamationCircle
                      : LineIcons.checkCircle,
                  color: isMeasurementDue ? Colors.orange : primaryColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMeasurement == null
                          ? "No measurement found"
                          : "Last measurement",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      lastMeasurement == null
                            ? "Please take your first measurement"
                          : _formatDateTime(lastMeasurement),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: Colors.black12, height: 1),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                LineIcons.clock,
                color: isMeasurementDue
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: isMeasurementDue
                            ? "Next measurement "
                            : "Next measurement at ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: isMeasurementDue
                            ? "due"
                            : _formatDateTime(nextMeasurement),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isMeasurementDue
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (lastMeasurement != null && !isMeasurementDue) ...[
            SizedBox(height: 8),
            _buildTimeRemainingIndicator(nextMeasurement),
          ],
        ],
      ),
    );
  }

  Widget _buildNextMeasurementButton() {
    bool isMeasurementDue = _isMeasurementDue();

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (ctx) => MeasurePage()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isMeasurementDue ? Colors.orange : primaryColor,
            padding: EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LineIcons.thermometer34Full, color: Colors.white),
              SizedBox(width: 10),
              Text(
                isMeasurementDue ? "Take measurement" : "New measurement",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRemainingIndicator(DateTime nextMeasurement) {
    DateTime now = DateTime.now();
    Duration remaining = nextMeasurement.difference(now);
    Duration total = Duration(hours: 24);
    double progress =
        1.0 - (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.blue.shade50,
            valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
            minHeight: 6,
          ),
        ),
        SizedBox(height: 4),
        Text(
          remaining.inHours >= 1
              ? "${remaining.inHours} hours and ${(remaining.inMinutes % 60).toString().padLeft(2, '0')} minutes left"
              : "${remaining.inMinutes} minutes left",
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }


  bool _hasMeasuredToday() {
    final todayData = temperatureData
        .where((element) => element.date.isSameDay(DateTime.now()));
    return todayData.isNotEmpty && todayData.first.temperature > 0;
  }


DateTime? _getLastMeasurementTime() {
  if (temperatureData.isEmpty) return null;

  var actualMeasurements = temperatureData.where((data) => data.temperature > 0).toList();
  
  if (actualMeasurements.isEmpty) return null;
  
  actualMeasurements.sort((a, b) => b.date.compareTo(a.date));
  
  if (actualMeasurements.first.date.isAfter(DateTime.now().add(Duration(days: 1)))) {
    for (var measurement in actualMeasurements) {
      if (measurement.date.isBefore(DateTime.now().add(Duration(hours: 1)))) {
        return measurement.date;
      }
    }
    return null;
  }
  
  return actualMeasurements.first.date;
}


  DateTime _getNextMeasurementTime() {
    DateTime? lastMeasurement = _getLastMeasurementTime();
    if (lastMeasurement == null) return DateTime.now();
    return lastMeasurement.add(Duration(hours: 24));
  }


  bool _isMeasurementDue() {
    if (_hasMeasuredToday()) return false;

    DateTime? lastMeasurement = _getLastMeasurementTime();
    if (lastMeasurement == null) return true;

    DateTime nextDueMeasurement = lastMeasurement.add(Duration(hours: 24));
    return DateTime.now().isAfter(nextDueMeasurement);
  }


  String _formatDateTime(DateTime dateTime) {
  return "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
}


  IconData _getPhaseIcon() {
    switch (currentPhase) {
      case CyclePhaseType.menstruation:
        return LineIcons.tint;
      case CyclePhaseType.follicular:
        return LineIcons.leaf;
      case CyclePhaseType.ovulation:
        return LineIcons.egg;
      case CyclePhaseType.luteal:
        return LineIcons.moon;
      default:
        return LineIcons.questionCircle;
    }
  }

    void showCalendar() {
    showBarModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        height: MediaQuery.of(context).size.height * 0.8,
        child: CycleCalendarWidget(),
      ),
    );
  }
}