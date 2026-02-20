class Reciter {
  final int id;
  final String name;
  final String letter;
  final List<Moshaf> moshaf;

  Reciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.moshaf,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'] as int,
      name: json['name'] as String,
      letter: json['letter'] as String? ?? '',
      moshaf:
          (json['moshaf'] as List<dynamic>?)
              ?.map((e) => Moshaf.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Moshaf {
  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final String surahList;

  Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.surahList,
  });

  factory Moshaf.fromJson(Map<String, dynamic> json) {
    return Moshaf(
      id: json['id'] as int,
      name: json['name'] as String,
      server: json['server'] as String,
      surahTotal: json['surah_total'] as int,
      surahList: json['surah_list'] as String,
    );
  }

  List<int> get availableSurahs {
    return surahList.split(',').map((e) => int.tryParse(e) ?? 0).toList();
  }
}
