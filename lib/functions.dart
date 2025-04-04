import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showAlertDialog(BuildContext context, String message, {Function? afterwards}) {
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
              Navigator.of(context).pop();
              if (afterwards != null) {
                afterwards();
              }
            },
          ),
        ],
      );
    },
  )
;}

Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  return token;
}