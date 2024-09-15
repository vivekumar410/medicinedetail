import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class MedicineDetailService {
  final Dio _dio = Dio();
  final String apiKey = 'AIzaSyDB4crYsZxUo8kqlTMGIQzgKHytzbQzYJI';  // Replace with your actual API key

  // Function to get medicine details from the image
  Future<Map<String, dynamic>> getMedicineDetails(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final String imageBase64 = base64Encode(bytes);

    // API URL for Google Cloud Vision API
    final String url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

    final data = {
      'requests': [
        {
          'image': {
            'content': imageBase64,
          },
          'features': [
            {
              'type': 'TEXT_DETECTION',
              'maxResults': 10,
            }
          ]
        }
      ]
    };

    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        print('Response: ${response.data}');
        return response.data;
      } else {
        throw Exception('Failed to load details: ${response.statusCode}');
      }
    } on DioError catch (e) {
      print('Dio error: ${e.response?.statusCode} - ${e.response?.data}');
      throw Exception('Dio error: ${e.message}');
    }
  }
}
