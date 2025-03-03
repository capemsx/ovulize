import 'dart:math';

import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ovulize/backend/types/cycle.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';
import 'package:ovulize/globals.dart';

class TemperatureDay {
  final DateTime date;
  final double temperature;
  final double? avgLast5Days;
  final double? trendLast5Days;
  CyclePhaseType cyclePhase;

  TemperatureDay({
    required this.date,
    required this.temperature,
    this.avgLast5Days,
    this.trendLast5Days,
    this.cyclePhase = CyclePhaseType.uncertain,
  });
}

class CyclePhasePredictor {
  LogisticRegressor? model;
  DataFrame? trainingData;
  bool isModelTrained = false;

  CyclePhasePredictor();

  bool hasCompleteCycle(List<TemperatureDay> historicalData) {
    // Prüfen, ob mindestens ein vollständiger Zyklus vorliegt
    // Ein Zyklus ist komplett, wenn Daten von allen Phasen vorliegen
    if (historicalData.length < 21) {
      // Mindestlänge eines Zyklus (ca. 21 Tage)
      return false;
    }

    // Prüfe, ob alle Phasenwerte vorhanden sind
    Set<CyclePhaseType> phases = {};
    for (var day in historicalData) {
      if (day.cyclePhase != CyclePhaseType.uncertain) {
        phases.add(day.cyclePhase);
      }
    }

    // Alle vier Phasentypen sollten vorhanden sein
    return phases.length >= 4;
  }

  void trainModel(List<TemperatureDay> historicalData) {
    if (!hasCompleteCycle(historicalData)) {
      return; // Nicht genügend Daten für Training
    }

    List<List<dynamic>> trainingRows = [
      ['temperature', 'avgLast5Days', 'trendLast5Days', 'phase']
    ];

    for (var day in historicalData) {
      if (day.cyclePhase != CyclePhaseType.uncertain) {
        trainingRows.add([
          day.temperature,
          day.avgLast5Days ?? day.temperature,
          day.trendLast5Days ?? 0.0,
          CyclePhaseType.values.indexOf(day.cyclePhase)
        ]);
      }
    }

    trainingData = DataFrame(trainingRows, headerExists: true);
    model = LogisticRegressor(trainingData!, "phase",
        optimizerType: LinearOptimizerType.gradient);
    isModelTrained = true;
  }

  List<TemperatureDay> predictFutureCyclePhases(
      List<TemperatureDay> historicalData, int monthsInFuture) {
    final List<TemperatureDay> allData = List.from(historicalData);

    // Überprüfe, ob genug Daten zum Training vorhanden sind
    if (!isModelTrained) {
      trainModel(historicalData);

      // Wenn immer noch nicht genug Daten, keine Vorhersagen machen
      if (!isModelTrained) {
        return allData; // Gib die ursprünglichen Daten zurück ohne Vorhersagen
      }
    }

    // Berechne Features für historische Daten
    for (var day in allData) {
      final recentData = allData.sublist(
          max(0, allData.indexOf(day) - 5), allData.indexOf(day) + 1);
      final avgLast5Days = recentData.isNotEmpty
          ? recentData.map((d) => d.temperature).reduce((a, b) => a + b) /
              recentData.length
          : day.temperature;
      final trendLast5Days = recentData.length > 1
          ? recentData.last.temperature - recentData.first.temperature
          : 0.0;

      if (model != null) {
        final prediction = model!.predict(DataFrame([
          ['temperature', 'avgLast5Days', 'trendLast5Days'],
          [day.temperature, avgLast5Days, trendLast5Days],
        ]));

        final predictedPhase = prediction.rows.first.first.toInt();
        day.cyclePhase = CyclePhaseType.values[predictedPhase];
      }
    }

    // Wenn kein Modell trainiert wurde, keine Zukunftsprognosen
    if (model == null) {
      return allData;
    }

    // Vorhersage für zukünftige Tage
    final int daysInFuture = monthsInFuture * 30;
    for (int i = 0; i < daysInFuture; i++) {
      final lastDay = allData.last;
      final nextDate = lastDay.date.add(const Duration(days: 1));

      final recentData =
          allData.sublist(max(0, allData.length - 5), allData.length);
      final avgLast5Days = recentData.isNotEmpty
          ? recentData.map((d) => d.temperature).reduce((a, b) => a + b) /
              recentData.length
          : lastDay.temperature;
      final trendLast5Days = recentData.length > 1
          ? recentData.last.temperature - recentData.first.temperature
          : 0.0;

      final prediction = model!.predict(DataFrame([
        ['temperature', 'avgLast5Days', 'trendLast5Days'],
        [lastDay.temperature, avgLast5Days, trendLast5Days],
      ]));

      final predictedPhase = prediction.rows.first.first.toInt();
      final nextTemperatureDay = TemperatureDay(
        date: nextDate,
        temperature: lastDay.temperature,
        avgLast5Days: avgLast5Days,
        trendLast5Days: trendLast5Days,
        cyclePhase: CyclePhaseType.values[predictedPhase],
      );

      allData.add(nextTemperatureDay);
    }

    return allData;
  }

  void updateModel(TemperatureDay day) {
    if (trainingData == null || model == null) return;

    final newTrainingData = DataFrame([
      ['temperature', 'avgLast5Days', 'trendLast5Days', 'phase'],
      [
        day.temperature,
        day.avgLast5Days ?? 0.0,
        day.trendLast5Days ?? 0.0,
        CyclePhaseType.values.indexOf(day.cyclePhase)
      ],
    ], headerExists: true);

    trainingData = DataFrame([...trainingData!.rows, ...newTrainingData.rows],
        headerExists: true);
    model = LogisticRegressor(trainingData!, "phase",
        optimizerType: LinearOptimizerType.gradient);
  }
}
