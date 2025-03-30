// lib/main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // API base URL - replace with your actual API URL when deployed
  final String apiUrl = "http://10.0.2.2:8000"; // For Android emulator pointing to localhost

  Future<void> _authenticateUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = isLogin ? '$apiUrl/login' : '$apiUrl/signup';
      
      Map<String, dynamic> body = {
        'email': _emailController.text,
        'password': _passwordController.text,
      };
      
      if (!isLogin) {
        body['name'] = _nameController.text;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Save the token for future requests
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['access_token']);
        await prefs.setString('user_id', responseData['user_id']);
        
        // Navigate to Home page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(
              token: responseData['access_token'],
              userId: responseData['user_id'],
            ),
          ),
        );
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          _errorMessage = responseData['detail'] ?? 'Authentication failed';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Network error: ${error.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isLogin)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!isLogin && (value == null || value.isEmpty)) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              if (!isLogin) const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (!isLogin && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _authenticateUser();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isLogin ? 'Login' : 'Sign Up'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    _errorMessage = null;
                  });
                },
                child: Text(
                  isLogin
                      ? 'Don\'t have an account? Sign Up'
                      : 'Already have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String token;
  final String userId;

  const HomePage({Key? key, required this.token, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear saved credentials
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              await prefs.remove('user_id');
              
              // Navigate back to login page
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Expense Tracker!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            const Text(
              'You are now logged in.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            const Text(
              'Coming soon:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('• Voice command expense tracking'),
            const Text('• Expense categorization'),
            const Text('• Transaction history'),
            const Text('• Visual reports and charts'),
          ],
        ),
      ),
    );
  }
}
