import 'package:flutter/material.dart';

import '../config.dart';
import '../data/app_store.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'onboarding.dart';
import 'shell.dart';

class ChalklineApp extends StatefulWidget {
  const ChalklineApp({super.key, required this.store, this.initialCreatorHandle});

  final AppStore store;

  /// From a creator's share link (`/c/<handle>`): open their profile first.
  final String? initialCreatorHandle;

  @override
  State<ChalklineApp> createState() => _ChalklineAppState();
}

class _ChalklineAppState extends State<ChalklineApp> {
  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: widget.store,
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: ClTheme.dark.toThemeData(),
        home: _Root(initialCreatorHandle: widget.initialCreatorHandle),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root({this.initialCreatorHandle});

  final String? initialCreatorHandle;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    if (!store.loaded) return const Scaffold();
    final creator = initialCreatorHandle == null ? null : store.creatorByHandle(initialCreatorHandle!);
    if (store.profile == null) return OnboardingScreen(invitedBy: creator);
    return HomeShell(openCreatorId: creator?.id);
  }
}

/// `/c/marko.lifts` or `#/c/marko.lifts` → `marko.lifts`.
String? creatorHandleFromUri(Uri uri) {
  List<String> segments(String path) => path.split('/').where((s) => s.isNotEmpty).toList();
  for (final s in [uri.pathSegments, segments(uri.fragment)]) {
    final i = s.indexOf('c');
    if (i >= 0 && i + 1 < s.length) return s[i + 1];
  }
  return null;
}
