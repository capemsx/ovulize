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
    final List<List<dynamic>> sampleData = [
      ['tempDiffFromBaseline', 'trendLast3Days', 'trendLast7Days', 'daysFromCycleStart', 'phase'],
      // Menstruation
      [-0.1, -0.05, -0.05, 1, 0],
      [-0.1, -0.02, -0.03, 3, 0],
      [-0.05, 0.0, -0.01, 5, 0],
      // Follicular phase
      [-0.2, -0.05, -0.03, 7, 1],
      [-0.2, 0.0, -0.01, 10, 1],
      [-0.1, 0.05, 0.02, 13, 1],
      // Ovulation 
      [0.1, 0.15, 0.05, 14, 2],
      [0.3, 0.25, 0.1, 15, 2],
      [0.5, 0.15, 0.15, 16, 2],
      // Luteal phase
      [0.5, 0.05, 0.2, 17, 3],
      [0.4, 0.0, 0.15, 22, 3],
      [0.2, -0.05, 0.05, 27, 3],
    ];
    
    final List<List<dynamic>> balancedData = [sampleData[0]];
    
    for (int phaseIndex = 0; phaseIndex < 4; phaseIndex++) {
      int startIdx = 1 + (phaseIndex * 3);
      int endIdx = startIdx + 2;
      
      for (int i = startIdx; i <= endIdx; i++) {
        balancedData.add(List.from(sampleData[i]));
        
        int variations = phaseIndex == 2 ? 4 : 2;
        for (int j = 0; j < variations; j++) {
          balancedData.add(_addVariation(List.from(sampleData[i])));
        }
      }
    }

    trainingData = DataFrame(balancedData, headerExists: true);
    _trainModel();
  }
  
  List<dynamic> _addVariation(List<dynamic> data) {
    final rand = Random();
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] is num) {
        data[i] = (data[i] as num) + (rand.nextDouble() * 0.12 - 0.06); //+-0.06
      }
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
    final cycleStartDate = _findCycleStartDate(data);
    
    if (_lastCycleStart != null && 
        cycleStartDate != null && 
        cycleStartDate != _lastCycleStart) {
      _updateCycleLength(cycleStartDate);
    }
    
    return _determinePhases(data, cycleStartDate);
  }
  
  double _calculateBaselineTemperature(List<TemperatureDay> data) {
    if (data.isEmpty) return 36.5;
    
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
               data[startIdx - 1].cyclePhase == CyclePhaseType.menstruation && //find most recent menstruation
               data[startIdx].date.difference(data[startIdx - 1].date).inDays <= 3) {
          startIdx--;
        }
        
        _lastCycleStart = data[startIdx].date;
        return data[startIdx].date;
      }
    }
    
    return data.first.date;
  }
  
  void _updateCycleLength(DateTime newCycleStart) {
    if (_lastCycleStart == null) return;
    
    final cycleDuration = newCycleStart.difference(_lastCycleStart!).inDays;
    if (cycleDuration >= 21 && cycleDuration <= 40) {
      _recentCycleLengths.add(cycleDuration);
      
      if (_recentCycleLengths.length > 5) {
        _recentCycleLengths.removeAt(0);
      }
      
      if (_recentCycleLengths.isNotEmpty) {
        int sum = _recentCycleLengths.reduce((a, b) => a + b);
        averageCycleLength = sum ~/ _recentCycleLengths.length;
        _updatePhaseDistribution();
      }
    }
    
    _lastCycleStart = newCycleStart;
  }
  
  void _updatePhaseDistribution() {
    _lutealLength = 13;
    _menstruationLength = 5;
    _ovulationLength = 3;
    _follicularLength = averageCycleLength - (_menstruationLength + _ovulationLength + _lutealLength); //most variable phase
    _follicularLength = max(5, _follicularLength);
  }
  
  double _calculateTrend(List<double> temperatures, [int maxDays = 3]) {
    if (temperatures.length <= 1) return 0.0;
    
    final daysToConsider = min(maxDays, temperatures.length);
    final recentTemps = temperatures.sublist(temperatures.length - daysToConsider);
    
    if (recentTemps.length >= 3) {
      double weightedSum = 0;
      double weights = 0;
      
      for (int i = 0; i < recentTemps.length - 1; i++) {
        final weight = i + 1;
        weightedSum += (recentTemps[i + 1] - recentTemps[i]) * weight;
        weights += weight;
      }
      //weighted to improve importance of most recent values
      
      return weights > 0 ? weightedSum / weights : 0;
    }
    
    return recentTemps.last - recentTemps.first;
  }
  
  List<TemperatureDay> _determinePhases(
    List<TemperatureDay> data, 
    DateTime? cycleStartDate
  ) {
    if (data.isEmpty) return [];
    cycleStartDate ??= data.first.date;
    
    final result = <TemperatureDay>[];
    
    for (int i = 0; i < data.length; i++) {
      final day = data[i];
      
      // Calculate features for ML model
      final tempDiff = day.temperature - (baselineTemperature ?? 36.5);
      
      double trendShort = 0;
      double trendLong = 0;
      
      if (i > 0) {
        final shortWindow = data.sublist(max(0, i - min(i, 3)), i + 1);
        final longWindow = data.sublist(max(0, i - min(i, 7)), i + 1);
        
        trendShort = _calculateTrend(shortWindow.map((d) => d.temperature).toList());
        trendLong = _calculateTrend(longWindow.map((d) => d.temperature).toList(), 7);
      }
      
      final daysFromStart = day.date.difference(cycleStartDate).inDays % averageCycleLength + 1;
      
      // Only predict phase if not manually set
      CyclePhaseType detectedPhase = day.cyclePhase;
      
      if (detectedPhase == CyclePhaseType.uncertain && model != null && isModelTrained) {
        try {
          final prediction = model!.predict(DataFrame([
            ['tempDiffFromBaseline', 'trendLast3Days', 'trendLast7Days', 'daysFromCycleStart'],
            [tempDiff, trendShort, trendLong, daysFromStart],
          ]));
          
          final mlPhase = prediction.rows.first.first.toInt();
          
          if (mlPhase >= 0 && mlPhase < CyclePhaseType.values.length) {
            detectedPhase = CyclePhaseType.values[mlPhase];
          }
        } catch (e) {
          // Fallback if ML fails - use calendar method
          if (daysFromStart <= _menstruationLength) {
            detectedPhase = CyclePhaseType.menstruation;
          } else if (daysFromStart <= _menstruationLength + _follicularLength) {
            detectedPhase = CyclePhaseType.follicular;
          } else if (daysFromStart <= _menstruationLength + _follicularLength + _ovulationLength) {
            detectedPhase = CyclePhaseType.ovulation;
          } else {
            detectedPhase = CyclePhaseType.luteal;
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
        cyclePhase: detectedPhase,
      ));
    }
    
    return result;
  }
  
  List<TemperatureDay> predictFutureCyclePhases(
      List<TemperatureDay> historicalData, int monthsInFuture) {
    if (historicalData.isEmpty) return [];
    
    List<TemperatureDay> analyzedData = analyzeCurrentCycle(historicalData);
    
    DateTime lastDate = analyzedData.last.date;
    DateTime cycleStartDate = _findCycleStartDate(analyzedData) ?? lastDate;
    
    Map<int, CyclePhaseType> cyclePattern = _createCyclePattern();
    
    return _generateFutureDays(analyzedData, cycleStartDate, cyclePattern, monthsInFuture);
  }
  
  Map<int, CyclePhaseType> _createCyclePattern() {
    final Map<int, CyclePhaseType> pattern = {};
    
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
  
  List<TemperatureDay> _generateFutureDays(
      List<TemperatureDay> analyzedData,
      DateTime cycleStartDate,
      Map<int, CyclePhaseType> cyclePattern,
      int monthsInFuture) {
      
    List<TemperatureDay> allData = List.from(analyzedData);
    int daysToPredict = monthsInFuture * 30;
    DateTime currentCycleStart = cycleStartDate;
    
    for (int i = 0; i < daysToPredict; i++) {
      final nextDate = allData.last.date.add(const Duration(days: 1));
      
      final daysFromStart = nextDate.difference(currentCycleStart).inDays % averageCycleLength + 1;
      final phase = cyclePattern[daysFromStart] ?? CyclePhaseType.uncertain;
      
      final temperatureValues = _generateTemperatureForPhase(
        phase, 
        daysFromStart, 
        baselineTemperature ?? 36.5
      );
      
      final nextDay = TemperatureDay(
        date: nextDate,
        temperature: temperatureValues.temp,
        tempDiffFromBaseline: temperatureValues.diff,
        trendLast3Days: temperatureValues.trendShort,
        trendLast7Days: temperatureValues.trendLong,
        daysFromCycleStart: daysFromStart,
        cyclePhase: phase,
      );
      
      allData.add(nextDay);
      
      if (daysFromStart == averageCycleLength) {
        currentCycleStart = nextDate.add(const Duration(days: 1));
      }
    }
    
    return allData;
  }
  
  //bunch of hardcode :((
  _TemperatureValues _generateTemperatureForPhase(
      CyclePhaseType phase, int daysFromStart, double baseline) {
    
    double tempDiff = 0.0;
    double trendShort = 0.0;
    double trendLong = 0.0;
    final rand = Random();
    
    switch (phase) {
      case CyclePhaseType.menstruation:
        double progress = daysFromStart / _menstruationLength;
        tempDiff = -0.15 + progress * 0.1 + (rand.nextDouble() * 0.08 - 0.04);
        trendShort = -0.05 + progress * 0.1;
        trendLong = -0.02 + progress * 0.02;
        break;
        
      case CyclePhaseType.follicular:
        double relativePos = (daysFromStart - _menstruationLength) / _follicularLength;
        tempDiff = -0.2 + relativePos * 0.2 + (rand.nextDouble() * 0.06 - 0.03);
        trendShort = 0.0 + relativePos * 0.1;
        trendLong = 0.01 + relativePos * 0.03;
        break;
        
      case CyclePhaseType.ovulation:
        double ovuProgress = (daysFromStart - (_menstruationLength + _follicularLength)) / _ovulationLength;
        
        if (ovuProgress < 0.33) {
          tempDiff = -0.1 + (rand.nextDouble() * 0.05);
          trendShort = -0.1;
        } else if (ovuProgress < 0.66) {
          tempDiff = 0.1 + (rand.nextDouble() * 0.1);
          trendShort = 0.2;
        } else {
          tempDiff = 0.3 + (rand.nextDouble() * 0.1);
          trendShort = 0.2;
        }
        trendLong = 0.1;
        break;
        
      case CyclePhaseType.luteal:
        double lutealProgress = (daysFromStart - (_menstruationLength + _follicularLength + _ovulationLength)) / _lutealLength;
        tempDiff = 0.4 - lutealProgress * 0.3 + (rand.nextDouble() * 0.08 - 0.04);
        trendShort = (rand.nextDouble() * 0.08 - 0.04) - lutealProgress * 0.1;
        trendLong = -0.05 * lutealProgress;
        break;
        
      case CyclePhaseType.uncertain:
      default:
        tempDiff = 0.0;
        trendShort = 0.0;
        trendLong = 0.0;
    }
    
    final temperature = baseline + tempDiff;
    
    return _TemperatureValues(
      temp: double.parse(temperature.toStringAsFixed(2)),
      diff: double.parse(tempDiff.toStringAsFixed(2)),
      trendShort: double.parse(trendShort.toStringAsFixed(2)),
      trendLong: double.parse(trendLong.toStringAsFixed(2))
    );
  }
  
  void updateModelWithNewData(TemperatureDay day) {
    if (trainingData == null) return;
    
    if (day.cyclePhase != CyclePhaseType.uncertain) {
      baselineTemperature ??= day.temperature;
      
      final tempDiff = day.temperature - baselineTemperature!;
      final cycleStartDate = _lastCycleStart ?? day.date;
      final daysFromStart = day.date.difference(cycleStartDate).inDays % averageCycleLength + 1;
      
      final newData = DataFrame([
        ['tempDiffFromBaseline', 'trendLast3Days', 'trendLast7Days', 'daysFromCycleStart', 'phase'],
        [
          tempDiff,
          day.trendLast3Days ?? 0.0,
          day.trendLast7Days ?? 0.0,
          daysFromStart,
          CyclePhaseType.values.indexOf(day.cyclePhase)
        ],
      ], headerExists: true);
      
      trainingData = DataFrame(
        [...trainingData!.rows, ...newData.rows.skip(1)], 
        headerExists: true
      );
      
      _trainModel();
    }
  }
}

class _TemperatureValues {
  final double temp;
  final double diff;
  final double trendShort;
  final double trendLong;
  
  _TemperatureValues({
    required this.temp, 
    required this.diff,
    required this.trendShort,
    required this.trendLong
  });
}