import 'package:flutter/material.dart';
import './login.dart';
import './profile.dart';
import './tasks.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Todo App',
    initialRoute: "/tasks",
    routes: {
      "/": (context) => const Login(),
      "/tasks": (context) => const Tasks(),
      "/profile": (context) => const ProfilePage(),
    },
  ));
}