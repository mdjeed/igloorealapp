import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:igloo/websocket.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final WebSocketService _webSocketService = WebSocketService();

  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // ignore: unused_field
  String _loginStatus = '';

  void _login() {
    final username = _loginController.text;
    final password = _passwordController.text;
    _webSocketService.sendMessage({
      'action': 'login',
      'username': username,
      'password': password, 
    });
  }

  @override
  void initState() {
    super.initState();
    _webSocketService.stream.listen((data) async {
      print('Received data: $data'); // تأكد من تلقي البيانات بشكل صحيح
      if (data['status'] == 'success') {
        final username = _loginController.text;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('token', data['token']);
        await prefs.setString('company', data['name']);

        if(data['name']=='admin')
        {
        setState(() {
          Navigator.pushReplacementNamed(context, 'admin');
        });
        }
        else if(data['name']=='coadmin')
        { 
          setState(() {
          Navigator.pushReplacementNamed(context, 'coadmin');
        });
        }
        else if(data['name']=='superadmin')
        { 
          setState(() {
          Navigator.pushReplacementNamed(context, 'superadmin');
        });
        }
        else
        {
        setState(() {
          Navigator.pushReplacementNamed(context, 'nonadmin');
        });

        }

    



       
      

      } else if (data['status'] == 'error') {
        setState(() {
          _loginStatus = 'Invalid credentials';
        });
      }
    }, onError: (error) {
      print('Error: $error'); // طباعة أي خطأ يحدث
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              Container(
                height: 250,
                child: Image.asset("assets/images/imgloginhome.png"),
              ),
              const SizedBox(
                height: 50,
              ),
              Container(
                alignment: Alignment.center,
                width: size.width,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFF7F7F7)),
                child: TextField(
                  controller: _loginController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "اسم المستخدم",
                      hintTextDirection: TextDirection.rtl,
                      hintStyle:
                          TextStyle(fontFamily: 'arabic', color: Colors.grey)),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                alignment: Alignment.center,
                width: size.width,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFF7F7F7)),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "كلمة السر",
                      hintTextDirection: TextDirection.rtl,
                      hintStyle:
                          TextStyle(fontFamily: 'arabic', color: Colors.grey)),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                margin: const EdgeInsets.only(bottom: 80),
                child: MaterialButton(
                  minWidth: double.infinity,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  height: 60,
                  elevation: 0,
                  onPressed: _login,
                  color: const Color(0xFF242732),
                  textColor: Colors.white,
                  child: const Text(
                    "تسجيل دخول ",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'arabic',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
