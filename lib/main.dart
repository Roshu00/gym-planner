import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/app_store.dart';
import 'data/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore(storage: SharedPrefsStore());
  await store.load();
  runApp(ChalklineApp(store: store, initialCreatorHandle: creatorHandleFromUri(Uri.base)));
}
