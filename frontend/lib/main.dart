import 'package:flutter/material.dart';
import 'src/screens/signIn/SignIn.dart'; // Import the signIn.dart file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignInScreen(), // Set SignInScreen as the home widget
    );
  }
}
