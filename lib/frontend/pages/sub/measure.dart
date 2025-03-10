import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:ovulize/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool showTutorial = false;

  @override
  void initState() {
    super.initState();
    checkFirstOpen();
    createConnection();
    checkForConnectionStateAsync();
  }

  Future<void> checkFirstOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool firstOpen = !(prefs.getBool('measurement_tutorial_shown') ?? false);
    
    if (firstOpen) {
      setState(() {
        showTutorial = true;
      });
      await prefs.setBool('measurement_tutorial_shown', true);
    }
  }
  
  void closeTutorial() {
    setState(() {
      showTutorial = false;
    });
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                tween: Tween<double>(
                  begin: 0,
                  end: measurementProgress,
                ),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryColor.withOpacity(0.3),
                  ),
                  minHeight: 3,
                ),
              ),
            ),
            Center(
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
                          style: TextStyle(fontSize: 14, color: Colors.black54),
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
                              final value =
                                  snapshot.data?.toStringAsFixed(2) ?? "--.--";
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TweenAnimationBuilder(
                                    duration: Duration(milliseconds: 100),
                                    curve: Curves.easeOutBack,
                                    tween: Tween<double>(begin: 0.95, end: 1.0),
                                    key: ValueKey(
                                        value), 
                                    builder: (context, scale, child) =>
                                        Transform.scale(
                                      scale: scale,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          color: primaryColor,
                                          shadows: [
                                            Shadow(
                                                color: primaryColor
                                                    .withOpacity(0.3),
                                                offset: Offset(0, 0),
                                                blurRadius: 6)
                                          ],
                                          fontFamily: "Gilroy-Bold",
                                          fontSize:
                                              55,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
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
                                      fontSize: 55,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Align(
                                alignment: Alignment.topCenter,
                                child: buildBackgroundChart()),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Positioned(
                                    right: 20,
                                    child: Icon(
                                      LineIcons.thermometer34Full,
                                      color: primaryColor,
                                      size: 40,
                                    )),
                                Text(
                                  (finalValue.toStringAsFixed(2) ?? "--.--") +
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
                                ),
                              ],
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
                                await dataProvider.insertTemperatureData(
                                    DateTime.now(), finalValue);
                                await thermoProvider.disconnectDevice();
                                setState(() {
                                  done = true;
                                });
                                await Future.delayed(
                                    Duration(milliseconds: 500));
                                Navigator.of(context).pop();
                              },
                              child:
                                  done ? Icon(Icons.check) : Text("Speichern")),
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
                )),
                if (showTutorial)
  Container(
    color: Colors.black.withOpacity(0.7),
    width: double.infinity,
    height: double.infinity,
    child: Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Anleitung zur Temperaturmessung",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            buildTutorialStep(
              icon: LineIcons.thermometer, 
              text: "Lege das Thermometer unter deine Zunge und schließe den Mund"
            ),
            SizedBox(height: 10),
            buildTutorialStep(
              icon: LineIcons.chair, 
              text: "Setze dich bequem und ruhig hin während der Messung"
            ),
            SizedBox(height: 10),
            buildTutorialStep(
              icon: LineIcons.exclamationTriangle, 
              text: "Achte darauf, dass dein Körper keine erhöhte oder erniedrigte Temperatur hat"
            ),
            SizedBox(height: 10),
            buildTutorialStep(
              icon: LineIcons.clock, 
              text: "Für beste Ergebnisse, miss täglich zur gleichen Uhrzeit"
            ),
            SizedBox(height: 20),
            MaterialButton(
              color: primaryColor,
              textColor: Colors.white,
              minWidth: 150,
              height: 50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("Verstanden"),
              onPressed: closeTutorial,
            )
          ],
        ),
      ),
    ),
  ),
          ],
        ),
      ),
    );
  }

  Widget buildTutorialStep({required IconData icon, required String text}) {
  return Row(
    children: [
      Icon(icon, color: primaryColor, size: 24),
      SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 16),
        ),
      ),
    ],
  );
}

  double getBalancedTemperature(List<double> temperatures) {
    // 1. Sorting for calculating median
    List<double> lTemperatures = temperatures.toList();
    lTemperatures.sort();

    // Calculating median
    double median;
    int middle = lTemperatures.length ~/ 2;
    if (lTemperatures.length % 2 == 1) {
      median = lTemperatures[middle];
    } else {
      median = (lTemperatures[middle - 1] + lTemperatures[middle]) / 2.0;
    }

    // 3. Removing values 0.2°C away from median
    final refinedTemps =
        lTemperatures.where((temp) => (temp - median).abs() <= 0.2).toList();

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

  //WIDGETS//

  Widget buildBackgroundChart() {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.15, 0.85, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 200,
        child: IgnorePointer(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    measuredValues.length,
                    (index) => FlSpot(index.toDouble(), measuredValues[index]),
                  ),
                  isCurved: true,
                  color: primaryColor.withOpacity(0.2),
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: [
                    FlSpot(0, finalValue),
                    FlSpot(measuredValues.length.toDouble(), finalValue),
                  ],
                  color: primaryColor.withOpacity(0.4),
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
