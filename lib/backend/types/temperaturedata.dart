class TemperatureData {
  final int id;
  final DateTime timestamp;
  final double temperatureValue;

  TemperatureData({
    required this.id,
    required this.timestamp,
    required this.temperatureValue,
  });

  factory TemperatureData.fromMap(Map<String, dynamic> map) {
    return TemperatureData(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      temperatureValue: map['temperature_value'],
    );
  }
}
