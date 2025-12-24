import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InterViewPage extends StatefulWidget {
  const InterViewPage({super.key});

  @override
  State<StatefulWidget> createState() => _InterViewPage();
}

class _InterViewPage extends State<InterViewPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              child: const Column(
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  Text(
                    "منصة ايقلو",
                    style: TextStyle(
                        fontFamily: 'varsi',
                        fontSize: 35,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 65, 64, 63)),
                  ),
                  Text(
                    "تنظيم وإدارة",
                    style: TextStyle(
                        fontFamily: 'varsi',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 99, 97, 96)),
                  ),
                ],
              ),
            ),
            Container(
              height: 230,
              child: Image.asset("assets/images/logo.png"),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              child: const Column(
                children: [
                  Text(
                    "منصة ايقلو",
                    style: TextStyle(
                        fontSize: 26,
                        fontFamily: 'arabic',
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    " برنامج ايقلو خاص بادارة سلسة ايقلو بجميع افرعها بكل سهولة و سلاسة ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'arabic',
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 99, 97, 96)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 80),
              child: MaterialButton(
                minWidth: double.infinity,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                height: 70,
                elevation: 0,
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_seen', true);
                  Navigator.pushReplacementNamed(context, 'login');
                },
                color: Color(0xFF242732),
                textColor: Colors.white,
                child: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 60,
                        height: 45,
                        decoration: const BoxDecoration(
                          color: Colors.white, // لون الدائرة
                          shape: BoxShape.circle,
                          // شكل الدائرة
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                      const Text(
                        "تسجيل دخول ",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'arabic',
                        ),
                      ),
                      SizedBox(
                        width: 0,
                        height: 0,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



/** 



import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:igloo/websocket.dart';

class Mainscreen extends StatefulWidget {
  const Mainscreen({super.key});

  @override
  State<StatefulWidget> createState() => _Mainscreen();
}

class _Mainscreen extends State<Mainscreen> {
  final WebSocketService _webSocketService = WebSocketService();
  final List<Map<String, dynamic>> categories = [
    {'id': 1, 'name': 'Mec3'},
    {'id': 2, 'name': 'Pregel'},

    // أضف تصنيفاتك هنا
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 30),
          width: 40.0,
          height: 40.0,
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
                    padding: const EdgeInsets.only(left: 20),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'assets/images/humberg.svg',
                        width: 40.0,
                        height: 40.0,
                      ),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  )),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [Text("hello")],
        ),
      ),
      body: Container(
        width: size.width,
        height: size.height,
        child: Column(
          children: [
            Container(
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 20, top: 20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'برنامج ايقلو',
                    style: TextStyle(fontFamily: 'arabic', fontSize: 25),
                  ),
                  Text(
                    'ادارة سلعة المستودع',
                    style: TextStyle(fontFamily: 'arabic', fontSize: 25),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 23,
            ),
            Container(
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(left: 60, right: 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن السلعة',
                  suffixIcon: const Icon(Icons.search),
                  hintStyle: const TextStyle(
                      fontFamily: 'arabic',
                      color: Color.fromARGB(255, 167, 165, 165)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                          width: 2.2,
                          color: Color.fromARGB(255, 190, 190, 190))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 190, 190, 190),
                          width: 2.2)),
                  fillColor: const Color(0xff656565),
                  filled: false,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final categoryName = categories[index]['name'];
                    return Container(
                      alignment: Alignment.center,
                      width: 100,
                      height: 40,
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xFF26292E),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                    );
                  }),
            ),
            const SizedBox(
              height: 30,
            ),
            Container(
                width: size.width,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
                  'سلعة',
                  style: TextStyle(fontFamily: 'arabic', fontSize: 25),
                )),
          ],
        ),
      ),
    );
  }
}
*/