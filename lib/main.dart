import 'package:flutter/material.dart';
import 'package:igloo/loginpage.dart';
import 'package:igloo/interview.dart';
import 'package:igloo/admin.dart';
import 'package:igloo/selectedproduct.dart';
import 'package:igloo/addproductpage.dart';
import 'package:igloo/websocket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:igloo/finger.dart';
import 'package:igloo/nonadminmainscreen.dart';
import 'package:igloo/co_admin.dart';
import 'package:igloo/superadmin.dart';
import 'package:igloo/homepage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final WebSocketService _webSocketService = WebSocketService();

  runApp(const MyApp());
}
//hiiiiiiiiiiii
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<String> _initialRoute;

  @override
  void initState() {
    super.initState();
    _initialRoute =
        _checkInitialState(); // تحقق من حالة الجلسة وحالة Onboarding
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'igloo',
      routes: {
        'homepage': (context) => HomePage(),
        'fingerpage': (context) => AttendancePage(),
        'login': (context) => const LoginPage(),
        'sel3aout': (context) => const SelectedProduct(),
        'addproduct': (context) => const Addproductpage(),
        'admin': (context) => const Admin(),
        'onboarding': (context) => const InterViewPage(), // صفحة Onboarding
        'nonadmin': (context) => const NonAdmin(),
        'coadmin': (context) => const CoAdmin(),
        'superadmin': (context) => const SuperAdmin(),
      },
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: FutureBuilder<String>(
        future: _initialRoute,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            // توجيه المستخدم بناءً على الحالة
            if (snapshot.data == 'onboarding') {
              return const InterViewPage(); // عرض صفحة Onboarding
            } else if (snapshot.data == 'admin') {
              return const Admin(); // الصفحة الرئيسية لـ admin
            } else if (snapshot.data == 'superadmin') {
              return const HomePage();
            } else if (snapshot.data == 'coadmin') {
              return const CoAdmin(); // الصفحة الرئيسية لـ coadmin
            } else if (snapshot.data == 'nonadmin') {
              return const NonAdmin(); // الصفحة الرئيسية لـ nonadmin
            } else {
              return const LoginPage(); // صفحة تسجيل الدخول
            }
          }
        },
      ),
    );
  }

  // دالة للتحقق من حالة الجلسة وحالة Onboarding
  Future<String> _checkInitialState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

    if (!onboardingSeen) {
      // إذا لم تتم مشاهدة Onboarding، احفظ الحالة
      prefs.setBool('onboarding_seen', true);
      return 'onboarding'; // ارجع قيمة تدل على عرض Onboarding
    }

    // التحقق من الجلسة (التوكن)
    String? token = prefs.getString('token');
    String? sla7ia = prefs.getString('sla7ia'); // الحصول على نوع المستخدم

    if (token != null) {
      // تحديد الصفحة المناسبة بناءً على نوع المستخدم
      if (sla7ia == 'admin') {
        return 'admin';
      } else if (sla7ia == 'coadmin') {
        return 'coadmin';
      } else if (sla7ia == 'superadmin') {
        return 'superadmin';
      } else {
        return 'nonadmin';
      }
    }
    return 'login'; // إذا لم يكن التوكن موجودًا
  }
}
