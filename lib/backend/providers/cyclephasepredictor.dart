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
  late LogisticRegressor model;
  late DataFrame trainingData;

  CyclePhasePredictor() {
    // Train a model with more features and dummy data as an example
    trainingData = DataFrame([
      ['temperature', 'avgLast5Days', 'trendLast5Days', 'phase'],
      // Menstruation (Phase 0)
      [36.4, 36.4, 0.0, 0],
      [36.5, 36.45, 0.1, 0],
      // Follikulär (Phase 1)
      [36.6, 36.5, 0.1, 1],
      [36.7, 36.6, 0.1, 1],
      // Ovulation (Phase 2)
      [36.8, 36.7, 0.2, 2],
      [37.0, 36.8, 0.3, 2],
      // Luteal (Phase 3)
      [37.1, 37.0, 0.1, 3],
      [37.0, 37.0, 0.0, 3],
      // Zweiter Zyklus zur Verbesserung
      [36.4, 36.6, -0.4, 0],
      [36.5, 36.5, 0.1, 0],
      [36.7, 36.6, 0.2, 1],
      [36.9, 36.8, 0.2, 2],
      [37.1, 37.0, 0.2, 3]
    ], headerExists: true);

    model = LogisticRegressor(trainingData, "phase", optimizerType: LinearOptimizerType.gradient);
  }

  List<TemperatureDay> predictFutureCyclePhases(List<TemperatureDay> historicalData, int monthsInFuture) {
    final int daysInFuture = monthsInFuture * 30; // Approximate days in future
    final List<TemperatureDay> allData = List.from(historicalData);

    // Predict cycle phases for historical data
    for (var day in allData) {
      final recentData = allData.sublist(max(0, allData.indexOf(day) - 5), allData.indexOf(day) + 1);
      final avgLast5Days = recentData.isNotEmpty
          ? recentData.map((d) => d.temperature).reduce((a, b) => a + b) / recentData.length
          : day.temperature;
      final trendLast5Days = recentData.length > 1
          ? recentData.last.temperature - recentData.first.temperature
          : 0.0;

      final prediction = model.predict(DataFrame([
        ['temperature', 'avgLast5Days', 'trendLast5Days'],
        [
          day.temperature,
          avgLast5Days,
          trendLast5Days
        ],
      ]));

      final predictedPhase = prediction.rows.first.first.toInt();
      day.cyclePhase = CyclePhaseType.values[predictedPhase];
    }

    // Predict cycle phases for future data
    for (int i = 0; i < daysInFuture; i++) {
      final lastDay = allData.last;
      final nextDate = lastDay.date.add(Duration(days: 1));

      // Calculate additional features (average and trend)
      final recentData = allData.sublist(max(0, allData.length - 5), allData.length);
      final avgLast5Days = recentData.isNotEmpty
          ? recentData.map((d) => d.temperature).reduce((a, b) => a + b) / recentData.length
          : lastDay.temperature;
      final trendLast5Days = recentData.length > 1
          ? recentData.last.temperature - recentData.first.temperature
          : 0.0;

      final prediction = model.predict(DataFrame([
        ['temperature', 'avgLast5Days', 'trendLast5Days'],
        [
          lastDay.temperature,
          avgLast5Days,
          trendLast5Days
        ],
      ]));

      final predictedPhase = prediction.rows.first.first.toInt();
      final nextTemperatureDay = TemperatureDay(
        date: nextDate,
        temperature: lastDay.temperature, // Assuming temperature remains constant for simplicity
        avgLast5Days: avgLast5Days,
        trendLast5Days: trendLast5Days,
        cyclePhase: CyclePhaseType.values[predictedPhase],
      );

      allData.add(nextTemperatureDay);

      // Add the new day to the training data
      final newTrainingData = DataFrame([
        ['temperature', 'avgLast5Days', 'trendLast5Days', 'phase'],
        [
          nextTemperatureDay.temperature,
          nextTemperatureDay.avgLast5Days ?? 0.0,
          nextTemperatureDay.trendLast5Days ?? 0.0,
          CyclePhaseType.values.indexOf(nextTemperatureDay.cyclePhase)
        ],
      ], headerExists: true);

      trainingData = DataFrame([...trainingData.rows, ...newTrainingData.rows], headerExists: true);
      model = LogisticRegressor(trainingData, "phase", optimizerType: LinearOptimizerType.gradient);
    }

    return allData;
  }
}