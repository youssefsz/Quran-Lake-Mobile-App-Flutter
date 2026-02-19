import 'package:dio/dio.dart';
import '../api/dio_client.dart';
import '../models/surah.dart';

class SurahRepository {
  final DioClient _dioClient;

  SurahRepository(this._dioClient);

  Future<List<Surah>> getSurahs({String? language}) async {
    try {
      final response = await _dioClient.get(
        '/suwar',
        queryParameters: {
          if (language != null) 'language': language,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['suwar'] != null) {
          return (data['suwar'] as List)
              .map((e) => Surah.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw e;
    }
  }
}
