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
      [36.3, null, null, 0], // menstruation
      [36.4, null, null, 0],
      [36.6, 36.5, 0.1, 1], // follicular
      [36.4, 36.5, -0.1, 2], // ovulation
      [36.8, 36.7, 0.2, 3], // luteal
      [37.1, 36.9, 0.3, 4], // pregnancy
    ], headerExists: true);

    model = LogisticRegressor(data, "phase", optimizerType: LinearOptimizerType.gradient);
  }

  List<TemperatureDay> predictCyclePhases(List<TemperatureDay> historicalData) {
    for (int i = 0; i < historicalData.length; i++) {
      final currentDay = historicalData[i];

      // Calculate additional features (average and trend of last 5 days)
      final recentData = historicalData.sublist(max(0, i - 5), i);
      final avgLast5Days = recentData.isNotEmpty
          ? recentData.map((d) => d.temperature).reduce((a, b) => a + b) / recentData.length
          : null;
      final trendLast5Days = recentData.length > 1
          ? recentData.last.temperature - recentData.first.temperature
          : null;

      final prediction = model.predict(DataFrame([
        ['temperature', 'avgLast5Days', 'trendLast5Days'],
        [currentDay.temperature, avgLast5Days, trendLast5Days],
      ]));

      final predictedPhase = prediction.rows.first.first.toInt();
      currentDay.cyclePhase = CyclePhaseType.values[predictedPhase];
    }

    return historicalData;
  }
}


class CycleProvider {



  
}