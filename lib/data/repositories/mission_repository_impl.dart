import '../../domain/entities/mission.dart';
import '../../domain/repositories/mission_repository.dart';
import '../services/mission_service.dart';

class MissionRepositoryImpl implements MissionRepository {
  MissionRepositoryImpl({required MissionService service}) : _service = service;

  final MissionService _service;

  static const demoMissions = [
    const Mission(
      id: 'demo-mission-au',
      name: 'African Union Summit',
      code: 'au-summit',
      status: MissionStatus.active,
      description: 'VIP fleet and protocol transport for AU Summit events',
    ),
    const Mission(
      id: 'demo-mission-comilog',
      name: 'COMILOG Contract',
      code: 'comilog',
      status: MissionStatus.active,
      description: 'Long-term corporate contract with COMILOG',
    ),
    const Mission(
      id: 'demo-mission-airport',
      name: 'Airport Transfer',
      code: 'airport-transfer',
      status: MissionStatus.active,
      description: 'Airport pickup and drop-off services',
    ),
    const Mission(
      id: 'demo-mission-private',
      name: 'Private Client Rental',
      code: 'private-client',
      status: MissionStatus.active,
      description: 'Individual and private corporate client rentals',
    ),
  ];

  @override
  Future<List<Mission>> fetchActiveMissions() async {
    if (!_service.isAvailable) return demoMissions;

    final models = await _service.fetchActiveMissions();
    return models.map((model) => model.toEntity()).toList();
  }
}
