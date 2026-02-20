import 'package:intl/intl.dart';
import 'package:quran_lake/data/api/dio_client.dart';
import 'package:quran_lake/data/local_db/database_helper.dart';
import 'package:quran_lake/data/models/prayer_time.dart';
import 'package:quran_lake/data/services/location_service.dart';

class PrayerTimeRepository {
  final DioClient _dioClient;
  final DatabaseHelper _databaseHelper;
  final LocationService _locationService;

  PrayerTimeRepository({
    required DioClient dioClient,
    required DatabaseHelper databaseHelper,
    required LocationService locationService,
  }) : _dioClient = dioClient,
       _databaseHelper = databaseHelper,
       _locationService = locationService;

  Future<PrayerTime> getPrayerTimes() async {
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(now);

    // 1. Check Local DB
    final cached = await _databaseHelper.getPrayerTime(dateStr);
    if (cached != null) {
      return cached;
    }

    // 2. Get Location
    final position = await _locationService.determinePosition();

    // 3. Fetch from Aladhan API
    // https://api.aladhan.com/v1/timings/19-02-2026?latitude=51.508515&longitude=-0.1254872&method=2
    final aladhanResponse = await _dioClient.get(
      'https://api.aladhan.com/v1/timings/$dateStr',
      queryParameters: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'method': 2, // ISNA or MWL or whatever default
      },
    );

    // 4. Fetch Location Name (Reverse Geocode)
    // https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=...&longitude=...&localityLanguage=en
    final locationResponse = await _dioClient.get(
      'https://api.bigdatacloud.net/data/reverse-geocode-client',
      queryParameters: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'localityLanguage': 'en',
      },
    );

    final city =
        locationResponse.data['city'] ??
        locationResponse.data['locality'] ??
        'Unknown City';
    final country = locationResponse.data['countryName'] ?? 'Unknown Country';

    // 5. Create Model
    final timings = aladhanResponse.data['data']['timings'];
    final prayerTime = PrayerTime.fromAladhan(timings, dateStr, city, country);

    // 6. Save to DB
    await _databaseHelper.insertPrayerTime(prayerTime);

    return prayerTime;
  }
}
