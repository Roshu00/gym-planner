import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'app/app.dart';
import 'data/app_store.dart';
import 'data/storage.dart';
import 'data/supabase_backend.dart';

/// With Supabase settings (`--dart-define-from-file=supabase.json`) the app
/// uses accounts and the server; without them it runs as a local demo.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final handle = creatorHandleFromUri(Uri.base);

  if (!SupabaseConfig.isConfigured) {
    final store = AppStore(storage: SharedPrefsStore());
    await store.load();
    runApp(ChalklineApp(store: store, initialCreatorHandle: handle));
    return;
  }

  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  final client = Supabase.instance.client;
  final auth = SupabaseAuthService(client);
  runApp(
    ChalklineApp.cloud(
      auth: auth,
      initialCreatorHandle: handle,
      storeFor: (user) => AppStore(
        storage: SharedPrefsStore(),
        remote: SupabaseRemote(client, user.id),
        auth: auth,
        account: user,
      ),
    ),
  );
}
