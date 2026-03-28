import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:igloo/websocket.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

class SuperAdmin extends StatefulWidget {
  const SuperAdmin({super.key});

  @override
  State<StatefulWidget> createState() => _SuperAdmin();
}

class _SuperAdmin extends State<SuperAdmin> {
  final WebSocketService _webSocketService = WebSocketService();
  String? selectedValue;
  int? selectedBranchId;
  final List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> selectedItems = [];

  List<Map<String, dynamic>> items = [];

  final Map<int, int> _counters = {};
  final String currentVersion = '1.0.2';
  bool _isLoading = false;
  bool _isitemloading = false;
  bool _isLoggedIn = false;
  int? branchid;
  List<Map<String, dynamic>> branches = [];
  bool serverAlive = true;
  String connectionState = "connected";
  Timer? pingTimer;
  Timer? pongTimeout;
  bool reconnecting = false;
  int selectedIndex = 0;

  Future<void> fetchCategories() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    int? branchid = prefs.getInt('branch_id');

    if (branchid == 0) {
      _webSocketService.sendMessage({
        'action': 'get_catego',
      });
    } else {
      _webSocketService.sendMessage({
        'action': 'get_categories_by_branch',
        "branch_id": branchid,
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initData();
    fetchCategories();
    checkLogin();
    fetchBranches();
    pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _webSocketService.sendMessage({"action": "ping"});

      pongTimeout?.cancel();

      pongTimeout = Timer(const Duration(seconds: 2), () {
        setState(() {
          serverAlive = false;
        });
        showConnectionError();

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
        if (data['status'] == 'items_list_all') {
          setState(() {
            items = List<Map<String, dynamic>>.from(data['items']);
            _isLoading = false;
            _isitemloading =
                false; // تعيين حالة التحميل إلى false بعد تحميل العناصر
            print('Updated items: $items');
          });
        }

        if (data['status'] == 'items_list') {
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
        } else if (data['status'] == 'category_list') {
          print(data);
          setState(() {
            categories.clear();
            categories
                .addAll(List<Map<String, dynamic>>.from(data['categories']));

            if (categories.isNotEmpty) {
              fetchItems(categories[0]['id']);
            }
          });
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
        } else if (data['status'] == 'branch_list') {
          setState(() {
            branches.clear();
            branches.addAll(List<Map<String, dynamic>>.from(data['branches']));
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
        } else if (data['status'] == 'update_success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              margin: const EdgeInsets.only(
                bottom: 20,
                left: 80,
                right: 80,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: const Text(
                'تم التعديل بنجاح',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'arabic',
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          );
        } else if (data["action"] == "pong") {
          pongTimeout?.cancel();

          if (!serverAlive) {
            setState(() {
              serverAlive = true;
            });
            hideConnectionError();
          }
        } else if (data['status'] == 'not_available') {
          setState(() {
            _isitemloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              margin: const EdgeInsets.only(
                bottom: 20,
                left: 80,
                right: 80,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(
                '❌ العملية أُلغيت: ${data['items'].join(', ')} غير متوفر',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'arabic',
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          );
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

  Future<void> _refreshData() async {
    fetchCategories(); // تحديث البيانات عند السحب لأسفل
  }

  void fetchItems(int categoryId) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    int? branchid = prefs.getInt('branch_id');

    if (branchid == 0) {
      _webSocketService.sendMessage({
        'action': 'get_items_all_branches',
        'category_id': categoryId,
      });
    } else {
      _webSocketService.sendMessage({
        'action': 'get_items_bybranchandcatego',
        'branch_id': branchid,
        'category_id': categoryId,
      });
    }
  }

  /*void fetchItems(int categoryId) {
    setState(() {
      _isitemloading = true; // تعيين حالة التحميل إلى true عند بدء الجلب
    });
    _webSocketService.sendMessage({
      'action': 'get_items_by_category',
      'category_id': categoryId,
    });
  }
*/
  void saveSelectedItems() async {
    final now = DateTime.now().toIso8601String();
    print("SAVE CLICKED");
    final List<Map<String, dynamic>> itemsToSend = selectedItems.map((item) {
      final itemId = item['id'];
      final itemName = item['name'];
      final itemCounter = _counters[itemId] ?? 0;

      return {
        'id': itemId,
        'name': itemName,
        'counter': itemCounter,
      };
    }).toList();
    String? username = await getUsername();
    String? companyname = selectedValue;
    _webSocketService.sendMessage({
      'action': 'selcteditem',
      'itemsSelected': itemsToSend,
      'branch_id': selectedBranchId,
      'category_id': categories[0]['id'],
      'date': now,
      'added_by': username,
      'company': companyname,
    });
    setState(() {
      for (var itemId in _counters.keys) {
        _counters[itemId] = 0;
      }

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

  Future<int?> getbranchid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('branch_id');
  }

  Future<void> initData() async {
    branchid = await getbranchid();

    print("branchid = $branchid");
  }

  void fetchBranches() {
    _webSocketService.sendMessage({"action": "get_branch"});
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

      // إضافة أو تحديث العنصر في selectedItems
      final index =
          selectedItems.indexWhere((element) => element['id'] == itemId);
      if (index == -1) {
        // إذا لم يكن العنصر موجودًا، يتم إضافته
        selectedItems.add({
          'id': itemId,
          'name': items.firstWhere((item) => item['id'] == itemId)['name'],
          'counter': _counters[itemId],
        });
      } else {
        // إذا كان العنصر موجودًا، يتم تحديث العداد
        selectedItems[index]['counter'] = _counters[itemId];
      }
    });
  }

  void _decrementCounter(int itemId) {
    setState(() {
      if ((_counters[itemId] ?? 0) > 0) {
        _counters[itemId] = (_counters[itemId] ?? 0) - 1;

        // تحديث أو إزالة العنصر من selectedItems
        final index =
            selectedItems.indexWhere((element) => element['id'] == itemId);
        if (index != -1) {
          if (_counters[itemId] == 0) {
            // إذا أصبح العداد صفرًا، يتم إزالة العنصر
            selectedItems.removeAt(index);
          } else {
            // إذا لم يصل العداد إلى صفر، يتم تحديثه
            selectedItems[index]['counter'] = _counters[itemId];
          }
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
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

  void showPopup() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('اختر الفرع'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];

                return ListTile(
                  title: Text(branch['branchname']),
                  onTap: () {
                    Navigator.of(context).pop(branch);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      selectedValue = result['branchname'];
      selectedBranchId = result['id'];

      print("Selected branch: $selectedBranchId");

      // 🔥 الحل هنا
      saveSelectedItems(); // ✅ استدعاء الدالة بعد الاختيار
    }
  }

  void _showEditDialog(BuildContext context, int itemId, String currentName,
      int currentQuantity) {
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final TextEditingController quantityController =
        TextEditingController(text: currentQuantity.toString());
    final TextEditingController addQuantityController = TextEditingController();

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.edit, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        'تعديل السلعة',
                        style: TextStyle(
                          fontFamily: 'arabic',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔹 اسم السلعة
                  _modernField(
                    controller: nameController,
                    label: 'اسم السلعة',
                    icon: Icons.inventory,
                  ),

                  const SizedBox(height: 12),

                  // 🔹 الكمية الحالية
                  _modernField(
                    controller: quantityController,
                    label: 'الكمية الحالية',
                    icon: Icons.numbers,
                    isNumber: true,
                  ),

                  const SizedBox(height: 12),

                  _modernField(
                    controller: addQuantityController,
                    label: 'إضافة كمية',
                    icon: Icons.add,
                    isNumber: true,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
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
                                fontFamily: 'arabic', color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1E1E1E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final updatedName = nameController.text.trim();
                            final updatedQuantity =
                                int.tryParse(quantityController.text.trim()) ??
                                    currentQuantity;
                            final addedQuantity = int.tryParse(
                                    addQuantityController.text.trim()) ??
                                0;
                            final prefs = await SharedPreferences.getInstance();
                            int? branchid = prefs.getInt('branch_id');

                            _updateItem(itemId, updatedName, updatedQuantity,
                                addedQuantity, branchid);

                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'حفظ',
                            style: TextStyle(
                                fontFamily: 'arabic', color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _modernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      textDirection: TextDirection.rtl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontFamily: "arabic"),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'arabic'),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xffF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

// الدالة لتحديث العنصر في القائمة
  void _updateItem(int itemId, String updatedName, int updatedQuantity,
      int addedQuantity, int? branchid) {
    setState(() {
      for (var item in items) {
        if (item['id'] == itemId) {
          // تحديث القيم محليًا
          item['name'] = updatedName;
          item['quantity'] = updatedQuantity + addedQuantity;

          // إرسال التعديلات إلى السيرفر
          _webSocketService.sendMessage({
            'action': 'update_item',
            'item_id': itemId,
            'branch_id': branchid,
            'updated_name': updatedName,
            'updated_quantity': updatedQuantity,
            'added_quantity': addedQuantity,
          });

          break;
        }
      }
    });
  }

  OverlayEntry? overlayEntry;

  void showConnectionError() {
    if (overlayEntry != null) return; // لا تعيد إضافته

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "خطأ بالشبكة.. جاري إعادة الاتصال",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontFamily: 'arabic'),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  void hideConnectionError() {
    overlayEntry?.remove();
    overlayEntry = null;
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

  Widget _darkFab({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff1E1E1E), // 👈 غامق فاخر
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          icon,
          color: Colors.white, // 👈 واضح على الخلفية الغامقة
        ),
      ),
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
              RefreshIndicator(
                color: const Color.fromARGB(255, 0, 0, 0), // لون الدائرة
                backgroundColor: Colors.white, // خلفية الدائرة
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
                        height: 55,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final categoryName = categories[index]['name'];
                            final isSelected = selectedIndex == index;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                                fetchItems(categories[index]['id']);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                alignment: Alignment.center,
                                width: 130,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 6),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),

                                  // 🎨 لون حسب الاختيار
                                  color: isSelected
                                      ? const Color(0xff1E1E1E) // غامق
                                      : const Color(0xffF3F4F6), // فاتح

                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  categoryName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'arabic',
                                    fontWeight: FontWeight.w600,

                                    // 🎨 لون النص
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
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
                                      final item = items[index];
                                      final int quantity =
                                          item['quantity'] ?? 0;
                                      final String itemsname =
                                          item['name'] ?? 'غير معروف';
                                      final int itemId = item['id'] ?? 0;

                                      final bool isSelected = selectedItems.any(
                                          (element) => element['id'] == itemId);

                                      final int counterValue =
                                          _counters[itemId] ?? 0;

                                      return GestureDetector(
                                        onTap: () => toggleSelection(item),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: isSelected
                                                ? Border.all(
                                                    color:
                                                        const Color(0xff1E1E1E),
                                                    width: 1.5)
                                                : null,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.06),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xffF3F4F6),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.inventory_2_outlined,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      itemsname,
                                                      style: const TextStyle(
                                                        fontFamily: 'arabic',
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      'المتبقي: $quantity',
                                                      style: TextStyle(
                                                        fontFamily: 'arabic',
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: quantity <= 5
                                                            ? Colors.red
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      _showEditDialog(
                                                          context,
                                                          itemId,
                                                          itemsname,
                                                          quantity);
                                                    },
                                                    icon: const Icon(Icons.edit,
                                                        size: 18),
                                                  ),
                                                  IconButton(
                                                    onPressed: () =>
                                                        _incrementCounter(
                                                            itemId),
                                                    icon: const Icon(Icons
                                                        .add_circle_outline),
                                                  ),
                                                  Text(
                                                    '$counterValue',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () =>
                                                        _decrementCounter(
                                                            itemId),
                                                    icon: const Icon(Icons
                                                        .remove_circle_outline),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (_isitemloading)
                                    Container(
                                      color: Colors.white.withOpacity(0.6),
                                      child: const Center(
                                        child: CupertinoActivityIndicator(
                                            radius: 15),
                                      ),
                                    ),
                                ],
                              )
                            : const Center(
                                child: Text(
                                  'لا توجد سلع متاحة',
                                  style: TextStyle(fontFamily: "arabic"),
                                ),
                              ),
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
                    child: CupertinoActivityIndicator(
                      radius: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: [
            _darkFab(
              icon: Icons.add,
              onTap: showPopup,
            ),

            const SizedBox(width: 20), // 👈 خليتها أصغر عشان الشكل يكون مرتب

            _darkFab(
              icon: Icons.filter_list,
              onTap: () {
                final lowStockItems = items
                    .where((item) => (item['quantity'] ?? 0) <= 5)
                    .toList();

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
                            // 🔴 العنوان + أيقونة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.red, size: 26),
                                SizedBox(width: 8),
                                Text(
                                  'السلع قليلة المخزون',
                                  style: TextStyle(
                                    fontFamily: 'arabic',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            SizedBox(
                              height: 220,
                              child: ListView.builder(
                                itemCount: lowStockItems.length,
                                itemBuilder: (context, index) {
                                  final item = lowStockItems[index];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF5F5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${item['quantity'] ?? 0}',
                                            style: const TextStyle(
                                              fontFamily: 'arabic',
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item['name'] ?? 'غير معروف',
                                            textDirection: TextDirection.rtl,
                                            style: const TextStyle(
                                              fontFamily: 'arabic',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xffEEEEEE),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                              Icons.inventory_2_outlined),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff1E1E1E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'إغلاق',
                                  style: TextStyle(
                                      fontFamily: 'arabic',
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
