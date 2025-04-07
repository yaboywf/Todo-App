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

  Future<void> getTasks() async {
    String? token = await getToken();

    try {
      final response = await http.get(
        Uri.parse("http://192.168.0.189:3000/api/get_tasks"),
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

  void openTask(BuildContext context, String taskName, bool completed, {String? dueDate}) {
    showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(taskName),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Task: $taskName"),
              dueDate == null ? Container() : Text("Due: $dueDate"),
              Text("Completed: ${completed == true ? 'Yes' : 'No'}"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      }
    );
  }

  void createTask(Map<String, dynamic> parentTasks) {
    String? selectedTaskType;
    TextEditingController taskNameController = TextEditingController();
    TextEditingController dueDateController = TextEditingController();

    void sendCreateRequest(BuildContext context) async {
      String? token = await getToken();

      if (taskNameController.text.isEmpty) {
        if (!context.mounted) return;
        showAlertDialog(context, "Task name cannot be empty");
        return;
      }

      final response = await http.post(
        Uri.parse("http://192.168.0.189:3000/api/tasks/create"),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "task_name": taskNameController.text,
          "due_date": dueDateController.text,
          "parent_task": selectedTaskType == null ? null : parentTasks[selectedTaskType]["id"]
        })
      );

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        showAlertDialog(context, "Task created successfully", afterwards: () => Navigator.pushReplacementNamed(context, "/tasks"));
      } else {
        print("Error: ${json.decode(response.body)}");
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: Text("Create Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextField(
                controller: taskNameController,
                decoration: textDecor("Task Name"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: dueDateController,
                decoration: textDecor("Due Date (OPTIONAL)"),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: selectedTaskType,
                  underline: Container(),
                  hint: Text("Child Task of (OPTIONAL)", style: TextStyle(fontSize: 14),),
                  items: parentTasks.keys.toList().map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedTaskType = value;
                    });
                  }
                ),
              )
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Create"),
              onPressed: () {
                sendCreateRequest(context);
              }
            )
          ],
        ));
      }
    );
  }

  void sendDeleteRequest(BuildContext context, int taskId, String taskType) async {
    String? token = await getToken();

    final response = await http.delete(
      Uri.parse("http://192.168.0.189:3000/api/tasks/delete"),
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "id": taskId,
        "task_type": taskType
      })
    );

    if (response.statusCode == 200) {
      if (!context.mounted) return;
      showAlertDialog(context, "Task deleted successfully", afterwards: () => Navigator.pushReplacementNamed(context, "/tasks"));
    } else {
      if (!context.mounted) return;
      print("Error: ${json.decode(response.body)}");
    }
  }

  @override
  void initState() {
    super.initState();
    validateSession(context);
    getTasks();
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
      body: tasks.isEmpty ? Center(child: CircularProgressIndicator(color: Colors.black,)) : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          String taskName = tasks.keys.toList()[index];
          bool completed = tasks.values.toList()[index]["completed"];
          String? due = tasks.values.toList()[index]["due_date"];
          int parentIndex = tasks.values.toList()[index]["id"];
          Map<dynamic, dynamic> subtasks = tasks.values.toList()[index]["subtasks"];

          return GestureDetector(
            onLongPress: () {
              print("long press: $parentIndex");
              openTask(context, taskName, completed, dueDate: due);
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
                    sendDeleteRequest(context, parentIndex, "parent");
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
                    ValueKey key = ValueKey("subtask-$subtaskIndex");
            
                    return GestureDetector(
                      onLongPress: () {
                        print("Long press on subtask: $subtaskIndex");
                      },
                      child: ListTile(
                        key: key,
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
                            sendDeleteRequest(context, subtaskIndex, "sub");
                            setState(() {
                              subtasks.remove(subtaskTitle);
                            });
                          },
                        ),
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
        onPressed: () {
          createTask(tasks);
        },
        shape: CircleBorder(),
        backgroundColor: Colors.white,
        child: Icon(
          Icons.add,
          color: Colors.black,
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