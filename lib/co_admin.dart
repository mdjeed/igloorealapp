import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:igloo/websocket.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CoAdmin extends StatefulWidget {
  const CoAdmin({super.key});

  @override
  State<StatefulWidget> createState() => _CoAdmin();
}

class _CoAdmin extends State<CoAdmin> {
  final WebSocketService _webSocketService = WebSocketService();

  final List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> selectedItems = [];

  List<Map<String, dynamic>> items = [];

  final Map<int, int> _counters = {};
  final String currentVersion = '1.0.2'; // الإصدار الحالي للتطبيق
  bool _isLoading = false; // متغير حالة لتتبع حالة التحميل
  bool _isitemloading = false;
  bool _isLoggedIn = false;
  // حالة تسجيل الدخول

  void fetchCategories() {
    setState(() {
      _isLoading = true; // تعيين حالة التحميل إلى true
    });
    _webSocketService.sendMessage({
      'action': 'get_catego',
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
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
        if (data['status'] == 'product list') {
          setState(() {
            items = List<Map<String, dynamic>>.from(data['items']);
            _isLoading = false;
            _isitemloading =
                false; // تعيين حالة التحميل إلى false بعد تحميل العناصر
            print('Updated items: $items');
          });
        } else if (data['status'] == 'success') {
          setState(() {
            _isLoggedIn = true;
          });
          print('Login successful. Username: ${data['username']}');
        } else if (data['status'] == 'errorlog') {
          setState(() {
            _isLoggedIn = false;
          });
          Navigator.pushReplacementNamed(context, 'login');
        } else if (data['status'] == 'catego list') {
          setState(() {
            categories.clear();
            categories
                .addAll(List<Map<String, dynamic>>.from(data['categories']));

            // جلب العناصر للتصنيف الأول بعد تحديث التصنيفات
            if (categories.isNotEmpty) {
              fetchItems(categories[0]['id']);
            }
          });
        } else if (data['action'] == 'app_update') {
          final String latestVersion = data['version'];
          final String urlupdate = data['urlupdate'];
          compareVersions(currentVersion, latestVersion, urlupdate);
        } else if (data['status'] == 'error') {
          setState(() {
            _isLoading = false;
            _isitemloading = false; // تعيين حالة التحميل إلى false عند حدوث خطأ
          });
          print('Error status received');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isitemloading =
              false; // تعيين حالة التحميل إلى false عند حدوث خطأ في التحليل
        });
        print('Error parsing JSON: $e');
      }
    }, onError: (error) {
      setState(() {
        _isLoading = false;
        _isitemloading = false; // تعيين حالة التحميل إلى false عند حدوث خطأ
      });
      print('Error: $error');
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

  Future<void> _refreshData() async {
    fetchCategories(); // تحديث البيانات عند السحب لأسفل
  }

  void fetchItems(int categoryId) {
    setState(() {
      _isitemloading = true; // تعيين حالة التحميل إلى true عند بدء الجلب
    });
    _webSocketService.sendMessage({
      'action': 'get_items_by_category',
      'category_id': categoryId,
    });
  }

  void saveSelectedItems() async {
    final now = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> itemsToSend = selectedItems.map((item) {
      final itemId = item['id'];
      final itemName = item['name'];
      final itemCounter = _counters[itemId] ?? 0;

      return {
        'name': itemName,
        'counter': itemCounter,
      };
    }).toList();
    String? username = await getUsername();
    String? companyname = await getcompanyname();
    _webSocketService.sendMessage({
      'action': 'selcteditem',
      'itemsSelected': itemsToSend,
      'category_id': categories[0]['id'],
      'date': now,
      'added_by': username,
      'company': companyname,
    });
    setState(() {
      // إعادة تعيين العدادات إلى 0
      for (var itemId in _counters.keys) {
        _counters[itemId] = 0;
      }

      // إفراغ قائمة العناصر المحددة لإخفاء لون الحواف
      selectedItems.clear();
    });
    fetchItems(categories[0]['id']);
    _webSocketService.sendMessage({
      'action': 'getselecteditem',
    });
  }

  Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<String?> getcompanyname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('company');
  }

  void toggleSelection(Map<String, dynamic> item) {
    setState(() {
      final itemId = item['id'];
      final counterValue = _counters[itemId] ?? 0;
      final selectedItem = {
        'id': itemId,
        'name': item['name'],
        'counter': counterValue,
      };

      if (selectedItems.any((element) => element['id'] == itemId)) {
        selectedItems.removeWhere((element) => element['id'] == itemId);
      } else {
        selectedItems.add(selectedItem);
      }

      print(selectedItems);
    });
  }

  void _incrementCounter(int itemId) {
    setState(() {
      _counters[itemId] = (_counters[itemId] ?? 0) + 1;

      // تحديث قيمة العداد في selectedItems إذا كان العنصر موجودًا بالفعل
      final index =
          selectedItems.indexWhere((element) => element['id'] == itemId);
      if (index != -1) {
        selectedItems[index]['counter'] = _counters[itemId];
      }
    });
  }

  void _decrementCounter(int itemId) {
    setState(() {
      if ((_counters[itemId] ?? 0) > 0) {
        _counters[itemId] = (_counters[itemId] ?? 0) - 1;

        // تحديث قيمة العداد في selectedItems إذا كان العنصر موجودًا بالفعل
        final index =
            selectedItems.indexWhere((element) => element['id'] == itemId);
        if (index != -1) {
          selectedItems[index]['counter'] = _counters[itemId];
        }
      }
    });
  }

  void compareVersions(
      String currentVersion, String latestVersion, String urlupdate) {
    if (currentVersion != latestVersion) {
      showUpdateDialog(latestVersion, urlupdate); // عرض نافذة لتحديث التطبيق
    } else {
      print("التطبيق محدث إلى أحدث إصدار.");
    }
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Directionality(
      textDirection: TextDirection.rtl, // تحديد الاتجاه من اليمين إلى اليسار

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
                    
                  },
                  child: const Text(
                    'اضافة السلع',
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
              RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 20, top: 20),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'برنامج ايقلو',
                              style:
                                  TextStyle(fontFamily: 'arabic', fontSize: 25),
                            ),
                            Text(
                              'ادارة سلعة المستودع',
                              style:
                                  TextStyle(fontFamily: 'arabic', fontSize: 25),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 23),
                      Container(
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(left: 60, right: 10),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'ابحث عن السلعة',
                            suffixIcon: const Icon(Icons.search),
                            hintStyle: const TextStyle(
                              fontFamily: 'arabic',
                              color: Color.fromARGB(255, 167, 165, 165),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                width: 2.2,
                                color: Color.fromARGB(255, 190, 190, 190),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 190, 190, 190),
                                width: 2.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final categoryName = categories[index]['name'];
                            return InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () => fetchItems(categories[index]['id']),
                              child: Container(
                                alignment: Alignment.center,
                                width: 130,
                                margin: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFF26292E),
                                ),
                                padding: const EdgeInsets.all(5),
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'arabic',
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: size.width,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: const Text(
                          'سلعة',
                          style: TextStyle(fontFamily: 'arabic', fontSize: 25),
                        ),
                      ),
                      Container(
                        child: items.isNotEmpty
                            ? Stack(
                                children: [
                                  ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final Map<String, dynamic> item =
                                          items[index];
                                      final String itemsname =
                                          item['name'] ?? 'غير معروف';
                                      final int itemId = item['id'] ?? 0;
                                      final bool isSelected = selectedItems.any(
                                          (element) => element['id'] == itemId);
                                      final int counterValue =
                                          _counters[itemId] ?? 0;
                                      return Container(
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                              left: 10, right: 10, top: 20),
                                          width: double.infinity,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                              width: 2.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                        255, 206, 204, 204)
                                                    .withOpacity(0.5),
                                                spreadRadius: 0,
                                                blurRadius: 9,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: Colors.white,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 10),
                                                    height: 20,
                                                    child: Image.asset(
                                                        'assets/images/photo.png'),
                                                  ),
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 8),
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 16),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          itemsname,
                                                          style: const TextStyle(
                                                            fontFamily:
                                                                'arabic',
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700),
                                                        ),
                                                        const SizedBox(
                                                            height: 5),
                                                        Text(
                                                          'المتبقي: ${item['quantity'] ?? 'غير معروف'}',
                                                          style:
                                                              const TextStyle(
                                                            fontFamily:
                                                                'arabic',
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    233,
                                                                    73,
                                                                    73),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (_isitemloading)
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        color: Colors.white.withOpacity(0.7),
                                        width: double.infinity,
                                        height: 1000 * items.length.toDouble(),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : const Center(child: Text('لا توجد سلع متاحة',style: TextStyle(fontFamily: "arabic"),)),
                            
                      ),
                                SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 150),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
            floatingActionButton:  FloatingActionButton(
            elevation: 0,
            isExtended: false,
            onPressed: () {
              // تصفية العناصر التي تحتوي على كمية 2 أو أقل
              final lowStockItems =
                  items.where((item) => (item['quantity'] ?? 0) <= 5).toList();

              // عرض العناصر في مربع حوار
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text(
                      'السلع قليلة المخزون',
                      style: TextStyle(fontFamily: 'arabic'),
                    ),
                    content: SizedBox(
                      height: 200,
                      width: double.maxFinite,
                      child: ListView.builder(
                        itemCount: lowStockItems.length,
                        itemBuilder: (context, index) {
                          final item = lowStockItems[index];
                          return ListTile(
                            title: Text(
                              item['name'] ?? 'غير معروف',
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(fontFamily: 'arabic'),
                            ),
                            subtitle: Text(
                              'الكمية: ${item['quantity'] ?? 0}',
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(fontFamily: 'arabic'),
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'إغلاق',
                          style: TextStyle(fontFamily: 'arabic'),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Icon(Icons.filter_list),
          ),
        
      
  
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
