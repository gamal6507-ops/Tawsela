import 'package:flutter_bloc/flutter_bloc.dart';
import 'rating_state.dart';
import 'package:toktok/domain/repositories/rating_repository.dart';

class RatingCubit extends Cubit<RatingState> {
  final RatingRepository _repository;
  RatingCubit(this._repository) : super(RatingInitial());

  void setStars(int stars) {
    if (state is RatingSubmitting || stars < 1 || stars > 5) return;
    final current =
        state is RatingUpdated ? state as RatingUpdated : const RatingUpdated();
    emit(
      RatingUpdated(
        stars: stars,
        selectedTags: current.selectedTags,
        comment: current.comment,
      ),
    );
  }

  void toggleTag(String tag) {
    if (state is RatingSubmitting) return;
    final current =
        state is RatingUpdated ? state as RatingUpdated : const RatingUpdated();
    final tags = List<String>.from(current.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    emit(
      RatingUpdated(
        stars: current.stars,
        selectedTags: tags,
        comment: current.comment,
      ),
    );
  }

  void setComment(String comment) {
    if (state is RatingSubmitting) return;
    final current =
        state is RatingUpdated ? state as RatingUpdated : const RatingUpdated();
    emit(
      RatingUpdated(
        stars: current.stars,
        selectedTags: current.selectedTags,
        comment: comment,
      ),
    );
  }

  Future<void> submitRating({required String tripId}) async {
    final current = state;
    if (current is RatingUpdated &&
        current is! RatingSubmitting &&
        current.stars > 0) {
      emit(
        RatingSubmitting(
          stars: current.stars,
          selectedTags: current.selectedTags,
          comment: current.comment,
        ),
      );
      try {
        await _repository.saveRating(
          tripId,
          current.stars,
          current.selectedTags,
          current.comment,
        );
        if (!isClosed) emit(const RatingSubmitted());
      } catch (_) {
        if (!isClosed) {
          emit(
            RatingFailed(
              stars: current.stars,
              selectedTags: current.selectedTags,
              comment: current.comment,
              message: 'تعذر حفظ التقييم. حاول تاني',
            ),
          );
        }
      }
    }
  }

  void skip() {
    if (state is RatingSubmitting) return;
    emit(const RatingSkipped());
  }

  void reset() => emit(RatingInitial());
}
