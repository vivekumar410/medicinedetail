import 'package:flutter/material.dart';
import 'package:medicinedetail/scan_details.dart';
import 'package:medicinedetail/scanmedicinescreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //AIzaSyCAJ5rNXAVnCR6b5VSDRRxhGIpuJnjjKic

      home:  MedicineScannerHome(),
    );
  }
}

