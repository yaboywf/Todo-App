// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'functions.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final username = TextEditingController();
  final password = TextEditingController();

  Future<Map<String, dynamic>> sendAuthentication() async {
    final url = "http://10.102.0.78:3000/api/authenticate";
    final data = {"username": username.text, "password": password.text};

    if (username.text.isEmpty || password.text.isEmpty) {
      return {};
    }

    try {
      final response = await http.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: json.encode(data));

      Map<String, dynamic> userMap = json.decode(response.body);
      return userMap;
    } catch (err) {
      print(err);
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey,
        title: Row(
          children: [
            Image(image: AssetImage("assets/logo.png"), height: 50),
            SizedBox(width: 10),
            Text(
              "To-Do App",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/tasks");
                  },
                  icon: Icon(Icons.menu),
                ),
              ),
            )
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/login_bg.jpg"), fit: BoxFit.cover)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 130.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Username:",
                  style:
                      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                  cursorColor: Colors.black,
                  controller: username,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                      labelText: "Username",
                      labelStyle:
                          TextStyle(fontSize: 14.0, color: Colors.black),
                      hintText: "Enter your username",
                      hintStyle: TextStyle(fontSize: 13.0, color: Colors.black),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 1.0)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          )),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 10.0))),
              SizedBox(height: 20),
              Text("Password:",
                  style:
                      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                  cursorColor: Colors.black,
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle:
                          TextStyle(fontSize: 14.0, color: Colors.black),
                      hintText: "Enter your password",
                      hintStyle: TextStyle(fontSize: 13.0, color: Colors.black),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 1.0)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          )),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 10.0))),
              SizedBox(
                height: 20,
              ),
              Center(
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 5.0),
                        iconColor: Colors.black,
                      ),
                      onPressed: () async {
                        Map<String, dynamic> result =
                            await sendAuthentication();
                        if (!context.mounted) return;
                        if (result.isNotEmpty &&
                            result["message"] == "Authentication failed") {
                          showAlertDialog(context, "Authentication Failed");
                        } else {
                          if (result.containsKey('token')) {
                            String token = result['token'];
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setString('auth_token', token);
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, '/tasks');
                          }
                        }
                      },
                      icon: Icon(Icons.login),
                      label:
                          Text("Login", style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 5.0),
                        iconColor: Colors.black,
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/account');
                      },
                      child: Text("I don't have an account",
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
