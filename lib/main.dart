import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo/auth/authscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:todo/screens/home.dart';
// void main() {
//   runApp(const MyApp());
// }
//void main()=>runApp(new MyApp());
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyAl7V3Oaa7XovOwsQnZuz9FpU2daWIu5Xs',
    appId: '1:147930746945:android:10cfcd3c78a55e594f76c0',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    // ...other options...
  );
  await Firebase.initializeApp(
    options: firebaseOptions,
  );
  runApp( MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context,usersnapshot){
        if(usersnapshot.hasData){return Home();}
        else {
          return AuthScreen();
        }
      },),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.purple,
      ),
    );
  }
}
