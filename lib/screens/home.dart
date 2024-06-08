import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:todo/screens/add_task.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo/screens/description.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String uid = '';
  bool isSorted = false;
  late StreamSubscription subscription;
  bool isDeviceConnected = false;
  List<Map<String, dynamic>> localTasks = [];

  @override
  void initState() {
    getuid();
    getConnectivity();
    loadLocalTasks();
    super.initState();
  }

  getuid() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User user = auth.currentUser!;
    setState(() {
      uid = user.uid;
    });
  }

  getConnectivity() async {
    subscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) async {
        isDeviceConnected = await InternetConnectionChecker().hasConnection;
        if (isDeviceConnected) {
          syncLocalTasks();
        }
      },
    );
    isDeviceConnected = await InternetConnectionChecker().hasConnection; // Initial check
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  syncLocalTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> tasks = prefs.getStringList('localTasks') ?? [];

    if (tasks.isNotEmpty) {
      FirebaseAuth auth = FirebaseAuth.instance;
      User user = auth.currentUser!;
      String uid = user.uid;

      for (String taskString in tasks) {
        Map<String, dynamic> task = jsonDecode(taskString) as Map<String, dynamic>;
        var time = DateTime.parse(task['timestamp']);
        task['timestamp'] = Timestamp.fromDate(time);

        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(uid)
            .collection('mytasks')
            .doc(time.toString())
            .set(task);
      }

      await prefs.remove('localTasks');
      Fluttertoast.showToast(msg: 'Local Data Synced with Firebase');
      setState(() {
        localTasks = [];
      });
    }
  }

  loadLocalTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> tasks = prefs.getStringList('localTasks') ?? [];

    setState(() {
      localTasks = tasks.map((taskString) => jsonDecode(taskString) as Map<String, dynamic>).toList();
    });
  }

  onTaskAdded() {
    loadLocalTasks();
    setState(() {});
  }

  void sortTasks(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (isSorted) {
      docs.sort((a, b) => a['title'].compareTo(b['title']));
    }
  }

  void sortLocalTasks() {
    if (isSorted) {
      localTasks.sort((a, b) => a['title'].compareTo(b['title']));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ToDo"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              Fluttertoast.showToast(msg: 'To do list is filtered in alphabetic order');
              setState(() {
                isSorted = !isSorted;
                sortLocalTasks();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Text(
              'Firebase Stored Data',
              style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10,),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(uid)
                    .collection('mytasks')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    final docs = snapshot.data!.docs;

                    sortTasks(docs);

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var doc = docs[index];
                        var timestamp = doc['timestamp'];
                        DateTime time;
                        // Convert timestamp to DateTime
                        if (timestamp is Timestamp) {
                          time = timestamp.toDate();
                        } else if (timestamp is String) {
                          time = DateTime.parse(timestamp);
                        } else {
                          time = DateTime.now(); // Fallback in case of unexpected type
                        }

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Description(
                                  title: doc['title'],
                                  description: doc['description'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 90,
                            margin: EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.yellow[600],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(left: 20),
                                      child: Text(
                                        doc['title'],
                                        style: GoogleFonts.roboto(
                                          fontSize: 20,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(left: 20),
                                      child: Text(
                                        DateFormat.yMd().add_jm().format(time),
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  child: IconButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('tasks')
                                          .doc(uid)
                                          .collection('mytasks')
                                          .doc(doc['time'])
                                          .delete();
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Locally Stored Data',
              style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10,),
            Expanded(
              child: localTasks.isNotEmpty
                  ? ListView.builder(
                itemCount: localTasks.length,
                itemBuilder: (context, index) {
                  var task = localTasks[index];
                  var time = DateTime.parse(task['timestamp']);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Description(
                            title: task['title'],
                            description: task['description'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 90,
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.yellow[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(left: 20),
                                child: Text(
                                  task['title'],
                                  style: GoogleFonts.roboto(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 20),
                                child: Text(
                                  DateFormat.yMd().add_jm().format(time),
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            child: IconButton(
                              onPressed: () async {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                List<String> tasks = prefs.getStringList('localTasks') ?? [];
                                tasks.removeAt(index);
                                await prefs.setStringList('localTasks', tasks);
                                loadLocalTasks();
                              },
                              icon: Icon(
                                Icons.delete,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
                  : Center(
                child: Text(
                  'No data in local storage',
                  style: GoogleFonts.roboto(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTask(onTaskAdded: onTaskAdded),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
