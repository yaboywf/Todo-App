import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'functions.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final username = TextEditingController();
  final password = TextEditingController();

  void sendAccountInformation(BuildContext context) async {
    if (username.text.isEmpty || password.text.isEmpty) return;

    final response = await http.post(
        Uri.parse("http://10.102.0.78:3000/api/create_account"),
        headers: {"Content-Type": "application/json"},
        body: json
            .encode({"username": username.text, "password": password.text}));

    if (response.statusCode == 200) {
      if (!context.mounted) return;
      showAlertDialog(context, "Account created",
          afterwards: () => Navigator.pushReplacementNamed(context, "/"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(158, 158, 158, 1),
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
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("New Username:",
                  style:
                      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                cursorColor: Colors.black,
                controller: username,
                keyboardType: TextInputType.name,
                decoration: textDecor("New Username"),
              ),
              SizedBox(height: 20),
              Text("New Password:",
                  style:
                      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SingleChildScrollView(
                child: TextField(
                  cursorColor: Colors.black,
                  controller: password,
                  keyboardType: TextInputType.text,
                  obscureText: true,
                  decoration: textDecor("New Password"),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                child: OutlinedButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                    iconColor: Colors.black,
                  ),
                  onPressed: () {
                    sendAccountInformation(context);
                  },
                  icon: Icon(Icons.create),
                  label: Text("Create", style: TextStyle(color: Colors.black)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration textDecor(String hintText) {
    return InputDecoration(
      labelText: hintText,
      labelStyle: TextStyle(
        color: Colors.black,
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: Colors.black,
        fontSize: 14,
      ),
      hintText: "Enter $hintText",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.black),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.black),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 10.0),
    );
  }
}
