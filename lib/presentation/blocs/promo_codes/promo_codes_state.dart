import 'package:equatable/equatable.dart';
import 'package:toktok/domain/models/promo_code.dart';

abstract class PromoCodesState extends Equatable {
  const PromoCodesState();
  @override
  List<Object?> get props => [];
}

class PromoCodesInitial extends PromoCodesState {}
class PromoCodesLoading extends PromoCodesState {}
class PromoCodesLoaded extends PromoCodesState {
  final List<PromoCode> available;
  final List<PromoCode> expired;
  const PromoCodesLoaded({required this.available, required this.expired});
  @override
  List<Object?> get props => [available, expired];
}
class PromoCodeApplying extends PromoCodesState {
  final List<PromoCode> available;
  final List<PromoCode> expired;
  const PromoCodeApplying({required this.available, required this.expired});
  @override
  List<Object?> get props => [available, expired];
}
class PromoCodeApplied extends PromoCodesState {
  final String message;
  final List<PromoCode> available;
  final List<PromoCode> expired;
  const PromoCodeApplied(
    this.message, {
    this.available = const [],
    this.expired = const [],
  });
  @override
  List<Object?> get props => [message, available, expired];
}
class PromoCodeFailed extends PromoCodesState {
  final String message;
  final List<PromoCode> available;
  final List<PromoCode> expired;
  const PromoCodeFailed({required this.message, required this.available, required this.expired});
  @override
  List<Object?> get props => [message, available, expired];
}
