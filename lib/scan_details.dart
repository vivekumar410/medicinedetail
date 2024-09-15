import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

class MedicineScannerHome extends StatefulWidget {
  const MedicineScannerHome({super.key});

  @override
  MedicineScannerHomeState createState() => MedicineScannerHomeState();
}

class MedicineScannerHomeState extends State<MedicineScannerHome> {
  File? _image;
  final picker = ImagePicker();
  String _scanResults = '';
  String _medicineDetails = '';
  bool _isLoading = false;

  Future<void> _requestPermissions() async {
    // Request camera and storage permissions
    PermissionStatus cameraStatus = await Permission.camera.request();
    PermissionStatus storageStatus = await Permission.storage.request();

    // Check if both permissions are granted
    if (cameraStatus.isGranted && storageStatus.isGranted) {
      // Permissions are granted, do nothing or show a success message if needed
      return;
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await _scanImage();
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking image')),
        );
      }
    }
  }

  Future<void> _scanImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _scanResults = '';
      _medicineDetails = '';
    });

    try {
      final GoogleVisionImage visionImage = GoogleVisionImage.fromFile(_image!);
      final TextRecognizer textRecognizer =
          GoogleVision.instance.textRecognizer();
      final VisionText visionText =
          await textRecognizer.processImage(visionImage);

      String scannedText = '';
      for (TextBlock block in visionText.blocks) {
        for (TextLine line in block.lines) {
          scannedText += '${line.text}\n';
        }
      }

      setState(() {
        _scanResults = scannedText;
      });

      await _getMedicineDetails(scannedText);

      textRecognizer.close();
    } catch (e) {
      print('Error scanning image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error scanning image')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        if (_medicineDetails.isNotEmpty) {
          _showMedicineDetails(); // Show details in bottom alert
        }
      });
    }
  }

  Future<void> _getMedicineDetails(String scannedText) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'AIzaSyCAJ5rNXAVnCR6b5VSDRRxhGIpuJnjjKic',
      );

      final content = [
        Content.text('''
    Given the following text scanned from a medicine label, provide a detailed analysis of the medicine with the following information:

    1. **Medicine Name**: Identify the brand and generic names if available.
    2. **Active Ingredients**: List any active ingredients along with their respective quantities.
    3. **Symptoms It Treats**: Specify the symptoms or conditions this medicine is typically used for.
    4. **Primary Diagnosis**: The most common condition(s) this medicine is prescribed for.
    5. **Usage Instructions**: How should this medicine be taken (oral, topical, etc.), including timing and duration.
    6. **Dosage Information**: Recommended dosage for different age groups or conditions.
    7. **Side Effects**: Any common or serious side effects associated with this medicine.
    8. **Warnings**: Important warnings, including interactions with other medicines, foods, or pre-existing conditions.
    9. **Storage Instructions**: How should this medicine be stored (temperature, light exposure, etc.).
    10. **Expiration Information**: The expiration date and any degradation signs to watch for.

    Scanned text: $scannedText

    Please format the response as a structured JSON object with the following keys: "name", "activeIngredients", "symptoms", "diagnosis", "usage", "dosage", "sideEffects", "warnings", "storage", "manufacturer", "expiration".
  ''')
      ];

      final response = await model.generateContent(content);

      final startIndex = response.text!.indexOf('{');
      final endIndex = response.text!.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
        final formattedData =
            response.text!.substring(startIndex, endIndex + 1);
        final details = jsonDecode(formattedData) as Map<String, dynamic>;

        final formattedDetails = '''
      Medicine Name: ${details['name'] ?? 'N/A'}
      Active Ingredients: ${details['activeIngredients'] ?? 'N/A'}
      Symptoms It Treats: ${details['symptoms'] ?? 'N/A'}
      Primary Diagnosis: ${details['diagnosis'] ?? 'N/A'}
      Usage Instructions: ${details['usage'] ?? 'N/A'}
      Dosage Information: ${details['dosage'] ?? 'N/A'}
      Side Effects: ${details['sideEffects'] ?? 'N/A'}
      Warnings: ${details['warnings'] ?? 'N/A'}
      Storage Instructions: ${details['storage'] ?? 'N/A'}
      Expiration Information: ${details['expiration'] ?? 'N/A'}
      ''';

        setState(() {
          _medicineDetails = formattedDetails;
        });
      }
    } catch (e) {
      print('Error fetching medicine details: $e');
      setState(() {
        _medicineDetails = 'Error fetching medicine details';
      });
    }
  }

  void _showMedicineDetails() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(

          decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20), topLeft: Radius.circular(20))),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(
                  child: Text(
                    'Medicine Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Color(0xfff16325B)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(_medicineDetails,style: TextStyle(fontWeight: FontWeight.bold,),textAlign: TextAlign.left,),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xfff16325B),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close the bottom sheet
                  },
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.amber[50],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xfff16325B), Color(0xff9f2a00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor:
                Colors.transparent, // Make the AppBar's background transparent
            elevation: 0, // Remove shadow
            title: Center(
              child: Text('MEDX',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.amber[50]),),
            )
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_image != null)
                Image.file(
                  _image!,
                  fit: BoxFit.contain, // Adjust image fit
                )
              else
                const Text(
                  'Please select a Medicine image to Detail',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey, // Lighter color for contrast
                  ),
                ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amber), // Indicator color
                )
              else
                const SizedBox.shrink(),
              SizedBox(height: 5),
              _isLoading
                  ? Text(
                      "Ruko jara search kar rahe hai",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Lighter color for contrast
                      ),
                    )
                  : SizedBox.shrink(),
              SizedBox(height: 10),
              _image != null && _medicineDetails.isNotEmpty
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xfff16325B), // Dark button color

                        elevation: 5, // Add some elevation for a premium look
                      ),
                      onPressed: () {
                        _showMedicineDetails(); // Close the bottom sheet
                      },
                      child: const Text(
                        'Get Detail',
                        style: TextStyle(
                          color: Colors.white, // Text color on button
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: const Color(0xfff16325B),
            onPressed: () => _getImage(ImageSource.camera),
            tooltip: 'Take Photo',
            child: Icon(Icons.camera_alt, color: Colors.amber[50]),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            backgroundColor: const Color(0xfff16325B),
            onPressed: () => _getImage(ImageSource.gallery),
            tooltip: 'Choose from Gallery',
            child: Icon(Icons.photo_library, color: Colors.amber[50]),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
