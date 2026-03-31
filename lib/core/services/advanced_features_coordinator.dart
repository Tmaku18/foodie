import 'dart:async';

import 'package:foodie/core/services/background_picks_service.dart';
import 'package:foodie/domain/repositories/food_repository.dart';

class AdvancedFeaturesCoordinator {
  AdvancedFeaturesCoordinator(this._picksService, this._repository);

  final BackgroundPicksService _picksService;
  final FoodRepository _repository;
  Timer? _timer;

  Future<void> start() async {
    await _picksService.runCycle(_repository);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 4), (_) async {
      await _picksService.runCycle(_repository);
    });
  }
}
