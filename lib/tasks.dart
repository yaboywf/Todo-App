// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'functions.dart';

class Tasks extends StatefulWidget {
  const Tasks({super.key});

  @override
  State<Tasks> createState() => _TasksState();
}

class _TasksState extends State<Tasks> {
  // final Map<String, dynamic> tasks = {
  //   "Complete the Project Report": {
  //     "due": "2023-12-31",
  //     "completed": false,
  //     "subtasks": {
  //       "Gather all data from team membersssssss": {
  //         "due": "2023-12-31",
  //         "completed": false,
  //       },
  //       "Write report": {
  //         "due": "2023-12-31",
  //         "completed": true,
  //       },
  //       "Submit report": {
  //         "due": "2023-12-31",
  //         "completed": false,
  //       }
  //     }
  //   },
  //   "Prepare for Team Meeting": {
  //     "due": "2023-12-31",
  //     "completed": false,
  //     "subtasks": {}
  //   }
  // };


  Map<String, dynamic> tasks = {};

  Future<void> validateSession(BuildContext context) async {
    String? token = await getToken();

    if (token == null) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, "/");
    }

    try {
      final response = await http.get(
        Uri.parse("http://192.168.0.189:3000/api/check_session"),
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
      }
    } catch (err) {
      print(err);
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, "/");
    }
  }

  Future<void> getParentTasks() async {
    String? token = await getToken();

    try {
      final response = await http.get(
        Uri.parse("http://192.168.0.189:3000/api/get_parent_tasks"),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(json.decode(response.body));
        Map<String, dynamic> tasksMap = {
          for (var i = 0; i < data.length; i++) data[i]["task_name"]: data[i]
        };
        setState(() => tasks = tasksMap);
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (err) {
      print(err);
    }
  }

  @override
  void initState() {
    super.initState();
    validateSession(context);
    getParentTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/profile");
                  },
                  icon: Icon(Icons.account_circle),
                ),
              ),
            )
          ],
        ),
      ),
      body: tasks.isEmpty ? Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          String taskName = tasks.keys.toList()[index];
          bool completed = tasks.values.toList()[index]["completed"];
          String? due = tasks.values.toList()[index]["due_date"];
          int parentIndex = tasks.values.toList()[index]["id"];
          Map<dynamic, dynamic> subtasks = tasks.values.toList()[index]["subtasks"];

          return GestureDetector(
            onLongPress: () {
              print("long press");
            },
            child: tasks["tasks"] == "no tasks" ? Center(child: Text("No tasks")) : Card(
              key: ValueKey("parent-$parentIndex"),
              color: completed ? Colors.green[200] : Colors.transparent,
              margin: EdgeInsets.all(10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.black),
              ),
              child: ExpansionTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.black),
                ),
                leading: Checkbox(
                  activeColor: Colors.black,
                  value: completed,
                  onChanged: (bool? value) {
                    setState(() {
                      tasks[taskName]["completed"] = value!;
                      tasks[taskName]["subtasks"].forEach((key, value) {
                        tasks[taskName]["subtasks"][key]["completed"] = tasks[taskName]["completed"];
                      });
                    });
                  },
                ),
                title: Text(taskName, style: TextStyle(
                  fontWeight: FontWeight.bold
                )),
                subtitle: due == null ? null : Text("Due: $due"),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  color: Colors.black,
                  onPressed: () {
                    setState(() {
                      tasks.remove(taskName);
                    });
                  },
                ),
                children: subtasks.isNotEmpty ?
                  subtasks.entries.map<Widget>((entry) {
                    String subtaskTitle = entry.key;
                    var subtaskData = entry.value;
                    int subtaskIndex = subtaskData["id"];
                    bool subtaskCompleted = subtaskData['completed'];
                    String? subtaskDue = subtaskData['due_date'];
            
                    return ListTile(
                      key: ValueKey("subtask-$subtaskIndex"),
                      tileColor: subtaskCompleted ? Colors.green[200] : Colors.transparent,
                      leading: Checkbox(
                        activeColor: Colors.black,
                        value: subtaskCompleted,
                        onChanged: (bool? value) {
                          setState(() {
                            subtasks[subtaskTitle]["completed"] = value!;
                            if (value == false) tasks[taskName]["completed"] = false;
                          });
                        },
                      ),
                      title: Text(subtaskTitle),
                      subtitle: subtaskDue == null ? null : Text('Due: $subtaskDue'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            subtasks.remove(subtaskTitle);
                          });
                        },
                      ),
                    );
                  }).toList()
                : [
                  ListTile(
                    title: Text("All subtasks completed!"),
                  )
                ]
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        shape: CircleBorder(),
        backgroundColor: Colors.white,
        child: Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}