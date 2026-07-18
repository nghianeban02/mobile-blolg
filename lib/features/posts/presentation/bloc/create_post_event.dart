part of 'create_post_bloc.dart';

sealed class CreatePostEvent extends Equatable {
  const CreatePostEvent();

  @override
  List<Object?> get props => const [];
}

final class CreatePostSubmitted extends CreatePostEvent {
  final String title;
  final String content;
  final File? titleImageFile;
  final List<File> galleryImageFiles;

  const CreatePostSubmitted({
    required this.title,
    required this.content,
    this.titleImageFile,
    this.galleryImageFiles = const [],
  });

  @override
  List<Object?> get props => [
    title,
    content,
    titleImageFile,
    galleryImageFiles,
  ];
}
