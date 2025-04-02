import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.grey,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image(image: AssetImage("assets/logo.png"), height: 50),
            SizedBox(width: 10),
            Text("To-Do App", style: TextStyle(fontWeight: FontWeight.bold),),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: CircleAvatar(
                  radius: 20,
                ),
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/profile_bg.webp"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.1),
                  BlendMode.darken,
                )
              )
            ),
            padding: EdgeInsets.all(20),
            child: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text("Username:", style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),),
                  SizedBox(height: 10),
                  TextField(
                    cursorColor: Colors.black,
                    decoration: textDecor("Username"),
                  ),
                  SizedBox(height: 20),
                  Text("Change Password:", style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),),
                  SizedBox(height: 10),
                  Text("New Password:"),
                  SizedBox(height: 10),
                  TextField(
                    cursorColor: Colors.black,
                    decoration: textDecor("New Password"),
                  ),
                  SizedBox(height: 10),
                  Text("Confirm Password:"),
                  SizedBox(height: 10),
                  TextField(
                    cursorColor: Colors.black,
                    decoration: textDecor("Confirm Password"),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            right: 140,
            top: 85,
            child: ElevatedButton(
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(CircleBorder()),
                backgroundColor: WidgetStatePropertyAll(Colors.white),
                side: WidgetStatePropertyAll(BorderSide(color: Colors.black)),
              ),
              onPressed: () {},
              child: Icon(Icons.edit)
            )
          ),
          Positioned(
            right: 20,
            bottom: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/");
              },
              style: ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.all(18)),
                shape: WidgetStatePropertyAll(CircleBorder()),
                backgroundColor: WidgetStatePropertyAll(Colors.grey[300]),
                side: WidgetStatePropertyAll(BorderSide(color: Colors.black)),
              ),
              child: Icon(Icons.home, size: 20,),
            ),
          )
        ],
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