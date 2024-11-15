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
  bool connected = false;

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
                                  await Future.delayed(Duration(milliseconds: 500)); //wait for animation to be finished
                                  thermoProvider.startStream();
                                },
                                child: Text("Start")),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          
                          
                      
                
                            Center(
                              child: StreamBuilder(
                                stream:
                                    thermoProvider.getTemperatureStream(),
                                builder: (context, snapshot) {
                                  return Text(
                                      (snapshot.data?.toStringAsFixed(2) ?? "--.--") + "°",
                                      style: TextStyle(
                                          color: primaryColor,
                                          shadows: [
                                            Shadow(
                                                color: primaryColor.withOpacity(0.3),
                                                offset: Offset(0, 0),
                                                blurRadius: 6)
                                          ],
                                          fontFamily: "Gilroy-Bold",
                                          fontSize: 60),);
                                },
                              ),
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
                          color:
                              connected
                                  ? Colors.green
                                  : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(connected
                          ? "Connected!"
                          : "Connecting...")
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
