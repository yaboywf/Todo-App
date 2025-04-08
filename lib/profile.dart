import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Map<String, dynamic>>? user;
  late TextEditingController usernameController;
  File? image;
  final ImagePicker picker = ImagePicker();
  late bool imagePicked = false;
  String currentUsername = "";

  Future<void> validateSession(BuildContext context) async {
    String? token = await getToken();

    if (token == null) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, "/");
    }

    try {
      final response = await http.get(
        Uri.parse("http://10.102.0.78:3000/api/check_session"),
        headers: {
          'authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, "/");
      }

      Map data = json.decode(response.body);
      if (data["valid"] == false) {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, "/");
      } else {
        if (!context.mounted) return;
        setState(() {
          user = getUserData(context);
        });
      }
    } catch (err) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, "/");
    }
  }

  Future<Map<String, dynamic>> getUserData(BuildContext context) async {
    String? token = await getToken();

    try {
      final response = await http.get(
        Uri.parse("http://10.102.0.78:3000/api/get_user_data"),
        headers: {
          'authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        if (!context.mounted) return {};
        showAlertDialog(context, "Unable to get user data");
        return {};
      }

      Map<String, dynamic> data = json.decode(response.body);
      return data;
    } catch (err) {
      if (!context.mounted) return {};
      showAlertDialog(context, "Unable to get user data");
      return {};
    }
  }

  Future<void> logout(BuildContext context) async {
    String? token = await getToken();
    final response = await http.post(
        Uri.parse("http://10.102.0.78:3000/api/logout"),
        headers: {'authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, "/");
    } else {
      if (!context.mounted) return;
      showAlertDialog(context, "Unable to logout");
      return;
    }
  }

  Future<void> updateUsername(BuildContext context) async {
    String newUsername = usernameController.text;
    String? token = await getToken();

    if (newUsername.isEmpty) {
      if (!context.mounted) return;
      showAlertDialog(context, "Username cannot be empty");
      return;
    }

    if (newUsername == currentUsername) return;

    final response = await http.put(
        Uri.parse("http://10.102.0.78:3000/api/update_user_data/username"),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token'
        },
        body: json.encode({"username": newUsername}));

    if (response.statusCode == 200) {
      if (!context.mounted) return;
      showAlertDialog(context, "Username updated successfully",
          afterwards: () =>
              Navigator.pushReplacementNamed(context, "/profile"));
    } else if (response.statusCode == 403) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, "/");
    } else {
      if (!context.mounted) return;
      showAlertDialog(context, "Unable to update username");
      return;
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
        imagePicked = true;
      });
    }
  }

  Future<void> updateImage(BuildContext context) async {
    String? token = await getToken();

    if (image == null) {
      if (!context.mounted) return;
      showAlertDialog(context, "No image selected");
      return;
    }

    List<int> imageBytes = await image!.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    var jsonBody = json.encode({
      "image": base64Image,
    });

    var uri = Uri.parse("http://10.102.0.78:3000/api/update_user_data/image");
    var request = http.Request('PUT', uri);
    request.headers['Content-Type'] = 'application/json';
    request.headers['authorization'] = 'Bearer $token';
    request.body = jsonBody;
    var response = await request.send();

    if (response.statusCode == 200) {
      if (!context.mounted) return;
      showAlertDialog(context, "User Profile Image updated successfully", afterwards: () =>
              Navigator.pushReplacementNamed(context, "/profile"));
    } else if (response.statusCode == 403) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, "/");
    } else {
      if (!context.mounted) return;
      showAlertDialog(context, "Unable to update image");
      return;
    }
  }

  void deleteAccount(BuildContext context) {
    void sendDelete(BuildContext context1) async {
      String? token = await getToken();

      final response = await http.delete(
        Uri.parse("http://10.102.0.78:3000/api/delete_account"),
        headers: {
          "Content-Type": "application/json",
          "authorization": "Bearer $token"
        }
      );

      if (response.statusCode == 200) {
        if (!context1.mounted) return;
        showAlertDialog(context1, "Account deleted", afterwards: () => Navigator.pushReplacementNamed(context1, "/"));
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => AlertDialog(
            title: Text("Delete Account"),
            content: Text("Are you sure you want to delete your account? This cannot be undone."),
            actions: <Widget>[
              TextButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                  child: Text(
                    "Delete",
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () => sendDelete(context))
            ],
          )
        );
      }
    );
  }

  @override
  void initState() {
    super.initState();
    validateSession(context);
  }

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
                child: IconButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, "/profile"),
                  icon: Icon(Icons.account_circle),
                ),
              ),
            )
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.black,),
                  SizedBox(height: 10),
                  Text('Loading...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            var userData = snapshot.data!;
            var base64Image = userData['user_image'];
            var username = userData['username'];

            currentUsername = username;
            Uint8List decodedImage = base64Decode(base64Image);
            usernameController = TextEditingController(text: username);

            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/profile_bg.webp"),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.1),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: image != null ? FileImage(image!) : MemoryImage(decodedImage),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text("Username:", style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),),
                      SizedBox(height: 10),
                      TextField(
                        controller: usernameController,
                        cursorColor: Colors.black,
                        decoration: textDecor("Username"),
                      ),
                      SizedBox(height: 20),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  updateUsername(context);
                                  if (imagePicked) updateImage(context);
                                },
                                label: Text("Save", style: TextStyle(color: Colors.black),),
                                icon: Icon(Icons.save, color: Colors.black),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  side: BorderSide(color: Colors.black),
                                ),
                              ),
                              SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () => logout(context),
                                label: Text("Logout", style: TextStyle(color: Colors.black),),
                                icon: Icon(Icons.lock, color: Colors.black,),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  side: BorderSide(color: Colors.black),
                                ),
                              ),
                            ]
                          ),
                          OutlinedButton.icon(
                            onPressed: () => deleteAccount(context),
                            label: Text("Delete Account", style: TextStyle(color: Colors.black),),
                            icon: Icon(Icons.delete, color: Colors.black,),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              side: BorderSide(color: Colors.black),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                Positioned(
                  right: 140,
                  top: 85,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black),
                    ),
                    onPressed: () => pickImage(),
                    child: Icon(Icons.edit, color: Colors.black),
                  ),
                ),
              ],
            );
          } else {
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/profile_bg.webp"),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.1),
                    BlendMode.darken,
                  ),
                )
              ),
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No data found', style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                    ),),
                    SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, "/"),
                      child: Icon(Icons.refresh)
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushReplacementNamed(context, "/tasks"),
        shape: CircleBorder(),
        backgroundColor: Colors.white,
        child: Icon(Icons.home, color: Colors.black,),
      )
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
