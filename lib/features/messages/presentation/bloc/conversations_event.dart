part of 'conversations_bloc.dart';

sealed class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object?> get props => const [];
}

final class ConversationsStarted extends ConversationsEvent {
  const ConversationsStarted();
}

final class ConversationsRefreshRequested extends ConversationsEvent {
  const ConversationsRefreshRequested();
}

final class ConversationsQueryChanged extends ConversationsEvent {
  final String query;
  const ConversationsQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

final class ConversationsRealtimeTick extends ConversationsEvent {
  final String? currentUserId;
  const ConversationsRealtimeTick({this.currentUserId});

  @override
  List<Object?> get props => [currentUserId];
}

final class ConversationsCreateDirectRequested extends ConversationsEvent {
  final String recipientId;
  const ConversationsCreateDirectRequested(this.recipientId);

  @override
  List<Object?> get props => [recipientId];
}

final class ConversationsCreateGroupRequested extends ConversationsEvent {
  final String title;
  final List<String> memberIds;
  const ConversationsCreateGroupRequested({
    required this.title,
    required this.memberIds,
  });

  @override
  List<Object?> get props => [title, memberIds];
}
