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
   final TextEditingController _categoname= TextEditingController();
  int? _selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  @override
  void initState() {
    super.initState();
    // جلب التصنيفات من الخادم عند تحميل الصفحة
    fetchCategories();

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

  void saveProduct() {
    final productName = _nameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

    if (productName.isEmpty || _selectedCategoryId == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'رجاءً تحقق من الحقول بشكل صحيح',
            style: TextStyle(fontFamily: 'arabic'),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _webSocketService.sendMessage({
      'action': 'add_product',
      'name': productName,
      'quantity': quantity,
      'category_id': _selectedCategoryId,
    });

    _webSocketService.sendMessage({
      'action': 'get_items_by_category',
      'category_id': _selectedCategoryId,
    });

    // إفراغ الحقول بعد الإرسال
    _nameController.clear();
    _quantityController.clear();
    setState(() {
     
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          'تم إضافة السلعة بنجاح',
          style: TextStyle(fontFamily: 'arabic'),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }


      void add_catego()
    {
       final  addcatego= _categoname.text.trim();

       _webSocketService.sendMessage({
      'action': 'add_category',
      'name': addcatego,
    });


_categoname.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          'تم إضافة التصنيف بنجاح',
          style: TextStyle(fontFamily: 'arabic'),
        ),
        duration: Duration(seconds: 2),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Container(
                alignment: Alignment.center,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFF7F7F7)),
                child: TextField(
                  style: TextStyle(fontFamily:"arabic" ),
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "اسم السلعة",
                      hintTextDirection: TextDirection.rtl,
                      hintStyle:
                          TextStyle(fontFamily: 'arabic', color: Colors.grey)),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                alignment: Alignment.center,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFF7F7F7)),
                child: TextField(
                  controller: _quantityController,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily:"arabic" ),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "العدد",
                      hintTextDirection: TextDirection.rtl,
                      hintStyle:
                          TextStyle(fontFamily: 'arabic', color: Colors.grey)),
                ),
              ),
              DropdownButton<int>(
                borderRadius: BorderRadius.circular(10),
                dropdownColor: Colors.white,
                hint: const Text(
                  'اختر تصنيف السلعة',
                  style: TextStyle(
                    fontFamily: 'arabic',
                  ),
                ),
                value: _selectedCategoryId,
                items: categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['name'],style: TextStyle(fontFamily: "arabic"),),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategoryId = newValue;
                  });
                },
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                margin: const EdgeInsets.only(left: 20, right: 20),
                child: MaterialButton(
                  minWidth: double.infinity,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  height: 40,
                  elevation: 0,
                  onPressed: saveProduct,
                  color: const Color(0xFF242732),
                  textColor: Colors.white,
                  child: const Text(
                    "حفظ السلعة ",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'arabic',
                    ),
                  ),
                ),
              ),
                   SizedBox(height: 30,),
               Container(
                alignment: Alignment.center,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFF7F7F7)),
                child: TextField(
                  controller: _categoname,
                  style: TextStyle(fontFamily:"arabic" ),
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                  
                      border: InputBorder.none,
                      hintText: "اسم التصنيف",
                      hintTextDirection: TextDirection.rtl,
                      hintStyle:
                          TextStyle(fontFamily: 'arabic', color: Colors.grey)),
                ),
              ),
              SizedBox(height: 15,),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                margin: const EdgeInsets.only(left: 20, right: 20),
                child: MaterialButton(
                  minWidth: double.infinity,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  height: 40,
                  elevation: 0,
                  onPressed: add_catego,
                  color: const Color(0xFF242732),
                  textColor: Colors.white,
                  child: const Text(
                    "اضافة تصنيف",
                    style: TextStyle(
                      fontSize: 13,
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
