import 'package:dio/dio.dart';
import '../api/dio_client.dart';
import '../models/reciter.dart';

class RecitersRepository {
  final DioClient _dioClient;

  RecitersRepository(this._dioClient);

  Future<List<Reciter>> getReciters({String? language}) async {
    try {
      final response = await _dioClient.get(
        '/reciters',
        queryParameters: {
          if (language != null) 'language': language,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['reciters'] != null) {
          return (data['reciters'] as List)
              .map((e) => Reciter.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw e;
    }
  }
}
