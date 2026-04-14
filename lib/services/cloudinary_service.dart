import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'ProjectExpense';
  static const String _uploadPreset = 'expense_receipts';
  static const String _endpoint =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'file': 'data:image/jpeg;base64,$base64Image',
          'upload_preset': _uploadPreset,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
