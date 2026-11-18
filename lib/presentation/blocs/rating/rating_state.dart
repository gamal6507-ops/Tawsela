import 'package:equatable/equatable.dart';

abstract class RatingState extends Equatable {
  const RatingState();
  @override
  List<Object?> get props => [];
}

class RatingInitial extends RatingState {}
class RatingUpdated extends RatingState {
  final int stars;
  final List<String> selectedTags;
  final String comment;
  const RatingUpdated({this.stars = 0, this.selectedTags = const [], this.comment = ''});
  @override
  List<Object?> get props => [stars, selectedTags, comment];
}
class RatingSubmitting extends RatingState {
  final int stars;
  final List<String> selectedTags;
  final String comment;
  const RatingSubmitting({required this.stars, required this.selectedTags, required this.comment});
  @override
  List<Object?> get props => [stars, selectedTags, comment];
}
class RatingSubmitted extends RatingState {
  const RatingSubmitted();
}
class RatingSkipped extends RatingState {
  const RatingSkipped();
}
