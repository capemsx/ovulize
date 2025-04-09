import 'dart:math';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ovulize/backend/types/cyclephase.dart';
import 'package:ovulize/backend/types/cyclephasetype.dart';

class TemperatureDay {
  final DateTime date;
  final double temperature;
  final double? tempDiffFromBaseline;
  final double? trendLast3Days;
  final double? trendLast7Days;
  final int? daysFromCycleStart;
  CyclePhaseType cyclePhase;

  TemperatureDay({
    required this.date,
    required this.temperature,
    this.tempDiffFromBaseline,
    this.trendLast3Days,
    this.trendLast7Days,
    this.daysFromCycleStart,
    this.cyclePhase = CyclePhaseType.uncertain,
  });
}

class CyclePhasePredictor {
  LogisticRegressor? model;
  DataFrame? trainingData;
  bool isModelTrained = false;
  int averageCycleLength = 28;
  double? baselineTemperature;
  DateTime? _lastCycleStart;
  List<int> _recentCycleLengths = [];
  int _menstruationLength = 5;
  int _follicularLength = 8;
  int _ovulationLength = 3;
  int _lutealLength = 12;

  CyclePhasePredictor() {
    _initializeModel();
  }

  void _initializeModel() {
    final sampleData = [
      ['tempDiffFromBaseline', 'trendLast3Days', 'trendLast7Days', 'daysFromCycleStart', 'phase'],
      [-0.1, -0.05, -0.05, 1, 0], [-0.1, -0.02, -0.03, 3, 0], [-0.05, 0.0, -0.01, 5, 0],
      [-0.2, -0.05, -0.03, 7, 1], [-0.2, 0.0, -0.01, 10, 1], [-0.1, 0.05, 0.02, 13, 1],
      [0.1, 0.15, 0.05, 14, 2], [0.3, 0.25, 0.1, 15, 2], [0.5, 0.15, 0.15, 16, 2],
      [0.5, 0.05, 0.2, 17, 3], [0.4, 0.0, 0.15, 22, 3], [0.2, -0.05, 0.05, 27, 3],
    ];

    final balancedData = [sampleData[0]];
    for (int i = 0; i < 4; i++) {
      for (int j = 1 + (i * 3); j <= 3 + (i * 3); j++) {
        balancedData.add(List.from(sampleData[j]));
        int variations = i == 2 ? 4 : 2;
        for (int k = 0; k < variations; k++) {
          balancedData.add(_addVariation(List.from(sampleData[j])));
        }
      }
    }

    trainingData = DataFrame(balancedData, headerExists: true);
    _trainModel();
  }

   List<Object> _addVariation(List<Object> data) {
    final rand = Random();
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] is num) data[i] = (data[i] as num) + (rand.nextDouble() * 0.12 - 0.06);
    }
    return data;
  }

  void _trainModel() {
    if (trainingData == null) return;
    model = LogisticRegressor(trainingData!, "phase",
        optimizerType: LinearOptimizerType.gradient,
        iterationsLimit: 2000,
        learningRateType: LearningRateType.constant,
        initialLearningRate: 0.03,
        fitIntercept: true);
    isModelTrained = true;
  }

  List<TemperatureDay> analyzeCurrentCycle(List<TemperatureDay> rawData) {
    if (rawData.isEmpty) return [];
    
    final data = List<TemperatureDay>.from(rawData)..sort((a, b) => a.date.compareTo(b.date));
    baselineTemperature = _calculateBaselineTemperature(data);
    _preProcessPhaseDetection(data);
    
    final cycleStartDate = _findCycleStartDate(data);
    if (_lastCycleStart != null && cycleStartDate != null && cycleStartDate != _lastCycleStart) {
      _updateCycleLength(cycleStartDate);
    }
    
    return _determinePhases(data, cycleStartDate);
  }

  void _preProcessPhaseDetection(List<TemperatureDay> data) {
    if (data.length < 7) return;
    
    double recentAvg = 0;
    int count = 0;
    
    for (int i = data.length - 1; i >= max(0, data.length - 7); i--) {
      recentAvg += data[i].temperature;
      count++;
    }
    recentAvg /= count;

    for (int i = data.length - 1; i >= max(0, data.length - 4); i--) {
      if (data[i].cyclePhase == CyclePhaseType.uncertain) {
        if (data[i].temperature >= baselineTemperature! + 0.3) {
          data[i].cyclePhase = CyclePhaseType.luteal;
        } else if (i > 0 && i < data.length - 1 && 
                  data[i].temperature < baselineTemperature! - 0.2 &&
                  data[i+1].temperature > data[i].temperature + 0.2) {
          data[i].cyclePhase = CyclePhaseType.ovulation;
        }
      }
    }
  }

  double _calculateBaselineTemperature(List<TemperatureDay> data) {
    if (data.isEmpty || data.length < 3) return 36.5;
    final temps = data.map((d) => d.temperature).toList()..sort();
    final cutpoint = max(3, temps.length ~/ 3);
    return temps.sublist(0, cutpoint).reduce((a, b) => a + b) / cutpoint;
  }

  DateTime? _findCycleStartDate(List<TemperatureDay> data) {
    if (data.isEmpty) return null;

    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i].cyclePhase == CyclePhaseType.menstruation) {
        int startIdx = i;
        while (startIdx > 0 &&
               data[startIdx - 1].cyclePhase == CyclePhaseType.menstruation &&
               data[startIdx].date.difference(data[startIdx - 1].date).inDays <= 3) {
          startIdx--;
        }
        _lastCycleStart = data[startIdx].date;
        return data[startIdx].date;
      }
    }

    List<int> potentialStartIndices = [];
    for (int i = 1; i < data.length; i++) {
      if (i > 1 && data[i].temperature < data[i - 1].temperature && 
          data[i].temperature < baselineTemperature!) {
        potentialStartIndices.add(i);
      }
    }

    if (potentialStartIndices.isNotEmpty) {
      int lastStart = potentialStartIndices.last;
      _lastCycleStart = data[lastStart].date;
      
      for (int j = lastStart; j < data.length && j < lastStart + 5; j++) {
        if (j < data.length && data[j].cyclePhase == CyclePhaseType.uncertain) {
          data[j].cyclePhase = CyclePhaseType.menstruation;
        }
      }
      return data[lastStart].date;
    }

    _lastCycleStart = data.first.date;
    return data.first.date;
  }

  void _updateCycleLength(DateTime newCycleStart) {
    if (_lastCycleStart == null) return;
    final cycleDuration = newCycleStart.difference(_lastCycleStart!).inDays;
    if (cycleDuration >= 21 && cycleDuration <= 40) {
      _recentCycleLengths.add(cycleDuration);
      if (_recentCycleLengths.length > 5) _recentCycleLengths.removeAt(0);
      if (_recentCycleLengths.isNotEmpty) {
        averageCycleLength = _recentCycleLengths.reduce((a, b) => a + b) ~/ _recentCycleLengths.length;
        _updatePhaseDistribution();
      }
    }
    _lastCycleStart = newCycleStart;
  }

  void _updatePhaseDistribution() {
    _lutealLength = 13;
    _menstruationLength = 5;
    _ovulationLength = 3;
    _follicularLength = averageCycleLength - (_menstruationLength + _ovulationLength + _lutealLength);
    _follicularLength = max(5, _follicularLength);
  }

  double _calculateTrend(List<double> temps, [int maxDays = 3]) {
    if (temps.length <= 1) return 0.0;
    final days = min(maxDays, temps.length);
    final recent = temps.sublist(temps.length - days);
    
    if (recent.length >= 3) {
      double wSum = 0, weights = 0;
      for (int i = 0; i < recent.length - 1; i++) {
        final w = i + 1;
        wSum += (recent[i + 1] - recent[i]) * w;
        weights += w;
      }
      return weights > 0 ? wSum / weights : 0;
    }
    return recent.last - recent.first;
  }

  List<TemperatureDay> _determinePhases(List<TemperatureDay> data, DateTime? cycleStartDate) {
    if (data.isEmpty) return [];
    cycleStartDate ??= data.first.date;
    final result = <TemperatureDay>[];

    for (int i = 0; i < data.length; i++) {
      final day = data[i];
      final tempDiff = day.temperature - (baselineTemperature ?? 36.5);
      double trendShort = 0, trendLong = 0;

      if (i > 0) {
        final shortWindow = data.sublist(max(0, i - min(i, 3)), i + 1);
        final longWindow = data.sublist(max(0, i - min(i, 7)), i + 1);
        trendShort = _calculateTrend(shortWindow.map((d) => d.temperature).toList());
        trendLong = _calculateTrend(longWindow.map((d) => d.temperature).toList(), 7);
      }

      final daysFromStart = day.date.difference(cycleStartDate).inDays % averageCycleLength + 1;
      CyclePhaseType phase = day.cyclePhase;

      if (phase == CyclePhaseType.uncertain && model != null && isModelTrained) {
        try {
          final prediction = model!.predict(DataFrame([
            ['tempDiffFromBaseline', 'trendLast3Days', 'trendLast7Days', 'daysFromCycleStart'],
            [tempDiff, trendShort, trendLong, daysFromStart],
          ]));
          final mlPhase = prediction.rows.first.first.toInt();
          if (mlPhase >= 0 && mlPhase < CyclePhaseType.values.length) {
            phase = CyclePhaseType.values[mlPhase];
          }
        } catch (e) {
          // Fallback to calendar
          if (daysFromStart <= _menstruationLength) {
            phase = CyclePhaseType.menstruation;
          } else if (daysFromStart <= _menstruationLength + _follicularLength) {
            phase = CyclePhaseType.follicular;
          } else if (daysFromStart <= _menstruationLength + _follicularLength + _ovulationLength) {
            phase = CyclePhaseType.ovulation;
          } else {
            phase = CyclePhaseType.luteal;
          }
        }
      }

      result.add(TemperatureDay(
        date: day.date,
        temperature: day.temperature,
        tempDiffFromBaseline: tempDiff,
        trendLast3Days: trendShort,
        trendLast7Days: trendLong,
        daysFromCycleStart: daysFromStart,
        cyclePhase: phase,
      ));
    }
    return result;
  }

  List<TemperatureDay> predictFutureCyclePhases(List<TemperatureDay> history, int months) {
    if (history.isEmpty) return [];
    List<TemperatureDay> analyzed = analyzeCurrentCycle(history);
    DateTime cycleStart = _findCycleStartDate(analyzed) ?? analyzed.last.date;
    Map<int, CyclePhaseType> pattern = _createCyclePattern();
    return _generateFutureDays(analyzed, cycleStart, pattern, months);
  }

  Map<int, CyclePhaseType> _createCyclePattern() {
    final pattern = <int, CyclePhaseType>{};
    for (int day = 1; day <= averageCycleLength; day++) {
      if (day <= _menstruationLength) {
        pattern[day] = CyclePhaseType.menstruation;
      } else if (day <= _menstruationLength + _follicularLength) {
        pattern[day] = CyclePhaseType.follicular;
      } else if (day <= _menstruationLength + _follicularLength + _ovulationLength) {
        pattern[day] = CyclePhaseType.ovulation;
      } else {
        pattern[day] = CyclePhaseType.luteal;
      }
    }
    return pattern;
  }

  List<TemperatureDay> _generateFutureDays(List<TemperatureDay> data, DateTime cycleStart, 
      Map<int, CyclePhaseType> pattern, int months) {
    List<TemperatureDay> all = List.from(data);
    DateTime currentStart = cycleStart;

    for (int i = 0; i < months * 30; i++) {
      final next = all.last.date.add(const Duration(days: 1));
      final days = next.difference(currentStart).inDays % averageCycleLength + 1;
      final phase = pattern[days] ?? CyclePhaseType.uncertain;
      final values = _generateTempValues(phase, days, baselineTemperature ?? 36.5);
      
      all.add(TemperatureDay(
        date: next,
        temperature: values.temp,
        tempDiffFromBaseline: values.diff,
        trendLast3Days: values.trendShort,
        trendLast7Days: values.trendLong,
        daysFromCycleStart: days,
        cyclePhase: phase,
      ));

      if (days == averageCycleLength) {
        currentStart = next.add(const Duration(days: 1));
      }
    }
    return all;
  }

  _TempValues _generateTempValues(CyclePhaseType phase, int days, double baseline) {
    final rand = Random();
    double diff = 0, trendS = 0, trendL = 0;
    
    switch (phase) {
      case CyclePhaseType.menstruation:
        double p = days / _menstruationLength;
        diff = -0.15 + p * 0.1 + (rand.nextDouble() * 0.08 - 0.04);
        trendS = -0.05 + p * 0.1;
        trendL = -0.02 + p * 0.02;
        break;
      case CyclePhaseType.follicular:
        double p = (days - _menstruationLength) / _follicularLength;
        diff = -0.2 + p * 0.2 + (rand.nextDouble() * 0.06 - 0.03);
        trendS = 0.0 + p * 0.1;
        trendL = 0.01 + p * 0.03;
        break;
      case CyclePhaseType.ovulation:
        double p = (days - (_menstruationLength + _follicularLength)) / _ovulationLength;
        if (p < 0.33) {
          diff = -0.1 + (rand.nextDouble() * 0.05);
          trendS = -0.1;
        } else if (p < 0.66) {
          diff = 0.1 + (rand.nextDouble() * 0.1);
          trendS = 0.2;
        } else {
          diff = 0.3 + (rand.nextDouble() * 0.1);
          trendS = 0.2;
        }
        trendL = 0.1;
        break;
      case CyclePhaseType.luteal:
        double p = (days - (_menstruationLength + _follicularLength + _ovulationLength)) / _lutealLength;
        diff = 0.4 - p * 0.3 + (rand.nextDouble() * 0.08 - 0.04);
        trendS = (rand.nextDouble() * 0.08 - 0.04) - p * 0.1;
        trendL = -0.05 * p;
        break;
      default:
        break;
    }

    final temp = baseline + diff;
    return _TempValues(
      temp: double.parse(temp.toStringAsFixed(2)),
      diff: double.parse(diff.toStringAsFixed(2)),
      trendShort: double.parse(trendS.toStringAsFixed(2)),
      trendLong: double.parse(trendL.toStringAsFixed(2))
    );
  }

  void updateModelWithNewData(TemperatureDay day) {
    if (trainingData == null || day.cyclePhase == CyclePhaseType.uncertain) return;
    
    baselineTemperature ??= day.temperature;
    final diff = day.temperature - baselineTemperature!;
    final cycleStart = _lastCycleStart ?? day.date;
    final days = day.date.difference(cycleStart).inDays % averageCycleLength + 1;
    
    final newData = DataFrame([
      ['tempDiffFromBaseline', 'trendLast3Days', 'trendLast7Days', 'daysFromCycleStart', 'phase'],
      [diff, day.trendLast3Days ?? 0.0, day.trendLast7Days ?? 0.0, days, 
       CyclePhaseType.values.indexOf(day.cyclePhase)],
    ], headerExists: true);
    
    trainingData = DataFrame([...trainingData!.rows, ...newData.rows.skip(1)], headerExists: true);
    _trainModel();
  }
}

class _TempValues {
  final double temp;
  final double diff;
  final double trendShort;
  final double trendLong;

  _TempValues({required this.temp, required this.diff, 
              required this.trendShort, required this.trendLong});
}