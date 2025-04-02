import 'package:flutter/material.dart';
import './login.dart';
import './profile.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Todo App',
    initialRoute: "/profile",
    routes: {
      "/": (context) => const Login(),
      "/profile": (context) => const ProfilePage(),
    },
  ));
}