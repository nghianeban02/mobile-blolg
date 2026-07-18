part of 'conversations_bloc.dart';

enum ConversationsStatus { initial, loading, success, failure }

final class ConversationsState extends Equatable {
  final ConversationsStatus status;
  final List<ChatConversation> conversations;
  final String query;
  final String? currentUserId;
  final bool connected;
  final bool submitting;
  final String? errorMessage;
  final String? createdConversationId;

  const ConversationsState({
    this.status = ConversationsStatus.initial,
    this.conversations = const [],
    this.query = '',
    this.currentUserId,
    this.connected = false,
    this.submitting = false,
    this.errorMessage,
    this.createdConversationId,
  });

  List<ChatConversation> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations
        .where(
          (item) => item.displayName(currentUserId).toLowerCase().contains(q),
        )
        .toList();
  }

  ConversationsState copyWith({
    ConversationsStatus? status,
    List<ChatConversation>? conversations,
    String? query,
    String? currentUserId,
    bool? connected,
    bool? submitting,
    String? errorMessage,
    String? createdConversationId,
    bool clearError = false,
    bool clearCreated = false,
  }) {
    return ConversationsState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      query: query ?? this.query,
      currentUserId: currentUserId ?? this.currentUserId,
      connected: connected ?? this.connected,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdConversationId: clearCreated
          ? null
          : (createdConversationId ?? this.createdConversationId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversations,
    query,
    currentUserId,
    connected,
    submitting,
    errorMessage,
    createdConversationId,
  ];
}
