import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/hive_service.dart';
import 'core/database/seed_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await Seeder.ensureSeeded();
  runApp(const ProviderScope(child: SalesApp()));
}
