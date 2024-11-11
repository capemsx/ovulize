import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ThermoProvider {
  ValueNotifier<List<BluetoothDevice>> foundOvulizeSensors = ValueNotifier<List<BluetoothDevice>>([]);
  
  Future<void> init() async {
    startScanCycle();
  }

  void startScanCycle() async {
      Timer timer = Timer.periodic(Duration(seconds: 15), (Timer t) => runSingleScan());
  }

  void runSingleScan() async {
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        foundOvulizeSensors.value.clear();
        if (results.isNotEmpty) {
          
          for (BluetoothDevice device in results.map((r) => r.device)) {
            //if (device.remoteId.toString().contains("OVULIZE")) {
              foundOvulizeSensors.value.add(device);
              foundOvulizeSensors.notifyListeners();
            //}
          }
        }
      },
      onError: (e) => print(e),
    );

    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
  }
}
