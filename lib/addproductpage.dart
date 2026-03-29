import 'package:flutter/material.dart';
import 'package:igloo/websocket.dart';
import 'dart:convert';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class Addproductpage extends StatefulWidget {
  const Addproductpage({super.key});

  @override
  State<StatefulWidget> createState() => _Addproductpage();
}

class _Addproductpage extends State<Addproductpage> {
  final WebSocketService _webSocketService = WebSocketService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _categoname = TextEditingController();
  int? _selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  int? _selectedBranchId;
  List branches = [];
  @override
  void initState() {
    super.initState();
    // جلب التصنيفات من الخادم عند تحميل الصفحة
    fetchCategories();
    fetchBranches();

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

        if (data['status'] == 'catego list') {
          setState(() {
            categories = List<Map<String, dynamic>>.from(data['categories']);
          });
        } else if (data['status'] == 'branch_list') {
          setState(() {
            branches = message['branches'];
          });
        } else if (data['status'] == 'error') {
          print('Error status received');
        }
      } catch (e) {
        print('Error parsing JSON: $e');
      }
    }, onError: (error) {
      print('Error: $error');
    });
  }

  void fetchCategories() {
    _webSocketService.sendMessage({
      'action': 'get_catego',
    });
  }

  void fetchBranches() {
    setState(() {});
    _webSocketService.sendMessage({
      'action': 'get_branch',
    });
  }

  void saveProduct() {
    final productName = _nameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

    if (productName.isEmpty ||
        _selectedCategoryId == null ||
        _selectedBranchId == null || // 🔥 تحقق من الفرع
        quantity <= 0) {
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
          content: const Text(
            'رجاءً تحقق من الحقول بشكل صحيح',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'arabic',
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }

    _webSocketService.sendMessage({
      'action': 'add_product',
      'name': productName,
      'quantity': quantity,
      'category_id': _selectedCategoryId,
      'branch_id': _selectedBranchId, // 🔥 الجديد
    });

    _webSocketService.sendMessage({
      'action': 'get_items_by_category',
      'category_id': _selectedCategoryId,
      'branch_id': _selectedBranchId, // 🔥 مهم إذا عندك فلترة حسب الفرع
    });

    _nameController.clear();
    _quantityController.clear();

    setState(() {});

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
          'تم إضافة السلعة بنجاح',
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

  void add_catego() {
    final addcatego = _categoname.text.trim();

    // تحقق من الحقل
    if (addcatego.isEmpty) {
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
          content: const Text(
            'الرجاء إدخال اسم التصنيف',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'arabic',
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
      );

      return;
    }

    _webSocketService.sendMessage({
      'action': 'add_category',
      'name': addcatego,
    });

    _categoname.clear();

    FocusScope.of(context).unfocus();

    // رسالة نجاح
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
          'تم إضافة التصنيف بنجاح',
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

  Widget _modernInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xffF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: "arabic"),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'arabic'),
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget _mainButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(
              fontFamily: 'arabic',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'إضافة سلعة جديدة',
          style: TextStyle(fontFamily: 'arabic'),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              const Text(
                "إضافة سلعة",
                style: TextStyle(
                  fontFamily: 'arabic',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _modernInput(
                controller: _nameController,
                hint: "اسم السلعة",
                icon: Icons.inventory_2_outlined,
              ),

              const SizedBox(height: 15),

              _modernInput(
                controller: _quantityController,
                hint: "العدد",
                icon: Icons.numbers,
                isNumber: true,
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xffF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCategoryId,
                    hint: const Text(
                      'اختر تصنيف السلعة',
                      style: TextStyle(fontFamily: 'arabic'),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(
                          category['name'],
                          style: const TextStyle(fontFamily: "arabic"),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategoryId = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xffF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedBranchId,
                    hint: const Text(
                      'اختر الفرع',
                      style: TextStyle(fontFamily: 'arabic'),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: branches.map((branch) {
                      return DropdownMenuItem<int>(
                        value: branch['id'],
                        child: Text(
                          branch['branchname'], // حسب اسم العمود عندك
                          style: const TextStyle(fontFamily: "arabic"),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedBranchId = newValue;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _mainButton(
                title: "حفظ السلعة",
                onTap: saveProduct,
              ),

              const SizedBox(height: 30),

              // 🔷 Divider
              const Divider(thickness: 1),

              const SizedBox(height: 20),

              const Text(
                "إضافة تصنيف",
                style: TextStyle(
                  fontFamily: 'arabic',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _modernInput(
                controller: _categoname,
                hint: "اسم التصنيف",
                icon: Icons.category_outlined,
              ),

              const SizedBox(height: 15),

              _mainButton(
                title: "إضافة تصنيف",
                onTap: add_catego,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
