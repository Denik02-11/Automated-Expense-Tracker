import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:newapp/auth/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyB4r1E8PExWvnJEck_bhHDcDBCoQQ2OjXU",
            authDomain: "trying-410a0.firebaseapp.com",
            projectId: "trying-410a0",
            storageBucket: "trying-410a0.appspot.com",
            messagingSenderId: "464882402082",
            appId: "1:464882402082:web:7c3bbb61419c2540765b7b"));
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: LoginScreen());
  }
}
