import 'package:flutter/material.dart';
import 'package:igloo/websocket.dart';

class SelectedProduct extends StatefulWidget {
  const SelectedProduct({super.key});

  @override
  State<StatefulWidget> createState() => _SelectedProduct();
}

class _SelectedProduct extends State<SelectedProduct> {
  final WebSocketService _webSocketService = WebSocketService();

  // خريطة لتخزين البيانات مرتبة حسب التاريخ
  Map<String, List<Map<String, dynamic>>> itemsByDate = {};

  @override
  void initState() {
    super.initState();
    fetchItems(); // لتحميل البيانات الأولية إذا لزم الأمر
    _webSocketService.stream.listen((data) {
      print('Received data: $data'); // تأكد من تلقي البيانات بشكل صحيح
      if (data['action'] == 'send_items_info') {
        setState(() {
          // بناء خريطة من البيانات المستلمة، مرتبة حسب التاريخ
          itemsByDate = {};
          for (var item in data['itemsout']) {
            String date = item['date'];
            if (!itemsByDate.containsKey(date)) {
              itemsByDate[date] = [];
            }
            itemsByDate[date]!.add({
              'name': item['name'],
              'quantity': item['quantity'],
              'added_by': item['added_by'],
              'company': item['company']
            });
          }
          print("Data from socket: $itemsByDate");
        });
      } else if (data['status'] == 'error') {
        setState(() {});
      }
    }, onError: (error) {
      print('Error: $error'); // طباعة أي خطأ يحدث
    });
  }

  void fetchItems() {
    _webSocketService.sendMessage({
      'action': 'getselecteditem',
    });
  }

  Future<void> _refreshData() async {
    fetchItems(); // تحديث البيانات عند السحب لأسفل
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'سلعة خارجة',
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.black, fontFamily: 'arabic'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Container(
          width: size.width,
          height: size.height,
          child: itemsByDate.isNotEmpty
              ? ListView.builder(
                  reverse: false,
                  itemCount: itemsByDate.keys.length,
                  itemBuilder: (context, index) {
                    String date =
                        itemsByDate.keys.toList().reversed.elementAt(index);
                    List<Map<String, dynamic>> items = itemsByDate[date]!;

                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عرض التاريخ كعنوان كبير
                          Text(
                            date,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          // عرض العناصر المرتبطة بالتاريخ
                          ...items.reversed.map((item) {
                            return ListTile(
                              title: Text(
                                item['name'],
                                style: const TextStyle(
                                    fontFamily: 'arabic', fontSize: 18),
                              ), // عرض اسم العنصر
                              trailing: Column(
                                children: [
                                  Text(
                                        style: const TextStyle(
                                            fontFamily: 'arabic', fontSize: 11.7),
                                        'Quantity: ${item['quantity']}', // عرض الكمية
                                   ),
                                      //Text(
                                        //style: const TextStyle(
                                          //  fontFamily: 'arabic', fontSize: 10.6),
                                        //'${item['added_by']} : بواسطة', // عرض اسم المستخدم
                                      //),
                                  
                                   Text(
                                       style: const TextStyle(
                                          fontFamily: 'arabic', fontSize: 10.6),
                                       '${item['company']} :متجر', // عرض اسم المستخدم
                                      ),
                                                           
                                  
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                )
              : const Center(
                  child:
                      CircularProgressIndicator()), // عرض مؤشر التحميل إذا لم تكن هناك بيانات بعد
        ),
      ),
    );
  }
}
