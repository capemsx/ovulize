import 'package:ovulize/backend/types/cycle.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/globals.dart';

class CycleProvider {
  // Berechnet durchschnittliche Zyklus- und Phasendauern aus individuellen Daten
  Future<Map<String, dynamic>> estimateCycleDurations() async {
    final data = await dataProvider.getTemperatureData();
    int totalDays = data.length;
    int estimatedCycleLength = 0;

    int normalCycleDays = 24;
    int ovulationDays = 4;

    if (totalDays >= 28) {
      int cycleLengthSum = 0;
      int cycleCount = 0;
      int normalCycleCount = 0, ovulationCount = 0;

      DateTime? lastCycleStart;
      double avgTemp = 0;
      double tempSum = 0;

      // Durchschnittliche Temperatur berechnen
      for (var record in data) {
        double temp = record['temperature_value'];
        tempSum += temp;
      }
      avgTemp = tempSum / totalDays;

      // Schwellenwert für Eisprung basierend auf historischem Durchschnitt
      double ovulationThreshold =
          avgTemp + 0.3; // z. B. 0,3°C über dem Durchschnitt

      for (var record in data) {
        double temp = record['temperature_value'];
        DateTime date = DateTime.parse(record['timestamp']);

        if (temp >= ovulationThreshold) {
          ovulationCount++;
        } else {
          normalCycleCount++;
          if (lastCycleStart != null) {
            cycleLengthSum += date.difference(lastCycleStart).inDays;
            cycleCount++;
          }
          lastCycleStart = date;
        }
      }

      // Durchschnittliche Zykluslänge berechnen
      if (cycleCount > 0) {
        estimatedCycleLength = (cycleLengthSum / cycleCount).round();
      }

      // Phasendauern berechnen
      normalCycleDays =
          ((normalCycleCount / totalDays) * estimatedCycleLength).round();
      ovulationDays =
          ((ovulationCount / totalDays) * estimatedCycleLength).round();
    }

    return {
      'cycleLength': estimatedCycleLength,
      'normalCycleDays': normalCycleDays,
      'ovulationDays': ovulationDays,
    };
  }

  Future<OvulationCycle> getCurrentCycle() async {
    final cycleDurations = await estimateCycleDurations();
    final cycleLength = cycleDurations['cycleLength'] ?? 28;

    DateTime cycleStart = DateTime.now().subtract(Duration(days: cycleLength));
    DateTime cycleEnd = cycleStart.add(Duration(days: cycleLength));

    List<CyclePhase> phases = [
      CyclePhase(
          type: CyclePhaseType.menstruation,
          durationDays: cycleDurations[CyclePhaseType.menstruation] ?? 5),
      CyclePhase(
          type: CyclePhaseType.follicular,
          durationDays: cycleDurations[CyclePhaseType.follicular] ?? 9),
      CyclePhase(
          type: CyclePhaseType.ovulation,
          durationDays: cycleDurations[CyclePhaseType.ovulation] ?? 3),
      CyclePhase(
          type: CyclePhaseType.luteal,
          durationDays: cycleDurations[CyclePhaseType.luteal] ?? 6),
    ];

    return OvulationCycle(
      phases: phases,
      startDate: cycleStart,
      endDate: cycleEnd,
    );
  }

  Future<CyclePhase> getCurrentPhase() async {
    OvulationCycle currentCycle = await getCurrentCycle();
    DateTime now = DateTime.now();
    int daysSinceStart = now.difference(currentCycle.startDate).inDays;
    int daysSincePhaseStart = 0;

    for (CyclePhase phase in currentCycle.phases) {
      if (daysSincePhaseStart + phase.durationDays > daysSinceStart) {
        return phase;
      }
      daysSincePhaseStart += phase.durationDays;
    }
    return CyclePhase(
        type: CyclePhaseType.menstruation, durationDays: 0); // Fallback
  }

  // Berechnet zukünftige Zyklen für bis zu 6 Monate
  Future<List<OvulationCycle>> getFutureCycles({int monthsAhead = 6}) async {
    final List<OvulationCycle> futureCycles = [];
    DateTime cycleStart = DateTime.now();

    for (int i = 0; i < monthsAhead; i++) {
      final cycle = await getCurrentCycle();
      futureCycles.add(cycle);
      cycleStart = cycle.endDate.add(Duration(days: 1));
    }

    return futureCycles;
  }

  Future<CyclePhaseType> getCyclePhaseTypeForDate(DateTime date) async {
    List<OvulationCycle> futureCycles = await getFutureCycles();
    for (var cycle in futureCycles) {
      if (date.isAfter(cycle.startDate) && date.isBefore(cycle.endDate)) {
        int daysSinceStart = date.difference(cycle.startDate).inDays;
        int daysSincePhaseStart = 0;
        for (CyclePhase phase in cycle.phases) {
          if (daysSincePhaseStart + phase.durationDays > daysSinceStart) {
            return phase.type;
          }
          daysSincePhaseStart += phase.durationDays;
        }
    }
  }
  return CyclePhaseType.menstruation; // Fallback
}
}