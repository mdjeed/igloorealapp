import 'package:flutter/material.dart';
import 'package:igloo/websocket.dart';
import 'package:flutter/cupertino.dart';

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
                  itemCount: itemsByDate.keys.length,
                  itemBuilder: (context, index) {
                    String date =
                        itemsByDate.keys.toList().reversed.elementAt(index);
                    List<Map<String, dynamic>> items = itemsByDate[date]!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔷 التاريخ (Header)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xffF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              date,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'arabic',
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 🔹 العناصر
                          ...items.reversed.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // 🔸 أيقونة
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF3F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // 🔸 النصوص
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontFamily: 'arabic',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'متجر: ${item['company']}',
                                          style: const TextStyle(
                                            fontFamily: 'arabic',
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🔸 الكمية
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffEEEEEE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '-${item['quantity']}',
                                      style: const TextStyle(
                                        fontFamily: 'arabic',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                  child: CupertinoActivityIndicator(radius: 15),
                ),
        ),
      ),
    );
  }
}
