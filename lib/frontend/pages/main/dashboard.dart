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

class DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  CycleWheelWidgetState? _cycleWheelState;
  CyclePhaseType currentPhase = CyclePhaseType.uncertain;
  int daysLeft = 0;
  int currentCycleDay = 0;
  int totalCycleDays = 28;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600),
    );
    
    // Wir können die Initialisierung direkt hier starten
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          // Fallback-Werte setzen, falls die Callback-Methoden noch nicht funktionieren
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

void updatePhaseInfo() {
  if (!mounted) return;
  
  // setState außerhalb der Build-Phase aufrufen
  Future.microtask(() {
    if (mounted) {
      setState(() {
        if (_cycleWheelState != null) {
          try {
            currentPhase = _cycleWheelState!.getCurrentPhase();
            daysLeft = _cycleWheelState!.getLeftDaysOfCurrentPhase();
            currentCycleDay = _cycleWheelState!.getCurrentCycleDay();
            totalCycleDays = _cycleWheelState!.getTotalCycleDays();
          } catch (e) {
            print("Fehler beim Abrufen der Phasen-Informationen: $e");
          }
          isInitialized = true;
          _animationController.forward(from: 0.0);
        }
      });
    }
  });
}
@override
Widget build(BuildContext context) {
  // Berechnung des verfügbaren Platzes unter Berücksichtigung der TabBar
  // Die TabBar hat typischerweise eine Höhe von ca. 56 Pixeln, aber wir geben etwas mehr für Sicherheit
  final availableHeight = MediaQuery.of(context).size.height - appBarHeight - 70; // 70 für TabBar + Sicherheit
  
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
      )
    ),
    backgroundColor: backgroundColor,
    // SingleChildScrollView entfernen und durch CustomScrollView ersetzen
    body: CustomScrollView(
      physics: ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            // Oberer Bereich - Aktuelle Phase
            height: availableHeight * 0.38, // Prozentsatz anpassen, damit genug Platz bleibt
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isInitialized ? currentPhase.getColor().withOpacity(0.8) : Colors.grey.withOpacity(0.8),
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
                    // Der Rest des oberen Bereichs bleibt gleich
                    // ...
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isInitialized ? currentPhase.getColor().withOpacity(0.5) : Colors.grey.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _getPhaseIcon(),
                          size: 40 * _animationController.value.clamp(0.1, 1.0),
                          color: isInitialized ? currentPhase.getColor() : Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: 15), // Verringert
                    Text(
                      isInitialized ? _getPhaseName(currentPhase) : "Wird geladen...",
                      style: TextStyle(
                        fontSize: 22, // Etwas verkleinert
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
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              text: "Noch ",
                              style: TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                            TextSpan(
                              text: isInitialized ? daysLeft.toString() : "?",
                              style: TextStyle(
                                color: isInitialized ? currentPhase.getColor() : Colors.grey, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 18
                              ),
                            ),
                            TextSpan(
                              text: " Tage in dieser Phase",
                              style: TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10), // Verringert
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: isInitialized ? (currentCycleDay / totalCycleDays).clamp(0.0, 1.0) : 0.0,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation(
                            isInitialized ? currentPhase.getColor() : Colors.grey,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    SizedBox(height: 6), // Verringert
                    Text(
                      isInitialized ? "Tag $currentCycleDay im Zyklus" : "Wird geladen...",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
        
        // Cycle Wheel
        SliverToBoxAdapter(
          child: SizedBox(
            height: availableHeight * 0.4, // Genug Platz für das Wheel
            child: CycleWheelWidget(
              onItemChanged: (phase, cycleDay, total, daysRemaining) {
                setState(() {
                  currentPhase = phase;
                  daysLeft = daysRemaining;
                  currentCycleDay = cycleDay;
                  totalCycleDays = total;
                  isInitialized = true;
                  _animationController.forward(from: 0.0);
                });
              },
              cycleWheelStateCallback: (state) {
                _cycleWheelState = state;
                updatePhaseInfo();
              },
            ),
          ),
        ),
        // Nach dem CycleWheel SliverToBoxAdapter füge diesen neuen Bereich hinzu
// Unterer Bereich - Messungsstatus
SliverFillRemaining(
  hasScrollBody: false,
  fillOverscroll: true,
  child: Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 70), // Unten Abstand für TabBar
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
                "Deine Messung",
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

// Statusindikator für die Messung (grün wenn gemessen, gelb/rot wenn ausstehend)
Widget _buildMeasurementStatusIndicator() {
  bool measuredToday = _hasMeasuredToday();
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: measuredToday ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
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
                color: (measuredToday ? Colors.green : Colors.orange).withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
              )
            ]
          ),
        ),
        SizedBox(width: 6),
        Text(
          measuredToday ? "Erledigt" : "Ausstehend",
          style: TextStyle(
            color: measuredToday ? Colors.green.shade800 : Colors.orange.shade800,
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
                lastMeasurement == null ? LineIcons.exclamationCircle : LineIcons.checkCircle,
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
                        ? "Keine Messung gefunden" 
                        : "Letzte Messung",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    lastMeasurement == null
                        ? "Bitte nimm deine erste Messung vor"
                        : "${_formatDateTime(lastMeasurement)} Uhr", 
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
              color: isMeasurementDue ? Colors.orange.shade700 : Colors.blue.shade700,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isMeasurementDue ? "Nächste Messung " : "Nächste Messung am ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: isMeasurementDue ? "jetzt fällig" : "${_formatDateTime(nextMeasurement)} Uhr",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isMeasurementDue ? Colors.orange.shade700 : Colors.blue.shade700,
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

// Button zur Durchführung der nächsten Messung
Widget _buildNextMeasurementButton() {
  bool isMeasurementDue = _isMeasurementDue();
  
  return Container(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () {
        // Hier die Navigation zur Messungsseite einfügen
        Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => MeasurePage()
        ));
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
            isMeasurementDue ? "Jetzt messen" : "Neue Messung",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

// Fortschrittsbalken, der anzeigt, wie viel Zeit bis zur nächsten Messung bleibt
Widget _buildTimeRemainingIndicator(DateTime nextMeasurement) {
  // Berechnung der verbleibenden Zeit
  DateTime now = DateTime.now();
  Duration remaining = nextMeasurement.difference(now);
  Duration total = Duration(hours: 24);
  double progress = 1.0 - (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);
  
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
            ? "Noch ${remaining.inHours} Stunden und ${(remaining.inMinutes % 60).toString().padLeft(2, '0')} Minuten" 
            : "Noch ${remaining.inMinutes} Minuten",
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    ],
  );
}

// Prüft, ob heute bereits gemessen wurde
bool _hasMeasuredToday() {
  // Diese Methode muss die tatsächliche Implementierung haben
  // Prüfe die temperatureData auf einen Eintrag für heute
  final todayData = temperatureData.where((element) => element.date.isSameDay(DateTime.now()));
  return todayData.isNotEmpty && todayData.first.temperature > 0;
}

// Gibt den Zeitpunkt der letzten Messung zurück
DateTime? _getLastMeasurementTime() {
  // Diese Methode muss die tatsächliche Implementierung haben
  // Sortiere temperatureData nach Datum und finde den letzten Eintrag
  if (temperatureData.isEmpty) return null;
  
  var sortedData = List.from(temperatureData);
  sortedData.sort((a, b) => b.date.compareTo(a.date));
  
  return sortedData.first.date;
}

// Gibt den Zeitpunkt der nächsten Messung zurück (24h nach der letzten)
DateTime _getNextMeasurementTime() {
  DateTime? lastMeasurement = _getLastMeasurementTime();
  
  if (lastMeasurement == null) {
    // Wenn noch keine Messung existiert, schlage den aktuellen Zeitpunkt vor
    return DateTime.now();
  }
  
  // 24 Stunden nach der letzten Messung
  return lastMeasurement.add(Duration(hours: 24));
}

// Prüft, ob eine neue Messung fällig ist
bool _isMeasurementDue() {
  if (_hasMeasuredToday()) return false;
  
  DateTime? lastMeasurement = _getLastMeasurementTime();
  if (lastMeasurement == null) return true;
  
  DateTime nextDueMeasurement = lastMeasurement.add(Duration(hours: 24));
  return DateTime.now().isAfter(nextDueMeasurement);
}

// Formatiert ein DateTime-Objekt schön für die Anzeige
String _formatDateTime(DateTime dateTime) {
  return "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')} um ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
}

  // Neue Hilfsmethode für die Anzeige des Phasennamens
  String _getPhaseName(CyclePhaseType phase) {
    switch (phase) {
      case CyclePhaseType.menstruation:
        return "Menstruation";
      case CyclePhaseType.follicular:
        return "Follikelphase";
      case CyclePhaseType.ovulation:
        return "Eisprung";
      case CyclePhaseType.luteal:
        return "Lutealphase";
      default:
        return "Unbekannte Phase";
    }
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

  List<Widget> _buildUpcomingPhases() {
    List<CyclePhaseType> allPhases = [
      CyclePhaseType.menstruation,
      CyclePhaseType.follicular,
      CyclePhaseType.ovulation,
      CyclePhaseType.luteal,
    ];
    
    int currentIndex = allPhases.indexOf(currentPhase);
    if (currentIndex == -1) currentIndex = 0;
    
    List<Widget> phaseWidgets = [];
    
    for (int i = 1; i <= 3; i++) {
      int nextPhaseIndex = (currentIndex + i) % allPhases.length;
      CyclePhaseType nextPhase = allPhases[nextPhaseIndex];
      
      phaseWidgets.add(
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: nextPhase.getColor().withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForPhase(nextPhase),
                color: nextPhase.getColor(),
                size: 24,
              ),
            ),
            SizedBox(height: 6),
            Text(
              _getShortName(nextPhase),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }
    
    return phaseWidgets;
  }

  IconData _getIconForPhase(CyclePhaseType phase) {
    switch (phase) {
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

  String _getShortName(CyclePhaseType phase) {
    switch (phase) {
      case CyclePhaseType.menstruation:
        return "Mens";
      case CyclePhaseType.follicular:
        return "Follikel";
      case CyclePhaseType.ovulation:
        return "Eisprung";
      case CyclePhaseType.luteal:
        return "Luteal";
      default:
        return "Unbekannt";
    }
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