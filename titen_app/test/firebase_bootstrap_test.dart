import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titen_app/core/services/firebase_bootstrap.dart';
import 'package:titen_app/features/dashboard/application/dashboard_providers.dart';
import 'package:titen_app/features/dashboard/data/repositories/mock_node_repository.dart';

void main() {
  group('Firebase startup and data source isolation', () {
    test(
      'Live exposes bootstrap failure without constructing a repository',
      () async {
        final bootstrapError = StateError(
          'Synthetic Firebase bootstrap failure',
        );
        var bootstrapCalls = 0;
        var repositoryCalls = 0;
        final container = ProviderContainer(
          overrides: [
            firebaseBootstrapProvider.overrideWith((ref) async {
              bootstrapCalls++;
              throw bootstrapError;
            }),
            nodeRepositoryProvider.overrideWith((ref) {
              repositoryCalls++;
              throw StateError('Repository must wait for successful bootstrap');
            }),
          ],
        );
        addTearDown(container.dispose);

        await expectLater(
          container
              .read(allNodesProvider.future)
              .timeout(const Duration(seconds: 2)),
          throwsA(same(bootstrapError)),
        );

        expect(container.read(dataSourceModeProvider), DataSourceMode.live);
        expect(container.read(allNodesProvider).hasError, isTrue);
        expect(bootstrapCalls, 1);
        expect(repositoryCalls, 0);
      },
    );

    test(
      'DEMO serves its three synthetic nodes without Firebase bootstrap',
      () async {
        var bootstrapCalls = 0;
        final container = ProviderContainer(
          overrides: [
            dataSourceModeProvider.overrideWith((ref) => DataSourceMode.demo),
            firebaseBootstrapProvider.overrideWith((ref) async {
              bootstrapCalls++;
              throw StateError('DEMO must not initialize Firebase');
            }),
          ],
        );
        addTearDown(container.dispose);

        final nodes = await container
            .read(allNodesProvider.future)
            .timeout(const Duration(seconds: 2));

        expect(nodes.map((node) => node.nodeId), orderedEquals([1, 2, 3]));
        expect(
          nodes.every((node) => node.name.contains('[DEMO/SINTETIS]')),
          isTrue,
        );
        expect(
          container.read(nodeRepositoryProvider),
          isA<MockNodeRepository>(),
        );
        expect(bootstrapCalls, 0);
      },
    );

    test(
      'Switching to DEMO does not wait for pending Live bootstrap',
      () async {
        final pendingBootstrap = Completer<FirebaseApp>();
        var bootstrapCalls = 0;
        var liveRepositoryCalls = 0;
        final container = ProviderContainer(
          overrides: [
            firebaseBootstrapProvider.overrideWith((ref) {
              bootstrapCalls++;
              return pendingBootstrap.future;
            }),
            nodeRepositoryProvider.overrideWith((ref) {
              final mode = ref.watch(dataSourceModeProvider);
              if (mode.isLive) {
                liveRepositoryCalls++;
                throw StateError(
                  'Pending bootstrap must not construct Live data',
                );
              }
              final repository = MockNodeRepository();
              ref.onDispose(repository.dispose);
              return repository;
            }),
          ],
        );
        addTearDown(container.dispose);

        // Keep a real consumer subscribed across the source-mode change.
        final subscription = container.listen(
          allNodesProvider,
          (previous, next) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);

        expect(container.read(allNodesProvider).isLoading, isTrue);
        expect(bootstrapCalls, 1);
        expect(liveRepositoryCalls, 0);

        container.read(dataSourceModeProvider.notifier).state =
            DataSourceMode.demo;
        final nodes = await container
            .read(allNodesProvider.future)
            .timeout(const Duration(seconds: 2));

        expect(nodes.map((node) => node.nodeId), orderedEquals([1, 2, 3]));
        expect(
          nodes.every((node) => node.name.contains('[DEMO/SINTETIS]')),
          isTrue,
        );
        expect(pendingBootstrap.isCompleted, isFalse);
        expect(bootstrapCalls, 1);
        expect(liveRepositoryCalls, 0);
      },
    );
  });
}
