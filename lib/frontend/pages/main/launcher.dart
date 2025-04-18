import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ovulize/frontend/pages/main/barwrapper.dart';
import 'package:ovulize/globals.dart';

class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key});

  @override
  State<LauncherPage> createState() => LauncherPageState();
}

class LauncherPageState extends State<LauncherPage> {
  bool finished = false;
  @override
  void initState() {
    super.initState();
    startup().then((val) async {
      setState(() {
        finished = true;
      });
      await Future.delayed(Duration(milliseconds: 200));
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (ctx) => BarWrapper()), (route) => false);
    });
  }

  Future<void> startup() async {
    await Future.delayed(Duration(seconds: 1)); //VISUAL REASON FOR DELAY
    await dataProvider.init();
    await thermoProvider.init();
    temperatureData = cyclePhasePredictor.predictFutureCyclePhases(await dataProvider.getTemperatureData(), 3);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        body: Container(
            color: primaryColor,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(60.0),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 400),
                  opacity: finished ? 0.2 : 1,
                  child: AnimatedScale(
                      duration: Duration(milliseconds: 400),
                      scale: finished ? 0.2 : 1,
                      child: Image.asset("assets/images/logo_font_white.png")),
                ),
              ),
            )));
  }
}
