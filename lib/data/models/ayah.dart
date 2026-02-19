class Ayah {
  final int number;
  final String text;
  final String translation;
  final String surahName;
  final String surahEnglishName;
  final int surahNumber;
  final int numberInSurah;

  Ayah({
    required this.number,
    required this.text,
    required this.translation,
    required this.surahName,
    required this.surahEnglishName,
    required this.surahNumber,
    required this.numberInSurah,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    // Expecting response from http://api.alquran.cloud/v1/ayah/random/editions/quran-uthmani,en.asad
    // The response structure is data: [ {text: ...}, {text: ...} ]
    
    final arabicData = json['data'][0];
    final englishData = json['data'][1];

    return Ayah(
      number: arabicData['number'],
      text: arabicData['text'],
      translation: englishData['text'],
      surahName: arabicData['surah']['name'],
      surahEnglishName: englishData['surah']['englishName'],
      surahNumber: arabicData['surah']['number'],
      numberInSurah: arabicData['numberInSurah'],
    );
  }
}
