!Ovulize

An open-source fertility tracking app with high-precision temperature measurement for accurate cycle monitoring.

## ✨ Features

- 🌡️ **High-precision temperature tracking** with custom ESP32 + TMP117 sensor (±0.1°C accuracy)
- 📊 **Advanced cycle analysis** with automatic phase detection
- 📱 **Intuitive UI** with interactive cycle wheel and calendar visualization
- 🔔 **Measurement reminders** for consistent daily readings
- 📈 **Personalized predictions** based on your historical data
- 🔒 **Privacy-focused** with all data stored locally on your device

## 📱 Screenshots

[Screenshots will be added here]

## 🛠️ Requirements

### App Development

- Flutter SDK (3.3.2 or later)
- Dart SDK (3.0.0 or later)
- Android Studio / Xcode for native platform development

### Supported Platforms

- ✅ iOS
- ✅ Android 
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 📋 Installation

```bash
# Clone the repository
git clone https://github.com/username/ovulize.git

# Navigate to project folder
cd ovulize

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🔌 Hardware Setup

The Ovulize app connects to a custom temperature sensor featuring:

- ESP32 microcontroller
- TMP117 high-precision temperature sensor
- LiPo battery (300mAh+)

### Building the Sensor

For sensor hardware and firmware:

1. Get hardware designs and schematic: [github.com/username/ovulize-hardware](https://github.com/username/ovulize-hardware)
2. Flash the firmware: [github.com/username/ovulize-firmware](https://github.com/username/ovulize-firmware)

Basic connections:
```
ESP32        TMP117
-------      -------
3.3V    -->  VCC
GND     -->  GND
GPIO22  -->  SDA
GPIO23  -->  SCL
```

## 🧪 Testing

Run the test suite:
```bash
flutter test
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

Ovulize is provided for informational purposes only and is not a substitute for medical advice. Always consult healthcare professionals for medical concerns.