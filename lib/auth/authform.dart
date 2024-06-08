import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AuthForm extends StatefulWidget {
  const AuthForm({Key? key}) : super(key: key);

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formkey = GlobalKey<FormState>();
  var _email = '';
  var _password = '';
  var _username = '';
  bool isLoginPage = false;
/////////////////////////
  startauthentication()async{
    final validity=_formkey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if(validity){
      _formkey.currentState!.save();
      submitform(_email,_password,_username);
    }
  }
  submitform(String emaill,String passwordd,String usernamee)async{
    final auth=FirebaseAuth.instance;
    UserCredential authResult;
    try{
      if(isLoginPage){
        authResult=await auth.signInWithEmailAndPassword(email: emaill, password: passwordd);
      }
      else{
        authResult=await auth.createUserWithEmailAndPassword(email: emaill, password: passwordd);
        String uid=authResult.user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'username':usernamee,
          'email':emaill,
        });
      }

    }
    catch(err){
    print(err);

    }
  }
  //////
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(children: [
        Container(
          padding: EdgeInsets.only(left: 10, right: 10, top: 10),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Form(
              key: _formkey,
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoginPage == false)
                    TextFormField(
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Incorrect username";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _username = value.toString();
                      },
                      keyboardType: TextInputType.emailAddress,
                      key: ValueKey('username'),
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: new BorderRadius.circular(8.0),
                            borderSide: new BorderSide(),
                          ),
                          labelText: "Enter username",
                          labelStyle: GoogleFonts.roboto()
                      ),
                    ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value!.isEmpty || value!.contains('@') == false) {
                        return "Incorrect email";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _email = value.toString();
                    },
                    keyboardType: TextInputType.emailAddress,
                    key: ValueKey('email'),
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(8.0),
                          borderSide: new BorderSide(),
                        ),
                        labelText: "Enter Email",
                        labelStyle: GoogleFonts.roboto()
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Incorrect password";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value.toString();
                    },
                    keyboardType: TextInputType.emailAddress,
                    key: ValueKey('password'),
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(8.0),
                          borderSide: new BorderSide(),
                        ),
                        labelText: "Enter Password",
                        labelStyle: GoogleFonts.roboto()
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Container(
                    width: double.infinity,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue,

                      // Replace this with the desired color
                    ),
                    child: TextButton(
                      onPressed: () {
                        startauthentication();
                      },
                      child: isLoginPage
                          ? Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.yellow,
                                // Replace this with the desired color
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              "Sign up",
                              style: TextStyle(
                                color: Colors.yellow,
                                // Replace this with the desired color
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    child: TextButton(
                      onPressed: (

                          ) {
                        setState(() {
                          isLoginPage=!isLoginPage;
                        });
                      },
                      child: isLoginPage
                          ? Text("Create New Account")
                          : Text("Already a member"),
                    ),
                  )

                ],
              )),
        ),
      ]),
    );
  }
}
