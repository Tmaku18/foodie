import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodie/core/models.dart';
import 'package:foodie/domain/repositories/food_repository.dart';

class DiscoverState extends Equatable {
  const DiscoverState({
    this.restaurants = const [],
    this.visible = const [],
    this.sessionSkipped = const {},
    this.loading = false,
    this.error,
  });

  final List<Restaurant> restaurants;
  final List<Restaurant> visible;
  final Set<int> sessionSkipped;
  final bool loading;
  final String? error;

  DiscoverState copyWith({
    List<Restaurant>? restaurants,
    List<Restaurant>? visible,
    Set<int>? sessionSkipped,
    bool? loading,
    String? error,
  }) {
    return DiscoverState(
      restaurants: restaurants ?? this.restaurants,
      visible: visible ?? this.visible,
      sessionSkipped: sessionSkipped ?? this.sessionSkipped,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [restaurants, visible, sessionSkipped, loading, error];
}

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit(this._repo) : super(const DiscoverState());

  final FoodRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final restaurants = await _repo.getRestaurants();
      emit(state.copyWith(restaurants: restaurants, visible: restaurants, loading: false));
    } catch (_) {
      emit(state.copyWith(loading: false, error: 'Failed to load restaurants'));
    }
  }

  void applyRadius(double miles) {
    final next = state.restaurants
        .where((r) => r.distanceMiles <= miles && !state.sessionSkipped.contains(r.id))
        .toList(growable: false);
    emit(state.copyWith(visible: next));
  }

  Future<void> swipeRight(Restaurant restaurant) async {
    await _repo.addBasketMatch(restaurant.id);
    final nextVisible = state.visible.where((r) => r.id != restaurant.id).toList(growable: false);
    emit(state.copyWith(visible: nextVisible));
  }

  void swipeLeft(Restaurant restaurant, {double? radiusMiles}) {
    final skipped = {...state.sessionSkipped, restaurant.id};
    final filtered = state.restaurants.where((r) {
      if (skipped.contains(r.id)) return false;
      if (radiusMiles != null && r.distanceMiles > radiusMiles) return false;
      return true;
    }).toList(growable: false);
    emit(state.copyWith(sessionSkipped: skipped, visible: filtered));
  }
}
