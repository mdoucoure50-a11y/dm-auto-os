import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mission_repository_impl.dart';
import '../data/repositories/rental_repository_impl.dart';
import '../data/services/mission_service.dart';
import '../data/services/rental_service.dart';
import '../domain/entities/mission.dart';
import '../domain/repositories/mission_repository.dart';
import '../domain/repositories/rental_repository.dart';
import 'auth_provider.dart';
import 'supabase_provider.dart';

final missionServiceProvider = Provider<MissionService>((ref) {
  return MissionService(ref.watch(supabaseDatabaseServiceProvider));
});

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepositoryImpl(service: ref.watch(missionServiceProvider));
});

final rentalServiceProvider = Provider<RentalService>((ref) {
  return RentalService(ref.watch(supabaseDatabaseServiceProvider));
});

final rentalRepositoryProvider = Provider<RentalRepository>((ref) {
  return RentalRepositoryImpl(service: ref.watch(rentalServiceProvider));
});

final missionsProvider = FutureProvider.autoDispose<List<Mission>>((ref) async {
  return ref.watch(missionRepositoryProvider).fetchActiveMissions();
});

final rentalsProvider =
    FutureProvider.autoDispose<List<RentalAgreement>>((ref) async {
  return ref.watch(rentalRepositoryProvider).fetchRentals();
});

class RentalController extends StateNotifier<AsyncValue<void>> {
  RentalController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<RentalAgreement> createRental(RentalAgreementInput input) async {
    state = const AsyncLoading();
    late RentalAgreement rental;

    state = await AsyncValue.guard(() async {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw StateError('Not authenticated');

      rental = await _ref.read(rentalRepositoryProvider).createRental(
            input,
            createdByUserId: user.id,
          );
      _ref.invalidate(rentalsProvider);
    });

    if (state.hasError) throw state.error!;
    return rental;
  }
}

final rentalControllerProvider =
    StateNotifierProvider<RentalController, AsyncValue<void>>((ref) {
  return RentalController(ref);
});
