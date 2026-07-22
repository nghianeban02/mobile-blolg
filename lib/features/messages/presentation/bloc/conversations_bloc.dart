import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/messaging/chat_sounds.dart';
import 'package:mobile/core/services/chat_realtime_service.dart';
import 'package:mobile/data/messaging/chat_models.dart';
import 'package:mobile/data/messaging/messaging_api.dart';
import 'package:mobile/data/repositories/users_repository.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc({
    ChatRealtimeService? realtime,
    BeBlogUsersRepository? usersRepository,
  }) : _realtime = realtime ?? ChatRealtimeService.instance,
       _users = usersRepository ?? BeBlogUsersRepository(),
       super(const ConversationsState()) {
    on<ConversationsStarted>(_onStarted);
    on<ConversationsRefreshRequested>(_onRefresh);
    on<ConversationsQueryChanged>(_onQueryChanged);
    on<ConversationsRealtimeTick>(_onRealtimeTick);
    on<ConversationsCreateDirectRequested>(_onCreateDirect);
    on<ConversationsCreateGroupRequested>(_onCreateGroup);
  }

  final ChatRealtimeService _realtime;
  final BeBlogUsersRepository _users;
  StreamSubscription<ChatRealtimeEvent>? _eventsSub;

  Future<void> _onStarted(
    ConversationsStarted event,
    Emitter<ConversationsState> emit,
  ) async {
    await _realtime.start();
    _eventsSub ??= _realtime.events.listen((e) {
      if (e.type == 'message.created') {
        final senderId = e.payload['senderId'] as String? ?? '';
        final me = state.currentUserId;
        if (me != null && senderId.isNotEmpty && senderId != me) {
          unawaited(ChatSounds.playMessageSound());
        }
      }
      if (e.type == 'message.created' ||
          e.type == 'message.revoked' ||
          e.type == 'conversation.read' ||
          e.type.startsWith('conversation.')) {
        add(const ConversationsRealtimeTick());
      }
    });
    _realtime.addListener(_onRealtimeConnected);
    emit(state.copyWith(connected: _realtime.connected));
    unawaited(
      _users.me().then((result) {
        if (result.success && result.data != null) {
          add(ConversationsRealtimeTick(currentUserId: result.data!.id));
        }
      }),
    );
    await _load(emit);
  }

  void _onRealtimeConnected() {
    add(const ConversationsRealtimeTick());
  }

  Future<void> _onRefresh(
    ConversationsRefreshRequested event,
    Emitter<ConversationsState> emit,
  ) => _load(emit);

  Future<void> _onRealtimeTick(
    ConversationsRealtimeTick event,
    Emitter<ConversationsState> emit,
  ) async {
    if (event.currentUserId != null) {
      emit(state.copyWith(currentUserId: event.currentUserId));
    }
    emit(state.copyWith(connected: _realtime.connected));
    if (event.currentUserId == null) await _load(emit, silent: true);
  }

  void _onQueryChanged(
    ConversationsQueryChanged event,
    Emitter<ConversationsState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onCreateDirect(
    ConversationsCreateDirectRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final id = await MessagingApi.createDirect(event.recipientId);
      await _load(emit);
      emit(state.copyWith(submitting: false, createdConversationId: id));
    } catch (e) {
      emit(state.copyWith(submitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateGroup(
    ConversationsCreateGroupRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final id = await MessagingApi.createGroup(event.title, event.memberIds);
      await _load(emit);
      emit(state.copyWith(submitting: false, createdConversationId: id));
    } catch (e) {
      emit(state.copyWith(submitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> _load(
    Emitter<ConversationsState> emit, {
    bool silent = false,
  }) async {
    if (!silent) {
      emit(
        state.copyWith(status: ConversationsStatus.loading, clearError: true),
      );
    }
    try {
      final items = await MessagingApi.conversations();
      emit(
        state.copyWith(
          status: ConversationsStatus.success,
          conversations: items,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ConversationsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    _realtime.removeListener(_onRealtimeConnected);
    await _eventsSub?.cancel();
    return super.close();
  }
}
