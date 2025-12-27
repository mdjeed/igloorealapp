import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:igloo/websocket.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igloo/loginpage.dart';

const Color bgColor = Color(0xFFF6F6F6);
const Color cardWhite = Colors.white;
const Color chartCard = Color(0xFFF4EEE8);
const Color greenCard = Color(0xFF9BC9C2);
const Color purpleCard = Color(0xFF8C78B8);
const Color brownCard = Color(0xFFC9A07A);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WebSocketService _webSocketService = WebSocketService();
  String username = '';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    loadUsername();
    checkLogin();

    _webSocketService.sendMessage({'action': 'check_update'});
    _webSocketService.stream.listen((message) {
      try {
        Map<String, dynamic> data;
        if (message is String) {
          data = jsonDecode(message);
        } else if (message is Map) {
          data = message as Map<String, dynamic>;
        } else {
          throw Exception('Unexpected message type');
        }

        print('Decoded data: $data');
        if (data['status'] == 'success') {
          setState(() {
            _isLoggedIn = true;
          });
          print('Login successful. Username: ${data['username']}');
        } else if (data['status'] == 'errorlog') {
          setState(() {
            _isLoggedIn = false;
          });
          Navigator.pushReplacementNamed(context, 'login');
        }
      } catch (e) {}
    });
  }

  Future<void> checkLogin() async {
    // جلب التوكن المحفوظ
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      // إرسال طلب للتحقق من حالة تسجيل الدخول
      _webSocketService.sendMessage({
        'action': 'check_login',
        'token': token,
      });
    } else {
      // إعادة توجيه المستخدم إلى صفحة تسجيل الدخول إذا لم يكن التوكن موجودًا
      Navigator.pushReplacementNamed(context, 'login');
    }
  }

  Future<void> loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String username = prefs.getString('username') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          elevation: null,
          centerTitle: false,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          title: Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 13),
            width: 35.0,
            height: 35.0,
            decoration: const BoxDecoration(
                color: Color(0xFFEBEBEB),
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: const Text(
              'M',
              style: TextStyle(fontSize: 20, color: Color(0xff656565)),
            ),
          ),
          actions: [
            Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.only(left: 13),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/images/humberg.svg',
                    width: 35.0,
                    height: 35.0,
                  ),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ),
          ],
        ),
        endDrawer: Drawer(
          backgroundColor: Colors.white,
          child: ListView(
            children: [
              Container(
                child: const Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      'برنامج ايقلو',
                      style: TextStyle(fontFamily: 'arabic', fontSize: 25),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'لوحة ادارة البرنامج',
                      style: TextStyle(fontFamily: 'arabic', fontSize: 25),
                    ),
                    SizedBox(
                      height: 30,
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 20),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: 1.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 206, 204, 204)
                          .withOpacity(0.5),
                      spreadRadius: 0,
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: MaterialButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'sel3aout');
                  },
                  child: const Text('سلع المسحوبة',
                      style: TextStyle(fontFamily: 'arabic', fontSize: 15)),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 20),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: 1.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 206, 204, 204)
                          .withOpacity(0.5),
                      spreadRadius: 0,
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: MaterialButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'addproduct');
                  },
                  child: const Text(
                    'اضافة السلع',
                    style: TextStyle(fontFamily: 'arabic', fontSize: 15),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 20),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: 1.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 206, 204, 204)
                          .withOpacity(0.5),
                      spreadRadius: 0,
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: MaterialButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'fingerpage');
                  },
                  child: const Text(
                    'تسجيل الخدامين',
                    style: TextStyle(fontFamily: 'arabic', fontSize: 15),
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
