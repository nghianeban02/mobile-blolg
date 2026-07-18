import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/be_blog_http.dart';
import 'package:mobile/data/models/dtos.dart';
import 'package:mobile/data/repositories/feed_repository.dart';
import 'package:mobile/features/home/presentation/bloc/feed_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedRepository extends Mock implements BeBlogFeedRepository {}

void main() {
  late _MockFeedRepository repo;

  setUp(() {
    repo = _MockFeedRepository();
  });

  FeedBloc buildBloc() => FeedBloc(repository: repo);

  group('FeedBloc', () {
    blocTest<FeedBloc, FeedState>(
      'load success with empty feed',
      build: () {
        when(
          () => repo.getHomeFeed(
            page: any(named: 'page'),
            size: any(named: 'size'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => BeBlogRepoResult.ok(const <FeedItemDto>[]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const FeedLoadRequested()),
      expect: () => [
        isA<FeedState>().having((s) => s.status, 'status', FeedStatus.loading),
        isA<FeedState>()
            .having((s) => s.status, 'status', FeedStatus.success)
            .having((s) => s.items, 'items', isEmpty)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'load failure surfaces error',
      build: () {
        when(
          () => repo.getHomeFeed(
            page: any(named: 'page'),
            size: any(named: 'size'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => BeBlogRepoResult.fail(500, 'Server error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const FeedLoadRequested()),
      expect: () => [
        isA<FeedState>().having((s) => s.status, 'status', FeedStatus.loading),
        isA<FeedState>()
            .having((s) => s.status, 'status', FeedStatus.failure)
            .having((s) => s.errorMessage, 'error', contains('Server')),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'refresh with empty items uses loading then failure',
      build: () {
        when(
          () => repo.getHomeFeed(
            page: any(named: 'page'),
            size: any(named: 'size'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => BeBlogRepoResult.fail(0, 'offline'));
        return buildBloc();
      },
      seed: () => const FeedState(status: FeedStatus.success),
      act: (bloc) => bloc.add(const FeedRefreshRequested()),
      expect: () => [
        isA<FeedState>().having((s) => s.status, 'status', FeedStatus.loading),
        isA<FeedState>()
            .having((s) => s.status, 'status', FeedStatus.failure)
            .having((s) => s.errorMessage, 'error', 'offline'),
      ],
    );
  });
}
