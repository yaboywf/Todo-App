// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final username = TextEditingController();
  final password = TextEditingController();

  Future<Map<String, dynamic>> sendAuthentication() async {
    final url = "http://192.168.0.189:3000/api/authenticate";
    final data = {
      "username": username.text,
      "password": password.text
    };

    if (username.text.isEmpty || password.text.isEmpty) {
      return {};
    }
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data)
      );

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey,
        title: Row(
          children: [
            Image(image: AssetImage("assets/logo.png"), height: 50),
            SizedBox(width: 10),
            Text("To-Do App", style: TextStyle(fontWeight: FontWeight.bold),)
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/login_bg.jpg"),
            fit: BoxFit.cover
          )
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Username:", style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold
                )),
                SizedBox(height: 10),
                TextField(
                  cursorColor: Colors.black,
                  controller: username,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: "Username",
                    labelStyle: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black
                    ),
                    hintText: "Enter your username",
                    hintStyle: TextStyle(
                      fontSize: 13.0,
                      color: Colors.black
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.0
                      )
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      )
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0)
                  )
                ),
                SizedBox(height: 20),
                Text("Password:", style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold
                )),
                SizedBox(height: 10),
                TextField(
                  cursorColor: Colors.black,
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black
                    ),
                    hintText: "Enter your password",
                    hintStyle: TextStyle(
                      fontSize: 13.0,
                      color: Colors.black
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.0
                      )
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      )
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0)
                  )
                ),
                SizedBox(height: 20,),
                Center(
                  child: OutlinedButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                      iconColor: Colors.black,
                    ),
                    onPressed: () async {
                      Map<String, dynamic> result = await sendAuthentication();
                      print(result);
                      if (!context.mounted) return;
                      if (result.isNotEmpty && result["message"] == "Authentication failed") {
                        showAlertDialog(context, result["message"]);
                      } else {
                        if (result.containsKey('token')) {
                          String token = result['token'];
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('auth_token', token);
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(context, '/profile');
                        }
                      }
                    },
                    icon: Icon(Icons.login),
                    label: Text("Login", style: TextStyle(
                      color: Colors.black
                    )),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showAlertDialog(BuildContext context, String message) {
// Create an AlertDialog
showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: Text('Alert'),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  },
);}