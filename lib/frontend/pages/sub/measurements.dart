import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ovulize/globals.dart';
import 'package:ovulize/backend/providers/dataprovider.dart';
import 'package:ovulize/backend/providers/cyclephasepredictor.dart';

class MeasurementsPage extends StatefulWidget {
  const MeasurementsPage({super.key});

  @override
  State<MeasurementsPage> createState() => MeasurementsPageState();
}

class MeasurementsPageState extends State<MeasurementsPage> {
  List<TemperatureDay> temperatureList = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    loadTemperatureData();
  }

  Future<void> loadTemperatureData() async {
    setState(() {
      isLoading = true;
    });
    
    final data = await dataProvider.getTemperatureData();
    
    setState(() {
      temperatureList = data;
      isLoading = false;
    });
  }
  
  Future<void> deleteTemperatureData(DateTime date) async {
    await dataProvider.db.delete('TemperatureData',
        where: 'timestamp = ?', whereArgs: [date.toIso8601String()]);
    loadTemperatureData();
  }
  
  Future<void> _showAddRandomDataDialog() async {
    int? numberOfDays = 30; // Standardwert
    int? ovulationDay = 14; // Standardwert für den Eisprung (Tag 14 im Zyklus)
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Zufällige Messdaten hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Wie viele Tage an Daten sollen generiert werden?'),
              SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Anzahl Tage',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    numberOfDays = int.tryParse(value) ?? 30;
                  }
                },
                controller: TextEditingController(text: '30'),
              ),
              SizedBox(height: 16),
              Text('An welchem Tag soll der Eisprung simuliert werden?'),
              SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Eisprung (Tag im Zyklus)',
                  border: OutlineInputBorder(),
                  helperText: 'Standardmäßig Tag 14 eines 28-Tage-Zyklus',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    ovulationDay = int.tryParse(value) ?? 14;
                  }
                },
                controller: TextEditingController(text: '14'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                generateAndSaveRandomData(numberOfDays!, ovulationDay!);
              },
              child: Text('Generieren'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> generateAndSaveRandomData(int numberOfDays, int ovulationDay) async {
    setState(() {
      isLoading = true;
    });
    
    // Aktuelles Datum für die Datengenerierung
    DateTime currentDate = DateTime.now();
    
    // Feste Werte verwenden, die vom CyclePhasePredictor garantiert erkannt werden
    double baseTemperature = 36.5; // Stabile Basislinie
    
    // Berechne den ersten Tag des simulierten Zyklus
    DateTime cycleStartDate = currentDate.subtract(Duration(days: numberOfDays - 1));
    
    // Letzte generierte Temperatur speichern
    double? lastTemp;
    
    // Listen zum Sammeln der Daten vor dem Speichern
    final List<DateTime> dates = [];
    final List<double> temperatures = [];
    
    // Erstelle die simulierten Temperaturwerte als zusammenhängendes Set
    for (int i = 0; i < numberOfDays; i++) {
      final date = cycleStartDate.add(Duration(days: i));
      dates.add(date);
      
      // Tag im Datensatz (1 bis numberOfDays)
      final dayInDataset = i + 1;
      
      // Temperatur basierend auf Position zum gewünschten Eisprung
      double temperature;
      
      // Präzise Temperaturen anhand der vom CyclePhasePredictor erwarteten Muster
      if (dayInDataset < ovulationDay - 1) {
        // Stabile niedrige Follicular-Temperatur
        temperature = baseTemperature - 0.2;
        
        // Ersten 5 Tage als Menstruation markieren (leichter Temperaturabfall)
        if (dayInDataset <= 5) {
          // Leichter Abfall in den ersten Tagen für Menstruation-Erkennung
          temperature = baseTemperature - 0.2 + (5 - dayInDataset) * 0.02;
        }
      } 
      else if (dayInDataset == ovulationDay - 1) {
        // Tag vor dem Eisprung: Temperaturtief (Nadir)
        // Der Algorithmus sucht nach einem Abfall vor dem Anstieg
        temperature = baseTemperature - 0.3; // Tiefer als das normale follikuläre Niveau
      }
      else if (dayInDataset == ovulationDay) {
        // Tag des Eisprung: Bereits beginnender Anstieg
        // Der Algorithmus erwartet hier schon einen signifikanten Anstieg
        temperature = baseTemperature + 0.0; // Zurück zur Basislinie
      }
      else if (dayInDataset == ovulationDay + 1) {
        // Tag nach dem Eisprung: Deutlicher Anstieg
        // Hier erwartet der Algorithmus die größte Änderung
        temperature = baseTemperature + 0.3; // Signifikant höher als Basislinie
      }
      else {
        // Nach dem Eisprung: Stabile Lutealphase (deutlich erhöht)
        temperature = baseTemperature + 0.4;
        
        // Gegen Ende wieder leicht absinkend, falls genügend Tage nach Eisprung
        int daysAfterOvulation = dayInDataset - ovulationDay;
        if (daysAfterOvulation > 10) {
          temperature = baseTemperature + 0.4 - ((daysAfterOvulation - 10) * 0.05);
        }
      }
      
      // Sanfte Übergänge für natürlichere Kurven, aber kein Verwischen der wichtigen Muster
      if (lastTemp != null) {
        // Große Änderungen nur beim Eisprung zulassen
        double maxChange;
        
        if (dayInDataset == ovulationDay || dayInDataset == ovulationDay + 1) {
          // Beim Eisprung darf es springen
          maxChange = 0.3;
        } else if (dayInDataset == ovulationDay - 1) {
          // Beim Nadir vor dem Eisprung darf es auch deutlich fallen
          maxChange = 0.2;
        } else {
          // Ansonsten nur kleine Änderungen
          maxChange = 0.1;
        }
        
        double diff = temperature - lastTemp;
        if (diff.abs() > maxChange) {
          // Änderung begrenzen
          temperature = lastTemp + (diff > 0 ? maxChange : -maxChange);
        }
      }
      
      // Exakt auf 2 Nachkommastellen runden
      temperature = double.parse(temperature.toStringAsFixed(2));
      temperatures.add(temperature);
      lastTemp = temperature;
    }
    
    // Leere die vorherigen Daten, um eine klare Datenbasis zu haben
    await dataProvider.db.delete('TemperatureData');
    
    // Speichere alle Werte als einheitlichen Datensatz
    for (int i = 0; i < dates.length; i++) {
      await dataProvider.insertTemperatureData(dates[i], temperatures[i]);
    }
    
    // Lade und analysiere die neuen Daten
    final newData = await dataProvider.getTemperatureData();
    
    // Analysiere mit dem CyclePhasePredictor
    temperatureData = cyclePhasePredictor.analyzeCurrentCycle(newData);
    // Aktualisiere temperatureData mit Vorhersage
    temperatureData = cyclePhasePredictor.predictFutureCyclePhases(temperatureData, 3);
    
    setState(() {
      temperatureList = newData;
      isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$numberOfDays Messdaten mit eindeutigem Eisprung an Tag $ovulationDay generiert'),
        backgroundColor: primaryColor,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vergangene Messungen'),
        actions: [
          IconButton(
            icon: Icon(Icons.science_outlined),
            tooltip: 'Testdaten generieren',
            onPressed: _showAddRandomDataDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : temperatureList.isEmpty
                    ? Center(child: Text('Keine Messungen vorhanden'))
                    : ListView.builder(
                        itemCount: temperatureList.length,
                        itemBuilder: (context, index) {
                          final item = temperatureList[index];
                          final dateFormat = DateFormat('dd.MM.yyyy');
                          
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.thermostat, 
                                color: primaryColor, 
                                size: 32
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '${item.temperature.toStringAsFixed(2)}°C',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: item.cyclePhase.getColor() ?? Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(dateFormat.format(item.date)),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteTemperatureData(item.date),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}