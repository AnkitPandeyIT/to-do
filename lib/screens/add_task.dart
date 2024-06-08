import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AddTask extends StatefulWidget {
  final Function onTaskAdded; // Callback function to notify home screen

  const AddTask({Key? key, required this.onTaskAdded}) : super(key: key);

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool isDeviceConnected = false;
  late StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    getConnectivity();
  }

  getConnectivity() async {
    subscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) async {
        isDeviceConnected = await InternetConnectionChecker().hasConnection;
      },
    );
    isDeviceConnected = await InternetConnectionChecker().hasConnection; // Initial check
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  addTaskToFirebase() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User user = auth.currentUser!;
    String uid = user.uid;
    var time = DateTime.now();
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(uid)
        .collection('mytasks')
        .doc(time.toString())
        .set({
      'title': titleController.text,
      'description': descriptionController.text,
      'time': time.toString(),
      'timestamp': Timestamp.fromDate(time),
    });
    Fluttertoast.showToast(msg: 'Data Added to Firebase');
    widget.onTaskAdded(); // Notify home screen
  }

  saveTaskLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var time = DateTime.now();
    Map<String, dynamic> task = {
      'title': titleController.text,
      'description': descriptionController.text,
      'time': time.toString(),
      'timestamp': time.toString(),
    };

    List<String> tasks = prefs.getStringList('localTasks') ?? [];
    tasks.add(jsonEncode(task));
    await prefs.setStringList('localTasks', tasks);

    Fluttertoast.showToast(msg: 'Data Saved Locally');
    widget.onTaskAdded(); // Notify home screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Task'),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              child: TextField(
                controller: titleController,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                    labelText: 'Enter title', border: OutlineInputBorder()),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              height: MediaQuery.of(context).size.height / 4,
              child: TextField(
                controller: descriptionController,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                    labelText: 'Enter description',
                    border: OutlineInputBorder()),
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  if (isDeviceConnected) {
                    addTaskToFirebase();
                  } else {
                    saveTaskLocally();
                  }
                  Navigator.pop(context);
                },
                child: Text('Add Task'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
