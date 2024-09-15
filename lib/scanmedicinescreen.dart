import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicinedetail/service_detail.dart';
import 'package:permission_handler/permission_handler.dart';

class TextGeneration2 extends StatefulWidget {
  const TextGeneration2({super.key});

  @override
  State<TextGeneration2> createState() => _TextGeneration2State();
}

class _TextGeneration2State extends State<TextGeneration2> {
  File? _image;
  String? _medicineDetails;
  bool _isLoading = false;
  final picker = ImagePicker();
  final MedicineDetailService _medicineDetailService = MedicineDetailService();

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _getMedicineDetails();
    }
  }

  Future<void> _getMedicineDetails() async {
    if (_image != null) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      try {


        final details = await _medicineDetailService.getMedicineDetails(_image!);
        setState(() {
          _medicineDetails = details['text']; // Assuming API returns a 'text' field
        });
      } catch (e) {
        setState(() {
          _medicineDetails = 'Error fetching details. Please try again.';
        });
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Medicine'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null ? Image.file(_image!) : Text('No image selected.'),
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: Icon(Icons.photo),
              label: Text('Select Image'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : _medicineDetails != null
                ? Text('Medicine Details: $_medicineDetails')
                : Text('No details available.'),
          ],
        ),
      ),
    );
  }
}
