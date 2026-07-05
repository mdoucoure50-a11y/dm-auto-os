import '../entities/mission.dart';

abstract interface class MissionRepository {
  Future<List<Mission>> fetchActiveMissions();
}
