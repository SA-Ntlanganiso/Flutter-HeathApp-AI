// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Repositories
import 'package:agcare_plus/core/repositories/cycle_event_repository.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // External dependencies
  await _initExternalDependencies();
  
  // Repositories
  getIt.registerLazySingleton<CycleEventRepository>(
    () => CycleEventRepository(getIt<DbCollection>()),
  );
}

Future<void> _initExternalDependencies() async {
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Initialize MongoDB
  try {
    final db = Db('mongodb+srv://Sinalo-Alizwa-Ntlanganiso:%40\$inalO05262001@agcarecluster.kapy0gn.mongodb.net/agcare');
    await db.open();
    getIt.registerLazySingleton<Db>(() => db);
    getIt.registerLazySingleton<DbCollection>(
      () => db.collection('cycle_events'),
    );
    print('MongoDB connection successful');
  } catch (e) {
    print('Failed to connect to MongoDB: $e');
    throw Exception('Failed to initialize database');
  }
}