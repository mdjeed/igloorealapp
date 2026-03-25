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
    fetchsla7ia() ;
     

pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {

  _webSocketService.sendMessage({
    "action": "ping"
  });

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
        } 
        else if (data["action"] == "pong") {

            pongTimeout?.cancel();

            if (!serverAlive) {

              setState(() {
                serverAlive = true;
              });

            }

          }
        
        else if (data['status'] == 'addbranchsuccess') {
          fetchBranches();

        }

        else if (data['status'] == 'branch_list') {

                  setState(() {

                      branches = message['branches'];
                       loading = false;

                    });


          

        }



                else if (data['status'] == 'errorlog') {
          setState(() {
            _isLoggedIn = false;
          });
          Navigator.pushReplacementNamed(context, 'login');
        }


      } catch (e) {}
    });
    
  }

  void fetchBranches() {
    setState(() {
    });
    _webSocketService.sendMessage({
      'action': 'get_branch',
    });
  }


  void addBranch(String Branchname)
  {
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

void showaddbranch ()
    {

      showDialog(context: context,
       builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
           title: Container(
            alignment: Alignment.center,
             child: const Text(
              'اضافة فرع ',
              style: TextStyle(fontFamily: 'arabic',fontSize: 18,color: Color.fromARGB(255, 66, 66, 66)),
                       ),
           ),

           content: Container(
            height: 100,
             child: Column(
              
              children: [
             
                Container(
                  child:TextField(
                    controller: myController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "اسم الفرع ",
                        hintTextDirection: TextDirection.rtl,
                        hintStyle:
                            TextStyle(fontFamily: 'arabic', color: Colors.grey)),
                  ),
                ),
                            TextButton(
                              
              onPressed: () {
                final branchname = myController.text;

                addBranch(branchname);
                Navigator.of(context).pop();
              },
              child: const Text(
                'اضافة',
                style: TextStyle(fontFamily: 'arabic', color: Colors.blue),
              ),
            ),

             
              ],
             ),
           ),

        );

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
        body: Container(
            child: Stack(
          children: [
            Container(
           
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
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                        margin: EdgeInsets.only(
                                          top: 20,
                                        ),
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
                                      margin: EdgeInsets.only(top: 5, right: 8),
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
                              Container(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(right: 20),
                                width: 160,
                                height: 130,
                                decoration: BoxDecoration(
                                    color: Color(0xFFece9f2),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                        margin: EdgeInsets.only(
                                          top: 20,
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/images/store.svg',
                                          width: 20,
                                          height: 25,
                                          colorFilter: ColorFilter.mode(
                                            Color.fromARGB(255, 122, 70, 143),
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
                                      margin: EdgeInsets.only(top: 5, right: 8),
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
                                    margin: EdgeInsets.only(
                                      top: 40,
                                    ),
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
                              ]),
                        ),
                      ],
                    ),
                  ),

                Container(
                alignment: Alignment.centerRight, 
                padding: EdgeInsets.only(right: 20,top: 30),
                
                      child:
                      Column(children: [
                        Row(

                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                                                    Text(
                        " جميع الافرع",
                        
                          textAlign: TextAlign.right,
                          
                          style: TextStyle(
                            color: const Color.fromARGB(255, 70, 67, 67),
                            fontFamily: 'arabic',
                            fontSize: 23
                          ),

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
                              color:Color(0xff656565),
                              onPressed: showaddbranch,
                            ),
                          )                
                                    ],
                        ),

                            Container(
                              margin: EdgeInsets.only(top: 30,left: 20,right: 10),
                              height: 300,
                              width: size.width,
                              child:
                              loading
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                radius: 15,
                              ),
                            )
                            : ListView.builder(
                                                      itemCount: branches.length,
                                                      itemBuilder: (context, index) {
                                                        final branchesname = branches[index]['branchname'];
                                                        final branchid= branches[index]['id'];
                                                        
                                  return InkWell(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                          onTap: () async {
                                            String page;
                                            print(branchid);
                                             final prefs = await SharedPreferences.getInstance();
                                              await prefs.setInt('branch_id', branchid); 

                                         

                                            if (sla7ia == 'admin') {
                                              page = 'admin';
                                            } else if (sla7ia == 'coadmin') {
                                              page = 'coadmin';
                                            } else if (sla7ia == 'superadmin') {
                                              page = 'superadmin';
                                            } else {
                                              page = 'nonadmin';
                                            }

                                            Navigator.pushReplacementNamed(context, page);
                                          },                                          
                                                          
                                      
    


  child: Container(
    alignment: Alignment.center,
    height: 70,
    margin: const EdgeInsets.all(9),
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
                                },
                              ),
                            )                 
                      ],)
                    )

 
                ],
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
        )),
      ),
    );
  }
    @override
  void dispose() {
    pingTimer?.cancel();
    super.dispose();
  }
}
