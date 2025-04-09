import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ovulize/backend/utils/encryption_helper.dart';
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

  Future<void> _showAddRandomDataDialog() async {
    int? numberOfDays = 30; // Default value
    int? ovulationDay = 14; // Default value for ovulation (day 14 in cycle)

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Random Measurement Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How many days of data should be generated?'),
              SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of days',
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
              Text('On which day should ovulation be simulated?'),
              SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ovulation (day in cycle)',
                  border: OutlineInputBorder(),
                  helperText: 'Default day 14 of a 28-day cycle',
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
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                generateAndSaveRandomData(numberOfDays!, ovulationDay!);
              },
              child: Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  

  Future<void> generateAndSaveRandomData(
      int numberOfDays, int ovulationDay) async {
    setState(() {
      isLoading = true;
    });

    // Current date for data generation
    DateTime currentDate = DateTime.now();

    // Use fixed values that are guaranteed to be recognized by CyclePhasePredictor
    double baseTemperature = 36.5; // Stable baseline

    // Calculate the first day of the simulated cycle
    DateTime cycleStartDate =
        currentDate.subtract(Duration(days: numberOfDays - 1));

    // Store last generated temperature
    double? lastTemp;

    // Lists for collecting data before saving
    final List<DateTime> dates = [];
    final List<double> temperatures = [];

    // Create simulated temperature values as a cohesive set
    for (int i = 0; i < numberOfDays; i++) {
      final date = cycleStartDate.add(Duration(days: i));
      dates.add(date);

      // Day in dataset (1 to numberOfDays)
      final dayInDataset = i + 1;

      // Temperature based on position relative to desired ovulation
      double temperature;

      // Precise temperatures based on patterns expected by CyclePhasePredictor
      if (dayInDataset < ovulationDay - 1) {
        // Stable low follicular temperature
        temperature = baseTemperature - 0.2;

        // Mark first 5 days as menstruation (slight temperature drop)
        if (dayInDataset <= 5) {
          // Slight drop in first days for menstruation detection
          temperature = baseTemperature - 0.2 + (5 - dayInDataset) * 0.02;
        }
      } else if (dayInDataset == ovulationDay - 1) {
        // Day before ovulation: Temperature low (nadir)
        // The algorithm looks for a drop before the rise
        temperature =
            baseTemperature - 0.3; // Lower than normal follicular level
      } else if (dayInDataset == ovulationDay) {
        // Day of ovulation: Beginning rise
        // The algorithm expects a significant rise already here
        temperature = baseTemperature + 0.0; // Back to baseline
      } else if (dayInDataset == ovulationDay + 1) {
        // Day after ovulation: Clear rise
        // The algorithm expects the biggest change here
        temperature = baseTemperature + 0.3; // Significantly higher than baseline
      } else {
        // After ovulation: Stable luteal phase (clearly elevated)
        temperature = baseTemperature + 0.4;

        // Slightly decreasing towards the end, if enough days after ovulation
        int daysAfterOvulation = dayInDataset - ovulationDay;
        if (daysAfterOvulation > 10) {
          temperature =
              baseTemperature + 0.4 - ((daysAfterOvulation - 10) * 0.05);
        }
      }

      // Smooth transitions for more natural curves, but without blurring important patterns
      if (lastTemp != null) {
        // Allow large changes only during ovulation
        double maxChange;

        if (dayInDataset == ovulationDay || dayInDataset == ovulationDay + 1) {
          // Allow jumps during ovulation
          maxChange = 0.3;
        } else if (dayInDataset == ovulationDay - 1) {
          // Allow significant drop at nadir before ovulation
          maxChange = 0.2;
        } else {
          // Otherwise only small changes
          maxChange = 0.1;
        }

        double diff = temperature - lastTemp;
        if (diff.abs() > maxChange) {
          // Limit change
          temperature = lastTemp + (diff > 0 ? maxChange : -maxChange);
        }
      }

      // Round to exactly 2 decimal places
      temperature = double.parse(temperature.toStringAsFixed(2));
      temperatures.add(temperature);
      lastTemp = temperature;
    }

    // Clear previous data for a clean baseline
    await dataProvider.db.delete('TemperatureData');

    // Save all values as a unified dataset
    for (int i = 0; i < dates.length; i++) {
      await dataProvider.insertTemperatureData(dates[i], temperatures[i]);
    }

    // Load and analyze the new data
    final newData = await dataProvider.getTemperatureData();

    // Analyze with the CyclePhasePredictor
    temperatureData = cyclePhasePredictor.analyzeCurrentCycle(newData);
    // Update temperatureData with prediction
    temperatureData =
        cyclePhasePredictor.predictFutureCyclePhases(temperatureData, 3);

    setState(() {
      temperatureList = newData;
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '$numberOfDays measurement data with distinct ovulation on day $ovulationDay generated'),
      backgroundColor: primaryColor,
    ));
  }

  Future<void> _showAddMeasurementDialog() async {
  double? temperatureValue;
  DateTime selectedDate = DateTime.now();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add measurement manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Temperaturr (°C)',
                border: OutlineInputBorder(),
                helperText: 'e.g. 36.5',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  temperatureValue = double.tryParse(value.replaceAll(',', '.'));
                }
              },
            ),
            SizedBox(height: 16),
            Text('Date of measurement'),
            SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null && picked != selectedDate) {
                  selectedDate = picked;
                  (context as Element).markNeedsBuild();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                    Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              if (temperatureValue != null) {
                Navigator.of(context).pop();
                addTemperatureData(selectedDate, temperatureValue!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please add valid temperature value.'))
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}
Future<void> addTemperatureData(DateTime date, double temperature) async {
  setState(() {
    isLoading = true;
  });

  try {
    await dataProvider.insertTemperatureData(date, temperature);
    
    // Daten neu laden und analysieren
    await loadTemperatureData();
    
    temperatureData = cyclePhasePredictor.analyzeCurrentCycle(temperatureList);
    temperatureData = cyclePhasePredictor.predictFutureCyclePhases(temperatureData, 3);
  } catch (e) {
    print('Fehler beim Hinzufügen: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
      temperatureList.sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(
        title: Text('Past Measurements'),
        actions: [
          IconButton(
            icon: Icon(Icons.science_outlined),
            tooltip: 'Generate test data',
            onPressed: _showAddRandomDataDialog,
          ),
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add measurement',
            onPressed: _showAddMeasurementDialog,
          ),
        ],
      ),
      
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : temperatureList.isEmpty
                    ? Center(child: Text('No measurements available'))
                    : ListView.builder(
                        itemCount: temperatureList.length,
                        itemBuilder: (context, index) {
                          final item = temperatureList[index];
                          final dateFormat = DateFormat('MM/dd/yyyy');

                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: Icon(Icons.thermostat,
                                  color: primaryColor, size: 32),
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
                                      color: item.cyclePhase.getColor() ??
                                          Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(dateFormat.format(item.date)),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    deleteTemperatureData(item.date),
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

  Future<void> deleteTemperatureData(DateTime date) async {
    try {
      // Call new method in DataProvider
      int count = await dataProvider.deleteTemperatureDataByDay(date);
      
      // Reload and update data
      await loadTemperatureData();
      

        temperatureData = cyclePhasePredictor.analyzeCurrentCycle(temperatureList);
        temperatureData = cyclePhasePredictor.predictFutureCyclePhases(temperatureData, 3);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0 
            ? 'Measurement from ${DateFormat('MM/dd/yyyy').format(date)} deleted' 
            : 'Could not delete measurement. Please try again.'),
          backgroundColor: count > 0 ? primaryColor : Colors.red,
        ),
      );
    } catch (e) {
      print('Error deleting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}