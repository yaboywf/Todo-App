import 'package:flutter/material.dart';
import './login.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Todo App',
    routes: {
      "/": (context) => const Login(),
    },
  ));
}