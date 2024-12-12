import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:menstrual_cycle_widget/ui/menstrual_cycle_phase_view.dart';
import 'package:ovulize/globals.dart';

class MeasurePage extends StatefulWidget {
  const MeasurePage({super.key});

  @override
  State<MeasurePage> createState() => MeasurePageState();
}

class MeasurePageState extends State<MeasurePage> {
  CarouselSliderController carouselSliderController =
      CarouselSliderController();
  static int maxMeasurementsCount = 25;
  bool connected = false;
  double measurementProgress = 0;
  List<double> measuredValues = [];
  double finalValue = 0;
  bool done = false;

  @override
  void initState() {
    super.initState();
    createConnection();
    checkForConnectionStateAsync();
  }

  void createConnection() async {
    await waitForConnection();
    setPage(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: CarouselSlider(
                    carouselController: carouselSliderController,
                    items: [
                      Container(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Start your measurement",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            "Place the sensor on your finger and press the button below to start the measurement.",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: MaterialButton(
                                color: primaryColor,
                                textColor: backgroundColor,
                                minWidth: 180,
                                height: 60,
                                onPressed: () async {
                                  setPage(2);
                                  await Future.delayed(Duration(
                                      milliseconds:
                                          500)); //wait for animation to be finished
                                  startMeasurement();
                                },
                                child: Text("Start")),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          Container(
                              decoration: BoxDecoration(
                            gradient: RadialGradient(
                                radius: 0.5 * measurementProgress,
                                colors: <Color>[
                                  primaryColor
                                      .withOpacity(0.4 * measurementProgress),
                                  primaryColor.withOpacity(0)
                                ]),
                          )),
                          Center(
                            child: StreamBuilder(
                              stream: thermoProvider.getTemperatureStream(),
                              builder: (context, snapshot) {
                                return Text(
                                  (snapshot.data?.toStringAsFixed(2) ??
                                          "--.--") +
                                      "°",
                                  style: TextStyle(
                                      color: primaryColor,
                                      shadows: [
                                        Shadow(
                                            color:
                                                primaryColor.withOpacity(0.3),
                                            offset: Offset(0, 0),
                                            blurRadius: 6)
                                      ],
                                      fontFamily: "Gilroy-Bold",
                                      fontSize: 50 + (5 * measurementProgress)),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Positioned(
                                right: 20,
                                child: Icon(LineIcons.thermometer34Full, color: primaryColor, size: 40,)),
                              Text(
                                (finalValue.toStringAsFixed(2) ?? "--.--") + "°",
                                style: TextStyle(
                                    color: primaryColor,
                                    shadows: [
                                      Shadow(
                                          color: primaryColor.withOpacity(0.3),
                                          offset: Offset(0, 0),
                                          blurRadius: 6)
                                    ],
                                    fontFamily: "Gilroy-Bold",
                                    fontSize: 50 + (5 * measurementProgress)),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height / 4),
                          TextButton(
                            child: Text(
                              "Erneut messen",
                              style: TextStyle(color: primaryColor),
                            ),
                            onPressed: () {
                              

                              setPage(1);
                                setState(() {
                                measuredValues = [];
                                measurementProgress = 0;
                                finalValue = 0;
                              });

                              
                            },
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: MaterialButton(
                                color: primaryColor,
                                textColor: backgroundColor,
                                minWidth: 180,
                                height: 60,
                                onPressed: () async {
                                  await dataProvider.insertTemperatureData(DateTime.now(), finalValue);
                                  setState(() {
                                    done = true;
                                  });
                                  await Future.delayed(Duration(
                                      milliseconds:
                                          500));
                                  Navigator.of(context).pop();
                                },
                                child: done ? Icon(Icons.check) : Text("Speichern")),
                          ),
                        ],
                      )
                    ],
                    options: CarouselOptions(
                        enableInfiniteScroll: false,
                        aspectRatio: 5 / 10,
                        viewportFraction: 1,
                        enlargeFactor: 0.2)),
              ),
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: connected ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(connected ? "Connected" : "Connecting...")
                    ],
                  ),
                )),
            Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        LineIcons.times,
                        color: Colors.grey,
                      )),
                ))
          ],
        ),
      ),
    );
  }

  double getBalancedTemperature(List<double> temperatures) {
    // 1. excluding extreme values
    final filteredTemps =
        temperatures.where((temp) => temp >= 35.0 && temp <= 42.0).toList();
    if (filteredTemps.isEmpty) {
      throw Exception("Invalid measurement.");
    }

    // 2. Sorting for calculating median
    filteredTemps.sort();

    // Calculating median
    double median;
    int middle = filteredTemps.length ~/ 2;
    if (filteredTemps.length % 2 == 1) {
      median = filteredTemps[middle];
    } else {
      median = (filteredTemps[middle - 1] + filteredTemps[middle]) / 2.0;
    }

    // 3. Removing values 0.2°C away from median
    final refinedTemps =
        filteredTemps.where((temp) => (temp - median).abs() <= 0.2).toList();

    // 4. Calculating final average
    double average = refinedTemps.reduce((a, b) => a + b) / refinedTemps.length;

    return average;
  }

  void startMeasurement() {
    thermoProvider.startStream();

    thermoProvider.getTemperatureStream().listen((value) {
      if (measuredValues.length >= maxMeasurementsCount) {
        thermoProvider.stopStream();
        getBalancedTemperature(measuredValues);
        setState(() {
          finalValue = getBalancedTemperature(measuredValues);
        });
        setPage(3);
        return;
      }
      setState(() {
        measuredValues.add(value);
        measurementProgress = measuredValues.length / maxMeasurementsCount;
      });
    });
  }

  void checkForConnectionStateAsync() async {
    Timer timer = Timer.periodic(Duration(seconds: 1), (timer) {
      bool lConnected = thermoProvider.deviceConnected();
      if (lConnected != connected) {
        setState(() {
          connected = lConnected;
        });
      }
    });
  }

  Future<void> waitForConnection() async {
    await thermoProvider
        .connectToDevice(thermoProvider.foundOvulizeSensors.value.first);
  }

  void setPage(int pageIndex) async {
    carouselSliderController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 450), curve: Curves.easeInOut);
    await Future.delayed(
        Duration(milliseconds: 450)); // wait for animation to finish
  }
}
