import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static String get _cloudName => (dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '').trim();
  static String get _apiKey => (dotenv.env['CLOUDINARY_API_KEY'] ?? '').trim();
  static String get _apiSecret => (dotenv.env['CLOUDINARY_API_SECRET'] ?? '').trim();

  static String get _endpoint => 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  static String _generateSignature(int timestamp) {
    final String params = 'timestamp=$timestamp';
    final String stringToSign = '$params$_apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  static Future<String?> uploadImage(File imageFile) async {
    if (_cloudName.isEmpty || _apiKey.isEmpty || _apiSecret.isEmpty) {
      throw Exception('Cloudinary not configured. Check .env file.');
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(timestamp);

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'file': 'data:image/jpeg;base64,$base64Image',
          'timestamp': timestamp.toString(),
          'api_key': _apiKey,
          'signature': signature,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url = data['secure_url'] as String?;
        if (url != null && url.isNotEmpty) {
          return url;
        }
        throw Exception('Cloudinary returned empty URL');
      }

      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMessage = errorData['error']?['message'] ?? 
                        errorData['error'] ?? 
                        response.body;
      
      debugPrint('Cloudinary error ${response.statusCode}: $errorMessage');
      throw Exception('Upload failed: $errorMessage');
      
    } on SocketException catch (e) {
      debugPrint('Cloudinary network error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('Cloudinary unexpected error: $e');
      throw Exception('Upload failed: $e');
    }
  }
}