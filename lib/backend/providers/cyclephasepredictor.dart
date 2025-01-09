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
  late final LogisticRegressor model;

  CyclePhasePredictor() {
    // Train a model with more features and dummy data as an example
    final data = DataFrame([
      ['temperature', 'avgLast5Days', 'trendLast5Days', 'phase'],
      [36.5, 36.6, 0.0, 0], // menstruation
      [36.6, 36.6, 0.0, 0],
      [36.6, 36.5, 0.1, 1], // follicular
      [36.4, 36.5, -0.1, 2], // ovulation
      [36.8, 36.7, 0.2, 3], // luteal
      [37.1, 36.9, 0.3, 4], // pregnancy
      [36.5, 36.5, 0.0, 0], // menstruation
      [36.6, 36.5, 0.1, 1], // follicular
      [36.7, 36.6, 0.1, 1],
      [36.8, 36.7, 0.1, 1],
      [36.9, 36.8, 0.1, 1],
    ], headerExists: true);

    model = LogisticRegressor(data, "phase", optimizerType: LinearOptimizerType.gradient);
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
    }

    return allData;
  }

  
}
