import 'dart:async';
import 'package:pokecardguess/models/trophy.dart';

class TrophyService {
  // Singleton pattern
  static final TrophyService _instance = TrophyService._internal();
  factory TrophyService() => _instance;
  TrophyService._internal();

  final _trophyUnlockController = StreamController<List<Trophy>>.broadcast();
  Stream<List<Trophy>> get trophyUnlockStream => _trophyUnlockController.stream;

  void showTrophies(List<dynamic> trophyDataList) {
    if (trophyDataList.isEmpty) return;
    
    final List<Trophy> parsedTrophies = [];
    
    for (var data in trophyDataList) {
       try {
         // Handle both raw object and wrapped { trophy: ... } format
         final Map<String, dynamic> dataMap = data is Map<String, dynamic> ? data : {};
         final trophyJson = dataMap['trophy'] != null ? dataMap['trophy'] : dataMap;
         
         if (trophyJson != null && trophyJson.isNotEmpty) {
            parsedTrophies.add(Trophy.fromJson(trophyJson));
         }
       } catch (e) {
         print('Error parsing trophy: $e');
       }
    }

    if (parsedTrophies.isNotEmpty) {
      _trophyUnlockController.add(parsedTrophies);
    }
  }
  
  void dispose() {
    _trophyUnlockController.close();
  }
}
