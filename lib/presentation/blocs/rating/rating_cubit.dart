import 'package:flutter_bloc/flutter_bloc.dart';
import 'rating_state.dart';

class RatingCubit extends Cubit<RatingState> {
  RatingCubit() : super(RatingInitial());

  void setStars(int stars) {
    final current = state is RatingUpdated ? state as RatingUpdated : const RatingUpdated();
    emit(RatingUpdated(stars: stars, selectedTags: current.selectedTags, comment: current.comment));
  }

  void toggleTag(String tag) {
    final current = state is RatingUpdated ? state as RatingUpdated : const RatingUpdated();
    final tags = List<String>.from(current.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    emit(RatingUpdated(stars: current.stars, selectedTags: tags, comment: current.comment));
  }

  void setComment(String comment) {
    final current = state is RatingUpdated ? state as RatingUpdated : const RatingUpdated();
    emit(RatingUpdated(stars: current.stars, selectedTags: current.selectedTags, comment: comment));
  }

  Future<void> submitRating() async {
    final current = state;
    if (current is RatingUpdated) {
      emit(RatingSubmitting(stars: current.stars, selectedTags: current.selectedTags, comment: current.comment));
      await Future.delayed(const Duration(milliseconds: 800));
      emit(const RatingSubmitted());
    }
  }

  void skip() {
    emit(const RatingSkipped());
  }
}
