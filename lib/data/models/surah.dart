class Surah {
  final int id;
  final String name;
  final int makkia; // 1 for Makkia, 0 for Madinia (usually)
  final int startPage;
  final int endPage;

  Surah({
    required this.id,
    required this.name,
    required this.makkia,
    required this.startPage,
    required this.endPage,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'] as int,
      name: json['name'] as String,
      makkia: json['makkia'] as int? ?? 0,
      startPage: json['start_page'] as int? ?? 0,
      endPage: json['end_page'] as int? ?? 0,
    );
  }

  bool get isMakkia => makkia == 1;
}
