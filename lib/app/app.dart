import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../data/app_store.dart';
import '../data/auth.dart';
import '../ui/chalkline_ui.dart';
import 'auth_screen.dart';
import 'common.dart';
import 'onboarding.dart';
import 'shell.dart';

/// Local mode: pass [store]. Cloud mode: pass [auth] and [storeFor], which
/// builds a store for each signed-in account.
class ChalklineApp extends StatelessWidget {
  const ChalklineApp({super.key, required AppStore this.store, this.initialCreatorHandle})
    : auth = null,
      storeFor = null;

  const ChalklineApp.cloud({
    super.key,
    required AuthService this.auth,
    required AppStore Function(AuthUser user) this.storeFor,
    this.initialCreatorHandle,
  }) : store = null;

  final AppStore? store;
  final AuthService? auth;
  final AppStore Function(AuthUser user)? storeFor;

  /// From a creator's share link (`/c/<handle>`): open their profile first.
  final String? initialCreatorHandle;

  static MaterialApp _material({Key? key, required Widget home}) => MaterialApp(
    key: key,
    title: appName,
    debugShowCheckedModeBanner: false,
    theme: ClTheme.dark.toThemeData(),
    home: home,
  );

  @override
  Widget build(BuildContext context) {
    if (store != null) {
      return AppScope(
        store: store!,
        child: _material(home: _Root(initialCreatorHandle: initialCreatorHandle)),
      );
    }
    return _CloudRoot(auth: auth!, storeFor: storeFor!, initialCreatorHandle: initialCreatorHandle);
  }
}

/// Follows the signed-in account and gives each one its own store.
class _CloudRoot extends StatefulWidget {
  const _CloudRoot({required this.auth, required this.storeFor, this.initialCreatorHandle});

  final AuthService auth;
  final AppStore Function(AuthUser user) storeFor;
  final String? initialCreatorHandle;

  @override
  State<_CloudRoot> createState() => _CloudRootState();
}

class _CloudRootState extends State<_CloudRoot> {
  late AuthUser? _user = widget.auth.current;
  AppStore? _store;
  StreamSubscription<AuthUser?>? _sub;

  @override
  void initState() {
    super.initState();
    _open(_user);
    _sub = widget.auth.changes.listen((u) {
      if (!mounted) return;
      setState(() {
        _user = u;
        _open(u);
      });
    });
  }

  void _open(AuthUser? u) {
    if (u == null) {
      _store?.dispose();
      _store = null;
    } else if (_store?.account?.id != u.id) {
      _store?.dispose();
      _store = widget.storeFor(u)..load();
    } else {
      // Same person, e.g. a guest who just saved an account.
      _store!.updateAccount(u);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (_user == null || store == null) {
      return ChalklineApp._material(
        key: const ValueKey('signed-out'),
        home: AuthScreen(auth: widget.auth),
      );
    }
    return AppScope(
      store: store,
      // A new navigator per account, so nothing from the last one stays open.
      child: ChalklineApp._material(
        key: ValueKey(store.account!.id),
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
    if (!store.loaded) {
      return Scaffold(
        body: Center(child: Text('UČITAVANJE', style: context.clText.label)),
      );
    }
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
