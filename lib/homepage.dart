import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:igloo/websocket.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igloo/loginpage.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';

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
  final String currentVersion = '1.0.2';
  String username = '';
  bool _isLoggedIn = false;
  String connectionState = "connected";
  Timer? pingTimer;
  Timer? pongTimeout;
  bool reconnecting = false;
  TextEditingController myController = TextEditingController();
  List branches = [];
  String sla7ia = '';
  bool loading = true;
  bool serverAlive = true;

  @override
  void initState() {
    super.initState();
    loadUsername();
    checkLogin();
    fetchBranches();
    fetchsla7ia();

    pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _webSocketService.sendMessage({"action": "ping"});

      pongTimeout?.cancel();

      pongTimeout = Timer(const Duration(seconds: 2), () {
        setState(() {
          serverAlive = false;
        });

        reconnect();
      });
    });
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
        } else if (data['action'] == 'app_update') {
          final String latestVersion = data['version'];
          final String urlupdate = data['urlupdate'];
          compareVersions(currentVersion, latestVersion, urlupdate);
        } else if (data["action"] == "pong") {
          pongTimeout?.cancel();

          if (!serverAlive) {
            setState(() {
              serverAlive = true;
            });
          }
        } else if (data['status'] == 'addbranchsuccess') {
          fetchBranches();
        } else if (data['status'] == 'branch_list') {
          setState(() {
            branches = message['branches'];
            loading = false;
          });
        } else if (data['status'] == 'errorlog') {
          setState(() {
            _isLoggedIn = false;
          });
          Navigator.pushReplacementNamed(context, 'login');
        }
      } catch (e) {}
    });
  }

  void showUpdateDialog(String latestVersion, String urlupdate) {
    final String updateUrl = urlupdate;

    showDialog(
      context: context,
      barrierDismissible: false, // منع الإغلاق عند النقر خارج الحوار
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            // إرجاع false لمنع الإغلاق عند الضغط على زر الرجوع
            return false;
          },
          child: AlertDialog(
            title: const Text(
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'arabic'),
                'تحديث متاح'),
            content: Text(
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'arabic'),
                'يوجد إصدار جديد ($latestVersion) متاح. هل ترغب في التحديث الآن؟'),
            actions: [
              TextButton(
                child:
                    const Text(style: TextStyle(fontFamily: 'arabic'), 'تحديث'),
                onPressed: () async {
                  final Uri uri = Uri.parse(updateUrl);
                  print(uri);

                  try {
                    await launchUrl(uri);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          style: TextStyle(fontFamily: 'arabic'),
                          'تعذر فتح الرابط',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void compareVersions(
      String currentVersion, String latestVersion, String urlupdate) {
    if (currentVersion != latestVersion) {
      showUpdateDialog(latestVersion, urlupdate); // عرض نافذة لتحديث التطبيق
    } else {
      print("التطبيق محدث إلى أحدث إصدار.");
    }
  }

  void fetchBranches() {
    setState(() {});
    _webSocketService.sendMessage({
      'action': 'get_branch',
    });
  }

  void addBranch(String Branchname) {
    _webSocketService.sendMessage({
      'action': 'add_branch',
      'branch_name': Branchname,
    });
  }

  void reconnect() {
    if (reconnecting) return;

    reconnecting = true;

    print("Trying to reconnect...");

    Future.delayed(const Duration(seconds: 5), () {
      try {
        _webSocketService.connect();

        reconnecting = false;
      } catch (e) {
        reconnecting = false;

        reconnect(); // يحاول مرة أخرى
      }
    });
  }

  void showaddbranch() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔷 العنوان
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.store, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      'إضافة فرع',
                      style: TextStyle(
                        fontFamily: 'arabic',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔹 حقل الإدخال
                TextField(
                  controller: myController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'arabic'),
                  decoration: InputDecoration(
                    hintText: 'اسم الفرع',
                    hintTextDirection: TextDirection.rtl,
                    filled: true,
                    fillColor: const Color(0xffF5F5F5),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔻 الأزرار
                Row(
                  children: [
                    // ❌ إلغاء
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: 'arabic',
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ✅ إضافة
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final branchname = myController.text.trim();

                          if (branchname.isNotEmpty) {
                            addBranch(branchname);
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text(
                          'إضافة',
                          style: TextStyle(
                            fontFamily: 'arabic',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
      username = prefs.getString('username') ?? '';
    });
  }

  Future<void> fetchsla7ia() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      sla7ia = prefs.getString('sla7ia') ?? '';

      print(sla7ia);
    });
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFF5F5F5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xffF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.black87,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontFamily: 'arabic',
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
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
                      width: 37.0,
                      height: 37.0,
                    ),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ),
            ],
          ),
          endDrawer: Drawer(
            backgroundColor: Colors.white,
            elevation: 0,
            child: Column(
              children: [
                // 🔷 HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50, bottom: 25),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.store, size: 40, color: Colors.blue),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'برنامج ايقلو',
                        style: TextStyle(
                          fontFamily: 'arabic',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'لوحة الإدارة',
                        style: TextStyle(
                          fontFamily: 'arabic',
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // 🔹 الأزرار
                Expanded(
                  child: ListView(
                    children: [
                      _drawerItem(
                        icon: Icons.inventory,
                        title: 'سلع المسحوبة',
                        onTap: () {
                          Navigator.pushNamed(context, 'sel3aout');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.add_box,
                        title: 'اضافة السلع',
                        onTap: () {
                          Navigator.pushNamed(context, 'addproduct');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.fingerprint,
                        title: 'تسجيل الخدامين',
                        onTap: () {
                          Navigator.pushNamed(context, 'fingerpage');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 15, top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "  مرحبا بك ,$username",
                                style: TextStyle(
                                    fontFamily: 'arabic',
                                    fontSize: 20,
                                    color: Color(0xff2e2e2e)),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 5, right: 15),
                                child: Text(
                                  " لوحة التحكم",
                                  style: TextStyle(
                                      fontFamily: 'arabic',
                                      fontSize: 15,
                                      color: Color(0xff696868)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 290,
                          margin: EdgeInsets.only(top: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.only(right: 20),
                                      width: 160,
                                      height: 130,
                                      decoration: BoxDecoration(
                                          color: Color(0xFFF7EFE7),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20))),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                              margin: EdgeInsets.only(top: 20),
                                              child: SvgPicture.asset(
                                                'assets/images/empo.svg',
                                                width: 20,
                                                height: 25,
                                                colorFilter: ColorFilter.mode(
                                                  Color(0xffedbd8d),
                                                  BlendMode.srcIn,
                                                ),
                                              )),
                                          Container(
                                            margin: EdgeInsets.only(top: 20),
                                            child: Text(
                                              " اجمالي الموظفين",
                                              style: TextStyle(
                                                  fontFamily: 'arabic',
                                                  fontSize: 13,
                                                  color: Color(0xff696868),
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                                top: 5, right: 8),
                                            child: Text(
                                              "10 ",
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontFamily: 'arabic',
                                                  color: Color(0xff2e2e2e),
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(height: 15),
                                    Container(
                                      padding: EdgeInsets.only(right: 20),
                                      width: 160,
                                      height: 130,
                                      decoration: BoxDecoration(
                                          color: Color(0xFFece9f2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20))),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                              margin: EdgeInsets.only(top: 20),
                                              child: SvgPicture.asset(
                                                'assets/images/store.svg',
                                                width: 20,
                                                height: 25,
                                                colorFilter: ColorFilter.mode(
                                                  Color.fromARGB(
                                                      255, 122, 70, 143),
                                                  BlendMode.srcIn,
                                                ),
                                              )),
                                          Container(
                                            margin: EdgeInsets.only(top: 20),
                                            child: Text(
                                              " عدد الافرع",
                                              style: TextStyle(
                                                  fontFamily: 'arabic',
                                                  fontSize: 15,
                                                  color: Color(0xff696868),
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                                top: 5, right: 8),
                                            child: Text(
                                              "10 ",
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontFamily: 'arabic',
                                                  color: Color(0xff2e2e2e),
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                    color: Color(0xffafffbe).withOpacity(0.26),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20))),
                                width: 150,
                                height: 280,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                        alignment: Alignment.center,
                                        margin: EdgeInsets.only(top: 40),
                                        child: SvgPicture.asset(
                                          'assets/images/activitay.svg',
                                          width: 50.0,
                                          height: 90.0,
                                          colorFilter: ColorFilter.mode(
                                            Color(0xFF5F8F86).withOpacity(0.6),
                                            BlendMode.srcIn,
                                          ),
                                        )),
                                    Container(
                                      child: Column(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(top: 10),
                                            child: Text(
                                              "متابعة المخزون",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'arabic',
                                                  color: Color(0xff2e2e2e),
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(top: 4),
                                            child: Text(
                                              "في وقت متزامن ",
                                              style: TextStyle(
                                                  fontFamily: 'arabic',
                                                  fontSize: 12,
                                                  color: Color(0xff696868),
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20, top: 30),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      " جميع الافرع",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 70, 67, 67),
                                          fontFamily: 'arabic',
                                          fontSize: 23),
                                    ),
                                    Container(
                                      alignment: Alignment.center,
                                      margin: EdgeInsets.only(left: 35),
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFEBEBEB),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        iconSize: 20,
                                        icon: Icon(Icons.add),
                                        color: Color(0xff656565),
                                        onPressed: showaddbranch,
                                      ),
                                    )
                                  ],
                                ),
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        top: 30, left: 20, right: 10),
                                    width: size.width,
                                    child: loading
                                        ? const Center(
                                            child: CupertinoActivityIndicator(
                                              radius: 15,
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: branches.length + 1,
                                            itemBuilder: (context, index) {
                                              if (index == 0) {
                                                return InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  onTap: () async {
                                                    final branchid = 0;
                                                    String page;
                                                    final prefs =
                                                        await SharedPreferences
                                                            .getInstance();
                                                    await prefs.setInt(
                                                        'branch_id', branchid);

                                                    if (sla7ia == 'admin') {
                                                      page = 'admin';
                                                    } else if (sla7ia ==
                                                        'coadmin') {
                                                      page = 'coadmin';
                                                    } else if (sla7ia ==
                                                        'superadmin') {
                                                      page = 'superadmin';
                                                    } else {
                                                      page = 'nonadmin';
                                                    }

                                                    Navigator
                                                        .pushReplacementNamed(
                                                            context, page);
                                                  },
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    height: 70,
                                                    margin:
                                                        const EdgeInsets.all(9),
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 15),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      color: const Color(
                                                          0xFFF5F5F5),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xffF3F4F6),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: const Icon(
                                                            Icons.store,
                                                            color:
                                                                Colors.black87,
                                                            size: 22,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 15),
                                                        Expanded(
                                                          child: Text(
                                                            'جميع الفروع',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 17,
                                                              fontFamily:
                                                                  'arabic',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons
                                                              .arrow_forward_ios,
                                                          size: 16,
                                                          color: Colors.grey,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }

                                              final branchesname =
                                                  branches[index - 1]
                                                      ['branchname'];
                                              final branchid =
                                                  branches[index - 1]['id'];

                                              return InkWell(
                                                splashColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                onTap: () async {
                                                  String page;
                                                  final prefs =
                                                      await SharedPreferences
                                                          .getInstance();
                                                  await prefs.setInt(
                                                      'branch_id', branchid);

                                                  if (sla7ia == 'admin') {
                                                    page = 'admin';
                                                  } else if (sla7ia ==
                                                      'coadmin') {
                                                    page = 'coadmin';
                                                  } else if (sla7ia ==
                                                      'superadmin') {
                                                    page = 'superadmin';
                                                  } else {
                                                    page = 'nonadmin';
                                                  }

                                                  Navigator
                                                      .pushReplacementNamed(
                                                          context, page);
                                                },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  height: 70,
                                                  margin:
                                                      const EdgeInsets.all(9),
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 15),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    color:
                                                        const Color(0xFFF5F5F5),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xffF3F4F6),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: const Icon(
                                                          Icons.store,
                                                          color: Colors.black87,
                                                          size: 22,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 15),
                                                      Expanded(
                                                        child: Text(
                                                          branchesname,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 17,
                                                            fontFamily:
                                                                'arabic',
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons.arrow_forward_ios,
                                                        size: 16,
                                                        color: Colors.grey,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSlide(
                  offset: serverAlive ? const Offset(0, 2) : const Offset(0, 0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "  خطا بالشبكة..جاري اعادة الاتصال",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'arabic',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  @override
  void dispose() {
    pingTimer?.cancel();
    super.dispose();
  }
}
