import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ThermoProvider {
  ValueNotifier<List<BluetoothDevice>> foundOvulizeSensors =
      ValueNotifier<List<BluetoothDevice>>([]);
  ValueNotifier<BluetoothDevice?> ovulizeSensor =
      ValueNotifier<BluetoothDevice?>(null);
  StreamController<double> streamController = StreamController.broadcast();
  BluetoothCharacteristic? dataCharacteristic;
  StreamSubscription? valueSubscription;

  Future<void> init() async {
    runSingleScan();
    startScanCycle();
  }

  void startScanCycle() async {
    Timer timer =
        Timer.periodic(Duration(seconds: 10), (Timer t) => runSingleScan());
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

  Future<bool> disconnectDevice() async {
    try {
      await ovulizeSensor.value!.disconnect();
      ovulizeSensor.value = null;
      return true;
    } catch (e) {
      print("Error disconnecting from device: $e");
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

    List<BluetoothService> services =
        await ovulizeSensor.value!.discoverServices();
    print("Services:");
    for (BluetoothService service in services) {
      print(service.serviceUuid.toString());
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.characteristicUuid.toString() == "fff1") {
          characteristic.write(utf8.encode("startTemperatureStream"));
        }
        if (characteristic.characteristicUuid.toString() == "fff2") {
          dataCharacteristic = characteristic;
        }
      }
    }
    if (services.isEmpty) {
      throw Exception("No services found");
    }

    await dataCharacteristic!.setNotifyValue(true);

    valueSubscription = dataCharacteristic?.lastValueStream.listen((value) {
      int tempInt = value[0] | (value[1] << 8);
      double tempDouble = tempInt / 100.0;
      streamController.add(tempDouble);
    });
  }

  void stopStream() async {
    streamController.done;
    streamController = StreamController.broadcast();
    dataCharacteristic?.setNotifyValue(false);
    valueSubscription?.cancel();
  }

  void runSingleScan() async {
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        foundOvulizeSensors.value.clear();
        foundOvulizeSensors.notifyListeners();
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
