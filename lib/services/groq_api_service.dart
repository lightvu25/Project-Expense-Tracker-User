import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqApiService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static Future<Map<String, dynamic>?> analyzeReceipt(File imageFile) async {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GROQ_API_KEY not found in environment variables');
      }

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);

      final systemPrompt = '''You are an OCR financial assistant specialized in extracting receipt data. 
Analyze the receipt image and extract ONLY a strict JSON object with these exact keys:
- title: The name/item purchased (string)
- amount: The total amount as a number (string, remove currency symbols)
- date: The receipt date in YYYY-MM-DD format (string)
- location: The store/vendor name and location (string)
- description: Brief description of items (string)
- category: One of these categories: travel, equipment, materials, services, software, labor, utilities, miscellaneous

Return ONLY valid JSON. No additional text.''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'temperature': 0.1,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          return _parseJsonResponse(content);
        }
        return null;
      } else {
        throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('GroqApiService error: $e');
      rethrow;
    }
  }

  static String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static Map<String, dynamic>? _parseJsonResponse(String content) {
    try {
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonString = content.substring(jsonStart, jsonEnd + 1);
        return json.decode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('JSON parse error: $e');
      return null;
    }
  }
}