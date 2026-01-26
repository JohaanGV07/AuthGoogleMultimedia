import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImgbbService {
  // TU API KEY REAL
  final String _apiKey = 'e00dc73933c8af502be1df612adf4800'; 

  Future<String?> uploadImage(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(uri, body: {
        'image': base64Image,
      });

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data']['url'];
      } else {
        print('Error Imgbb: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepción subida: $e');
      return null;
    }
  }
}