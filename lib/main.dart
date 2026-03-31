import 'package:flutter/material.dart';
import 'package:foodie/app/app.dart';
import 'package:foodie/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const FoodieApp());
}
