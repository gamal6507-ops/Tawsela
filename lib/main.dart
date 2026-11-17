import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:toktok/app.dart';
import 'package:toktok/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TawselaApp());
}
