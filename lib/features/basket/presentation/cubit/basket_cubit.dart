import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodie/core/models.dart';
import 'package:foodie/domain/repositories/food_repository.dart';

class BasketState extends Equatable {
  const BasketState({this.matches = const [], this.loading = false, this.clearing = false});

  final List<BasketMatch> matches;
  final bool loading;
  final bool clearing;

  BasketState copyWith({List<BasketMatch>? matches, bool? loading, bool? clearing}) {
    return BasketState(
      matches: matches ?? this.matches,
      loading: loading ?? this.loading,
      clearing: clearing ?? this.clearing,
    );
  }

  @override
  List<Object?> get props => [matches, loading, clearing];
}

class BasketCubit extends Cubit<BasketState> {
  BasketCubit(this._repo) : super(const BasketState());

  final FoodRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final matches = await _repo.getBasketMatches();
    emit(state.copyWith(matches: matches, loading: false));
  }

  Future<void> removeMatch(int matchId) async {
    await _repo.removeBasketMatch(matchId);
    await load();
  }

  Future<void> emptyBasket() async {
    emit(state.copyWith(clearing: true));
    await _repo.clearBasket();
    await load();
    emit(state.copyWith(clearing: false));
  }
}
