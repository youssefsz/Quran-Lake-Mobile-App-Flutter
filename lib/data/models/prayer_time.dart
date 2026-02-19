class PrayerTime {
  final String date;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String city;
  final String country;

  PrayerTime({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.city,
    required this.country,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      date: json['date'] ?? '',
      fajr: json['fajr'] ?? '',
      sunrise: json['sunrise'] ?? '',
      dhuhr: json['dhuhr'] ?? '',
      asr: json['asr'] ?? '',
      maghrib: json['maghrib'] ?? '',
      isha: json['isha'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'city': city,
      'country': country,
    };
  }

  // Helper to create from Aladhan API response structure if needed
  factory PrayerTime.fromAladhan(Map<String, dynamic> timings, String date, String city, String country) {
    return PrayerTime(
      date: date,
      fajr: timings['Fajr'],
      sunrise: timings['Sunrise'],
      dhuhr: timings['Dhuhr'],
      asr: timings['Asr'],
      maghrib: timings['Maghrib'],
      isha: timings['Isha'],
      city: city,
      country: country,
    );
  }
}
