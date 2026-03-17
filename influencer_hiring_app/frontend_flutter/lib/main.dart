import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/brand_dashboard_screen.dart';
import 'screens/influencer_main_screen.dart';
import 'screens/forgot_password_screen.dart'; // NEW

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Influencer Hiring App",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}

////////////////////////////////////////////////////////
/// LOGIN SCREEN
////////////////////////////////////////////////////////

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  final String baseUrl =
      "http://localhost:5000";

  Future<void> login() async {

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        SharedPreferences prefs =
            await SharedPreferences.getInstance();

        await prefs.setString("token", data["token"]);
        await prefs.setString("role", data["user"]["role"]);
        await prefs.setInt("userId", data["user"]["id"]);

        /// BRAND LOGIN
        if (data["user"]["role"] == "brand") {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BrandDashboardScreen(),
            ),
          );

        }

        /// INFLUENCER LOGIN
        else {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => InfluencerMainScreen(),
            ),
          );

        }

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["error"] ?? "Login Failed",
            ),
          ),
        );

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error. Check backend."),
        ),
      );

    }

    setState(() {
      isLoading = false;
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Login"),
      ),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            /// NEW FORGOT PASSWORD BUTTON
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                child: Text("Forgot Password?"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ForgotPasswordScreen(),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 15),

            isLoading
                ? CircularProgressIndicator()
                : Column(
                    children: [

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: login,
                          child: Text("Login"),
                        ),
                      ),

                      TextButton(
                        onPressed: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RegisterScreen(),
                            ),
                          );

                        },
                        child: Text("Create Account"),
                      ),

                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// REGISTER SCREEN
////////////////////////////////////////////////////////

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String role = "influencer";

  final String baseUrl =
      "http://localhost:5000";

  Future<void> register() async {

    final res = await http.post(
      Uri.parse("$baseUrl/api/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({

        "name": nameController.text,
        "email": emailController.text,
        "password": passwordController.text,
        "role": role

      }),
    );

    if (res.statusCode == 201) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account Created")),
      );

      Navigator.pop(context);

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Register"),
      ),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: Column(

          children: [

            TextField(
              controller: nameController,
              decoration:
                  InputDecoration(labelText: "Name"),
            ),

            TextField(
              controller: emailController,
              decoration:
                  InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration:
                  InputDecoration(labelText: "Password"),
            ),

            SizedBox(height: 15),

            DropdownButton<String>(
              value: role,
              items: [

                DropdownMenuItem(
                  value: "brand",
                  child: Text("Brand"),
                ),

                DropdownMenuItem(
                  value: "influencer",
                  child: Text("Influencer"),
                ),

              ],
              onChanged: (val) {
                setState(() {
                  role = val!;
                });
              },
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: register,
              child: Text("Register"),
            )

          ],
        ),
      ),
    );
  }
}