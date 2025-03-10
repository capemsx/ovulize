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
  // Machine-Learning-Modell
  LogisticRegressor? model;
  DataFrame? trainingData;
  bool isModelTrained = false;
  
  // Zyklusparameter
  int averageCycleLength = 28;
  double? baselineTemperature;
  
  // Tracking der erkannten Zyklusdaten
  DateTime? _lastDetectedOvulation;
  DateTime? _lastCycleStart;
  List<int> _recentCycleLengths = [];
  
  // Phasenlängen
  int _menstruationLength = 5;
  int _follicularLength = 8;
  int _ovulationLength = 3;
  int _lutealLength = 12;
  
  // Parameter für Mustererkennung
  final double _ovulationRiseThreshold = 0.2;
  final double _menstruationDropThreshold = -0.3;

  CyclePhasePredictor() {
    _initializeModel();
  }

  // Initialisiert das ML-Modell mit Standarddaten
  void _initializeModel() {
    final List<List<dynamic>> sampleData = [
      ['tempDiffFromBaseline', 'trendLast3Days', 'trendLast7Days', 'daysFromCycleStart', 'phase'],
      
      // Menstruation - leicht unter Basislinie, sinkender Trend
      [-0.1, -0.05, -0.05, 1, 0],
      [-0.1, -0.02, -0.03, 3, 0],
      [-0.05, 0.0, -0.01, 5, 0],
      
      // Follikelphase - tiefste Temperaturen, später leichter Anstieg
      [-0.2, -0.05, -0.03, 7, 1],
      [-0.2, 0.0, -0.01, 10, 1],
      [-0.1, 0.05, 0.02, 13, 1],
      
      // Eisprung - abrupter Anstieg
      [0.1, 0.15, 0.05, 14, 2],
      [0.3, 0.25, 0.1, 15, 2],
      [0.5, 0.15, 0.15, 16, 2],
      
      // Lutealphase - erhöhte Temperatur mit leichtem Abwärtstrend zum Ende
      [0.5, 0.05, 0.2, 17, 3],
      [0.4, 0.0, 0.15, 22, 3],
      [0.2, -0.05, 0.05, 27, 3],
    ];
    
    final List<List<dynamic>> balancedData = [sampleData[0]];
    
    // Erstelle erweiterten Datensatz mit Variationen
    for (int phaseIndex = 0; phaseIndex < 4; phaseIndex++) {
      int startIdx = 1 + (phaseIndex * 3);
      int endIdx = startIdx + 2;
      
      for (int i = startIdx; i <= endIdx; i++) {
        balancedData.add(List.from(sampleData[i]));
        
        // Besonders wichtig: mehr Variationen für die kurze Ovulationsphase
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
        data[i] = (data[i] as num) + (rand.nextDouble() * 0.12 - 0.06);
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

  // SCHRITT 1: ANALYSE DES AKTUELLEN ZYKLUS UND PHASEBESTIMMUNG
  
  // Analysiert die Temperaturdaten und erkennt die aktuelle Zyklusphase
  List<TemperatureDay> analyzeCurrentCycle(List<TemperatureDay> rawData) {
    if (rawData.isEmpty) return [];
    
    // Vorbereitung der Daten
    final data = List<TemperatureDay>.from(rawData)..sort((a, b) => a.date.compareTo(b.date));
    
    // 1. Baseline-Temperatur berechnen
    baselineTemperature = _calculateBaselineTemperature(data);
    
    // 2. Zyklusstart finden
    final cycleStartDate = _findCycleStartDate(data);
    
    // 3. Ovulation detektieren
    final ovulationDate = _detectOvulation(data);
    
    // 4. Zykluslänge aktualisieren, wenn neuer Zyklus erkannt wurde
    if (_lastCycleStart != null && 
        cycleStartDate != null && 
        cycleStartDate != _lastCycleStart) {
      _updateCycleLength(cycleStartDate);
    }
    
    // 5. Alle Features berechnen und Phasen bestimmen
    return _determinePhases(data, cycleStartDate, ovulationDate);
  }
  
  // Berechnet die Baseline-Temperatur (unteres Drittel)
  double _calculateBaselineTemperature(List<TemperatureDay> data) {
    if (data.isEmpty) return 36.5; // Default
    
    final temps = data.map((d) => d.temperature).toList()..sort();
    
    // Unteres Drittel verwenden (bessere Repräsentation der Follikelphase)
    final cutpoint = max(3, temps.length ~/ 3);
    return temps.sublist(0, cutpoint).reduce((a, b) => a + b) / cutpoint;
  }
  
  // Findet den Beginn des aktuellen Zyklus
  DateTime? _findCycleStartDate(List<TemperatureDay> data) {
    if (data.isEmpty) return null;
    
    // 1. Suche nach manuell eingegebenen Menstruationstagen
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i].cyclePhase == CyclePhaseType.menstruation) {
        // Finde den ersten Tag dieser Menstruation
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
    
    // 2. Wenn keine manuellen Daten vorhanden sind, suche nach Temperaturmuster
    DateTime? probableCycleStart = _detectCycleStartFromTemperature(data);
    if (probableCycleStart != null) {
      return probableCycleStart;
    }
    
    // Fallback: erster Tag der Daten
    return data.first.date;
  }
  
  // Erkennt Zyklusbeginn anhand von typischem Temperaturabfall
  DateTime? _detectCycleStartFromTemperature(List<TemperatureDay> data) {
    if (data.length < 10) return null;
    
    // Suche nach deutlichem Temperaturabfall (typisch für Menstruationsbeginn)
    for (int i = data.length - 1; i >= 5; i--) {
      final tempDiff = data[i].temperature - data[max(0, i - 3)].temperature;
      
      if (tempDiff < _menstruationDropThreshold) {
        return data[i].date;
      }
    }
    
    return null;
  }
  
  // Erkennt Eisprung anhand des typischen Temperaturanstiegs
  DateTime? _detectOvulation(List<TemperatureDay> data) {
    if (data.length < 7) return null;
    
    // Typisches Muster: leichter Abfall gefolgt von deutlichem Anstieg
    for (int i = 2; i < data.length - 2; i++) {
      final prevTemp = data[i - 1].temperature;
      final currTemp = data[i].temperature;
      final nextTemp = data[i + 1].temperature;
      final afterNextTemp = data[min(data.length - 1, i + 2)].temperature;
      
      final dropBeforeRise = prevTemp > currTemp;
      final significantRise = (nextTemp - currTemp) >= (_ovulationRiseThreshold / 2) &&
                              (afterNextTemp - currTemp) >= _ovulationRiseThreshold;
      
      if (dropBeforeRise && significantRise) {
        _lastDetectedOvulation = data[i].date;
        return data[i].date;
      }
    }
    
    return null;
  }
  
  // Aktualisiert die Zykluslänge basierend auf neuen Daten
  void _updateCycleLength(DateTime newCycleStart) {
    if (_lastCycleStart == null) return;
    
    final cycleDuration = newCycleStart.difference(_lastCycleStart!).inDays;
    if (cycleDuration >= 21 && cycleDuration <= 40) {
      _recentCycleLengths.add(cycleDuration);
      
      // Maximum 5 historische Längen speichern
      if (_recentCycleLengths.length > 5) {
        _recentCycleLengths.removeAt(0);
      }
      
      // Durchschnitt berechnen
      if (_recentCycleLengths.isNotEmpty) {
        int sum = _recentCycleLengths.reduce((a, b) => a + b);
        averageCycleLength = sum ~/ _recentCycleLengths.length;
        _updatePhaseDistribution();
      }
    }
    
    _lastCycleStart = newCycleStart;
  }
  
  // Aktualisiert die Länge der einzelnen Zyklusphasen
  void _updatePhaseDistribution() {
    // Lutealphase bleibt annähernd konstant (typischerweise 12-14 Tage)
    _lutealLength = 13;
    
    // Typische Menstruationsphase
    _menstruationLength = 5;
    
    // Typische Ovulationsphase
    _ovulationLength = 3;
    
    // Follikelphase als Rest
    _follicularLength = averageCycleLength - (_menstruationLength + _ovulationLength + _lutealLength);
    _follicularLength = max(5, _follicularLength);
  }
  
  // Berechnet Trends für die Temperaturanalyse
  double _calculateTrend(List<double> temperatures, [int maxDays = 3]) {
    if (temperatures.length <= 1) return 0.0;
    
    final daysToConsider = min(maxDays, temperatures.length);
    final recentTemps = temperatures.sublist(temperatures.length - daysToConsider);
    
    if (recentTemps.length >= 3) {
      // Gewichteter Trend (neuere Werte wichtiger)
      double weightedSum = 0;
      double weights = 0;
      
      for (int i = 0; i < recentTemps.length - 1; i++) {
        final weight = i + 1;
        weightedSum += (recentTemps[i + 1] - recentTemps[i]) * weight;
        weights += weight;
      }
      
      return weights > 0 ? weightedSum / weights : 0;
    }
    
    // Einfache Differenz als Fallback
    return recentTemps.last - recentTemps.first;
  }
  
  // Berechnet alle Features und bestimmt die Zyklusphase jedes Tages
  List<TemperatureDay> _determinePhases(
    List<TemperatureDay> data, 
    DateTime? cycleStartDate,
    DateTime? ovulationDate
  ) {
    if (data.isEmpty) return [];
    cycleStartDate ??= data.first.date;
    
    final result = <TemperatureDay>[];
    
    for (int i = 0; i < data.length; i++) {
      final day = data[i];
      
      // Temperaturdifferenz zur Baseline berechnen
      final tempDiff = day.temperature - (baselineTemperature ?? 36.5);
      
      // Kurzfristigen und langfristigen Trend berechnen
      double trendShort = 0;
      double trendLong = 0;
      
      if (i > 0) {
        final shortWindow = data.sublist(max(0, i - min(i, 3)), i + 1);
        final longWindow = data.sublist(max(0, i - min(i, 7)), i + 1);
        
        trendShort = _calculateTrend(shortWindow.map((d) => d.temperature).toList());
        trendLong = _calculateTrend(longWindow.map((d) => d.temperature).toList(), 7);
      }
      
      // Berechne relative Position im Zyklus
      final daysFromStart = day.date.difference(cycleStartDate).inDays % averageCycleLength + 1;
      
      // Bestimme Zyklusphase basierend auf Mustererkennung
      CyclePhaseType detectedPhase = day.cyclePhase;
      
      // Nur automatisch bestimmen, wenn nicht manuell gesetzt
      if (detectedPhase == CyclePhaseType.uncertain) {
        if (ovulationDate != null) {
          // Wenn Ovulation erkannt wurde, beziehe Phasen darauf
          final daysFromOvulation = day.date.difference(ovulationDate).inDays;
          
          if (daysFromOvulation >= -1 && daysFromOvulation <= 1) {
            detectedPhase = CyclePhaseType.ovulation;
          } else if (daysFromOvulation > 1) {
            detectedPhase = CyclePhaseType.luteal;
          } else if (daysFromStart <= _menstruationLength) {
            detectedPhase = CyclePhaseType.menstruation;
          } else {
            detectedPhase = CyclePhaseType.follicular;
          }
        } else {
          // Ohne erkannte Ovulation: Standard-Schema nach Kalendertagen
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
      
      // ML-Modell zur Bestätigung/Korrektur verwenden, wenn verfügbar
      if (model != null && isModelTrained) {
        try {
          final prediction = model!.predict(DataFrame([
            ['tempDiffFromBaseline', 'trendLast3Days', 'trendLast7Days', 'daysFromCycleStart'],
            [tempDiff, trendShort, trendLong, daysFromStart],
          ]));
          
          final mlPhase = prediction.rows.first.first.toInt();
          
          // Nur übernehmen, wenn nicht manuell gesetzt und hohe Konfidenz
          if (day.cyclePhase == CyclePhaseType.uncertain && 
              mlPhase >= 0 && mlPhase < CyclePhaseType.values.length) {
            detectedPhase = CyclePhaseType.values[mlPhase];
          }
        } catch (e) {
          // Ignoriere ML-Fehler, behalte regelbasierte Entscheidung
        }
      }
      
      // Neuen Tag mit berechneten Features erstellen
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
  
  // SCHRITT 2: PROJEKTION DES ERKANNTEN MUSTERS IN DIE ZUKUNFT
  
  // Hauptmethode für die Vorhersage zukünftiger Zyklen
  List<TemperatureDay> predictFutureCyclePhases(
      List<TemperatureDay> historicalData, int monthsInFuture) {
    if (historicalData.isEmpty) return [];
    
    // 1. Analysiere bisherige Daten, um Muster zu erkennen
    List<TemperatureDay> analyzedData = analyzeCurrentCycle(historicalData);
    
    // 2. Wichtige Parameter für die Vorhersage ermitteln
    DateTime lastDate = analyzedData.last.date;
    DateTime cycleStartDate = _findCycleStartDate(analyzedData) ?? lastDate;
    
    // 3. Phasenmuster für Projektion erzeugen
    Map<int, CyclePhaseType> cyclePattern = _createCyclePattern();
    
    // 4. Zukünftige Tage mit dem erkannten Muster projizieren
    return _generateFutureDays(analyzedData, cycleStartDate, cyclePattern, monthsInFuture);
  }
  
  // Erstellt ein Muster der Zyklusphasen basierend auf aktuellen Parametern
  Map<int, CyclePhaseType> _createCyclePattern() {
    final Map<int, CyclePhaseType> pattern = {};
    
    // Phasen zuordnen basierend auf aktuellen Phasenlängen
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
  
  // Generiert zukünftige Tage basierend auf dem erkannten Muster
  List<TemperatureDay> _generateFutureDays(
      List<TemperatureDay> analyzedData,
      DateTime cycleStartDate,
      Map<int, CyclePhaseType> cyclePattern,
      int monthsInFuture) {
      
    List<TemperatureDay> allData = List.from(analyzedData);
    int daysToPredict = monthsInFuture * 30;
    DateTime currentCycleStart = cycleStartDate;
    
    for (int i = 0; i < daysToPredict; i++) {
      // Nächstes Datum
      final nextDate = allData.last.date.add(const Duration(days: 1));
      
      // Position im Zyklus berechnen
      final daysFromStart = nextDate.difference(currentCycleStart).inDays % averageCycleLength + 1;
      
      // Phase basierend auf dem erkannten Muster bestimmen
      final phase = cyclePattern[daysFromStart] ?? CyclePhaseType.uncertain;
      
      // Temperaturwerte basierend auf der Phase erzeugen
      final temperatureValues = _generateTemperatureForPhase(
        phase, 
        daysFromStart, 
        baselineTemperature ?? 36.5
      );
      
      // Neuen Tag erzeugen
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
      
      // Neuen Zyklus beginnen
      if (daysFromStart == averageCycleLength) {
        currentCycleStart = nextDate.add(const Duration(days: 1));
      }
    }
    
    return allData;
  }
  
  // Generiert realistische Temperaturwerte für die jeweilige Phase
  _TemperatureValues _generateTemperatureForPhase(
      CyclePhaseType phase, int daysFromStart, double baseline) {
    
    double tempDiff = 0.0;
    double trendShort = 0.0;
    double trendLong = 0.0;
    final rand = Random();
    
    switch (phase) {
      case CyclePhaseType.menstruation:
        // Tiefere Temperatur, leicht ansteigend gegen Ende
        double progress = daysFromStart / _menstruationLength;
        tempDiff = -0.15 + progress * 0.1 + (rand.nextDouble() * 0.08 - 0.04);
        trendShort = -0.05 + progress * 0.1;
        trendLong = -0.02 + progress * 0.02;
        break;
        
      case CyclePhaseType.follicular:
        // Niedrig, dann langsam ansteigend
        double relativePos = (daysFromStart - _menstruationLength) / _follicularLength;
        tempDiff = -0.2 + relativePos * 0.2 + (rand.nextDouble() * 0.06 - 0.03);
        trendShort = 0.0 + relativePos * 0.1;
        trendLong = 0.01 + relativePos * 0.03;
        break;
        
      case CyclePhaseType.ovulation:
        // Abfall vor Eisprung, dann starker Anstieg
        double ovuProgress = (daysFromStart - (_menstruationLength + _follicularLength)) / _ovulationLength;
        
        if (ovuProgress < 0.33) {
          // Erster Tag: leicht abfallend/niedrig
          tempDiff = -0.1 + (rand.nextDouble() * 0.05);
          trendShort = -0.1;
        } else if (ovuProgress < 0.66) {
          // Zweiter Tag: Beginn des Anstiegs
          tempDiff = 0.1 + (rand.nextDouble() * 0.1);
          trendShort = 0.2;
        } else {
          // Dritter Tag: deutlicher Anstieg
          tempDiff = 0.3 + (rand.nextDouble() * 0.1);
          trendShort = 0.2;
        }
        trendLong = 0.1;
        break;
        
      case CyclePhaseType.luteal:
        // Hohe Temperatur, gegen Ende abfallend
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
    
    // Aus Differenz und Baseline die absolute Temperatur berechnen
    final temperature = baseline + tempDiff;
    
    return _TemperatureValues(
      temp: double.parse(temperature.toStringAsFixed(2)),
      diff: double.parse(tempDiff.toStringAsFixed(2)),
      trendShort: double.parse(trendShort.toStringAsFixed(2)),
      trendLong: double.parse(trendLong.toStringAsFixed(2))
    );
  }
  
  // Hilfsmethode zum Aktualisieren des Modells mit neuen manuellen Eingaben
  void updateModelWithNewData(TemperatureDay day) {
    if (trainingData == null) return;
    
    // Nur Daten mit manuell zugewiesener Phase verwenden
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

// Hilfklasse für Temperaturwertgenerierung
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