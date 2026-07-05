import '../models/mission_models.dart';
import 'supabase_database_service.dart';

class MissionService {
  MissionService(this._databaseService);

  final SupabaseDatabaseService _databaseService;

  bool get isAvailable => _databaseService.isAvailable;

  Future<List<MissionModel>> fetchActiveMissions() async {
    return _databaseService.execute(() async {
      final rows = await _databaseService
          .from('missions')
          .select()
          .eq('status', 'active')
          .isFilter('deleted_at', null)
          .order('name') as List<dynamic>;

      return rows
          .cast<Map<String, dynamic>>()
          .map(MissionModel.fromJson)
          .toList();
    }, errorMessage: 'Failed to load missions');
  }
}
