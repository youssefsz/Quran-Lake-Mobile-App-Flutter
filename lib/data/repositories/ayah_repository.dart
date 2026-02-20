import 'package:dio/dio.dart';
import '../models/ayah.dart';

class AyahRepository {
  final Dio _dio = Dio(); // Using a separate Dio instance for external API to avoid base URL conflicts

  Future<Ayah> getRandomAyah() async {
    try {
      // Fetch a random Ayah with Arabic text (quran-uthmani) and English translation (en.asad)
      // The API returns an object with a 'data' array containing two editions
      final response = await _dio.get(
        'https://api.alquran.cloud/v1/ayah/random/editions/quran-uthmani,en.asad',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data is List && data.isNotEmpty) {
          // Construct the Ayah object from the response
          // We pass the whole response data to the factory constructor
          // The API response structure:
          // {
          //   "code": 200,
          //   "status": "OK",
          //   "data": [
          //     { "text": "...", "number": 1, "surah": { ... }, ... }, // Arabic
          //     { "text": "...", "number": 1, "surah": { ... }, ... }  // English
          //   ]
          // }
          
          // Our factory expects the root json or the data part?
          // The factory I wrote: factory Ayah.fromJson(Map<String, dynamic> json)
          // It accesses json['data'][0]. So I should pass the whole response.data
          
          return Ayah.fromJson(response.data);
        }
      }
      throw Exception('Failed to load Ayah');
    } catch (e) {
      throw Exception('Error fetching Ayah: $e');
    }
  }
}
