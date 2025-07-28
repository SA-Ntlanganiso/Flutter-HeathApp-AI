
import 'package:agcare_plus/features/menstrual_tracker/presentation/providers/menstrual_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/navigation/auth_wrapper.dart';
import 'core/navigation/app_router.dart'; 

final nullableSharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);
final nullableMongoDbProvider = Provider<Db?>((ref) => null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences? sharedPrefs;
  Db? db;
  
  try {
    sharedPrefs = await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences initialized successfully');
  } catch (e) {
    debugPrint('SharedPreferences initialization failed: $e');
  }

  try {
    db = Db('');
    await db.open();
    debugPrint('MongoDB connected successfully');
  } catch (e) {
    debugPrint('MongoDB connection failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        if (sharedPrefs != null) 
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        if (db != null) 
          mongoDbProvider.overrideWithValue(db),
      ],
      child: const AGCarePlusApp(),
    ),
  );
}

class AGCarePlusApp extends ConsumerWidget { 
  const AGCarePlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {  
    return MaterialApp(
      title: 'AGCare+',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) => AppRouter.generateRoute(settings, ref), 
    );
  }
}
