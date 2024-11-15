import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ThermoProvider {
  ValueNotifier<List<BluetoothDevice>> foundOvulizeSensors = ValueNotifier<List<BluetoothDevice>>([]);
  ValueNotifier<BluetoothDevice?> ovulizeSensor = ValueNotifier<BluetoothDevice?>(null);
  StreamController<double> streamController = StreamController<double>();
  
  Future<void> init() async {
    startScanCycle();
  }

  void startScanCycle() async {
      Timer timer = Timer.periodic(Duration(seconds: 10), (Timer t) => runSingleScan());
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      ovulizeSensor.value = device;
      return true;
    } catch (e) {
      print("Error connecting to device: $e");
      return false;
    }
  }

  bool deviceConnected() {
    if (ovulizeSensor.value == null || !ovulizeSensor.value!.isConnected) {
      return false;
    }
    return true;
  }

  Stream getTemperatureStream() {
    Stream stream = streamController.stream;
    return stream;
  }

  void startStream() async {
    if (!deviceConnected()) throw Exception("No device connected");

    List<BluetoothService> services = await ovulizeSensor.value!.discoverServices();
    
    BluetoothCharacteristic commandCharacteristic = services.first.characteristics.firstWhere((element) => element.characteristicUuid.toString() == "fff1",);
    await commandCharacteristic.write(utf8.encode("startTemperatureStream"));

    BluetoothCharacteristic dataCharacteristic = services.first.characteristics.firstWhere((element) => element.characteristicUuid.toString() == "fff2",);
    await dataCharacteristic.setNotifyValue(true);

    dataCharacteristic.lastValueStream.listen((value) {
      int tempInt = value[0] | (value[1] << 8);
      double tempDouble = tempInt / 100.0;
      streamController.add(tempDouble);
    });

  }


  void runSingleScan() async {
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        foundOvulizeSensors.value.clear();
        if (results.isNotEmpty) {
          
          for (BluetoothDevice device in results.map((r) => r.device)) {
            if (device.advName.toString().contains("ovulize-")) {
              foundOvulizeSensors.value.add(device);
              foundOvulizeSensors.notifyListeners();
            }
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
