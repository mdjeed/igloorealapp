import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late WebSocketChannel channel;
  Map<int, Map<String, List<Map<String, String>>>> attendanceData = {};
  List<String> availableMonths = [];
  String selectedMonth = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    channel = IOWebSocketChannel.connect('ws://clearly-tidy-skink.ngrok-free.app');
    fetchAttendanceData();
  }

  void fetchAttendanceData() {
    channel.sink.add('get_attendance');

    channel.stream.listen(
      (message) {
        handleMessage(message);
      },
      onError: (error) {
        print("Error: $error");
      },
      onDone: () {
        print("WebSocket connection closed");
      },
    );
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
      attendanceData.clear();
    });

    channel.sink.add('get_attendance');
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      isLoading = false;
    });
  }

  void handleMessage(String message) {
  try {
    final data = jsonDecode(message) as List<dynamic>;

    if (data.isNotEmpty) {
      setState(() {
        isLoading = false;
        attendanceData.clear();

        availableMonths.clear();

        Map<int, String> allEmployees = {}; // لتخزين جميع الموظفين

        for (var item in data) {
          int employeeId = item['employee_id'];
          String name = item['name'] ?? 'Unknown';
          String time = item['time'] ?? 'N/A';
          String type = item['type'] ?? 'entry';

          String timeOnly = formatTime(DateTime.parse(time));
          String dateOnly = time.split(' ')[0]; // استخراج التاريخ فقط
          String monthYear = dateOnly.substring(0, 7); // استخراج الشهر والسنة

          // حفظ أسماء الموظفين
          allEmployees[employeeId] = name;

          if (!attendanceData.containsKey(employeeId)) {
            attendanceData[employeeId] = {};
          }

          if (!attendanceData[employeeId]!.containsKey(dateOnly)) {
            attendanceData[employeeId]![dateOnly] = [];
          }

          attendanceData[employeeId]![dateOnly]!.add({
            'name': name,
            'time': timeOnly,
            'type': type,
          });

          if (!availableMonths.contains(monthYear)) {
            availableMonths.add(monthYear);
          }
        }

        // إضافة جميع الموظفين إلى الحضور لضمان ظهورهم حتى بدون سجلات
        allEmployees.forEach((employeeId, name) {
          if (!attendanceData.containsKey(employeeId)) {
            attendanceData[employeeId] = {};
          }
          availableMonths.forEach((monthYear) {
            attendanceData[employeeId]!.putIfAbsent(monthYear, () => []);
          });
        });
      });
    } else {
      print("Received empty data");
    }
  } catch (e) {
    print("Error parsing message: $e");
  }
}
  String formatTime(DateTime dateTime) {
    return dateTime.toLocal().toString().split(' ')[1].substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'تسجيل الخدامين',
          style: TextStyle(fontFamily: 'arabic'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // قائمة الأشهر
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      isExpanded: false,
                      borderRadius: BorderRadius.circular(10),
                      dropdownColor: Colors.white,
                      elevation: 4,
                      
                      


                      value: selectedMonth.isEmpty ? null : selectedMonth,
                      hint: Text("اختر الشهر والسنة",style: TextStyle(fontFamily: "arabic",),textDirection: TextDirection.rtl,textAlign: TextAlign.right,),
                      items: availableMonths.map((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedMonth = value ?? '';
                        });
                      },
                    ),
                  ),

                  // عرض بيانات الحضور
                  Expanded(
                    child: ListView.builder(
                      itemCount: attendanceData.values
                          .expand((e) => e.keys)
                          .toSet()
                          .where((date) =>
                              date.startsWith(selectedMonth)) // تصفية البيانات حسب الشهر
                          .length,
                      itemBuilder: (context, index) {
                        final dates = attendanceData.values
                            .expand((e) => e.keys)
                            .toSet()
                            .where((date) =>
                                date.startsWith(selectedMonth)) // تصفية البيانات حسب الشهر
                            .toList()
                          ..sort((a, b) => b.compareTo(a));

                        String currentDisplayedDate = dates[index];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                currentDisplayedDate,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            ...attendanceData.entries.map((entry) {
                              final employeeId = entry.key;
                              final recordsByDate = entry.value;
                              final employeeName = recordsByDate.values.isNotEmpty
                                  ? recordsByDate.values.first.first['name']!
                                  : 'Unknown';

                              String? firstEntryTime = recordsByDate[currentDisplayedDate]?.firstWhere(
                                (record) => record['type'] == 'entry',
                                orElse: () => {'time': 'N/A'},
                              )['time'];

                              String? firstExitTime = recordsByDate[currentDisplayedDate]?.firstWhere(
                                (record) => record['type'] == 'exit',
                                orElse: () => {'time': 'N/A'},
                              )['time'];

                              return ListTile(
                                title: Text(employeeName),
                                subtitle: Text(
                                  'Entry: ${firstEntryTime ?? 'off'}\nExit: ${firstExitTime ?? 'off'}',
                                ),
                                leading: Icon(Icons.person),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EmployeeAttendancePage(
                                        employeeId: employeeId,
                                        employeeName: employeeName,
                                        recordsByDate: recordsByDate,
                                        currentDate: currentDisplayedDate,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}





class EmployeeAttendancePage extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final Map<String, List<Map<String, String>>> recordsByDate;
  final String currentDate;

  const EmployeeAttendancePage({
    Key? key,
    required this.employeeId,
    required this.employeeName,
    required this.recordsByDate,
    required this.currentDate,
  }) : super(key: key);

  @override
  _EmployeeAttendancePageState createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  String selectedMonth = '';
  int totalMinutesWorked = 0; // لتخزين عدد الدقائق الكلي

  @override
  Widget build(BuildContext context) {
    List<String> months = widget.recordsByDate.keys.map((date) {
      return date.substring(0, 7); // استخراج الشهر من السجل
    }).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          '${widget.employeeName} تسجيلات الخاصة ب',
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'arabic'),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'تسجيلات ',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'arabic'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
               isExpanded: false,
                      borderRadius: BorderRadius.circular(10),
                      dropdownColor: Colors.white,
                      elevation: 4,
                      
              value: selectedMonth.isEmpty ? null : selectedMonth,
              hint: Text('اختر الشهر',style: TextStyle(fontFamily: 'arabic'),),
              onChanged: (String? newValue) {
                setState(() {
                  selectedMonth = newValue!;
                });
              },
              items: months.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
           MaterialButton(
                
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                height: 40,
                elevation: 0,
               onPressed: selectedMonth.isEmpty
                  ? null
                  : () {
                      _calculateTotalHours();
                    },
                     color: const Color(0xFF242732),
                textColor: Colors.white,
                child: const Text(
                  "حساب ساعات العمل للشهر",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'arabic',
                  ),
                ),
             
            ),
               
              ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.recordsByDate.keys.length,
              itemBuilder: (context, index) {
                String date = widget.recordsByDate.keys.elementAt(index);

                // تصفية السجلات حسب الشهر المحدد
                if (selectedMonth.isNotEmpty && !date.startsWith(selectedMonth)) {
                  return SizedBox(); // لا عرض السجل إذا لم يكن في الشهر المحدد
                }

                List<Map<String, String>> records = widget.recordsByDate[date]!;

                return Card(
                  color:const Color.fromARGB(255, 241, 241, 241) ,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...records.map((record) {
                          return ListTile(
                            title: Text(
                                record['type'] == 'entry' ? 'Entry' : 'Exit'),
                            subtitle: Text(record['time']!),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // حساب الساعات الكلية بالدقائق والساعات بناءً على الشهر
void _calculateTotalHours() {
  totalMinutesWorked = 0; // إعادة تعيين الدقائق الكلية
  int attendanceDays = 0; // لتخزين عدد الأيام التي حضر فيها الموظف
  Map<String, int> dailyWorkMinutes = {}; // تخزين عدد دقائق العمل لكل يوم

  widget.recordsByDate.forEach((date, records) {
    if (selectedMonth.isNotEmpty && !date.startsWith(selectedMonth)) return;

    // تصفية السجلات لتضمين "entry" و "exit" فقط
    List<Map<String, String>> entryRecords = [];
    List<Map<String, String>> exitRecords = [];

    for (var record in records) {
      if (record['type'] == 'entry') {
        entryRecords.add(record);
      } else if (record['type'] == 'exit') {
        exitRecords.add(record);
      }
    }

    int dailyMinutes = 0;

    // التحقق من أن هناك تسجيل دخول وتسجيل خروج مرتبط به
    for (int i = 0; i < entryRecords.length; i++) {
      if (i < exitRecords.length) {
        // استخراج الوقت من السجلات
        String entryTime = entryRecords[i]['time']!;
        String exitTime = exitRecords[i]['time']!;

        // تحويل الوقت من النص إلى TimeOfDay
        DateTime entry = _parseTime(entryTime);
        DateTime exit = _parseTime(exitTime);

        // حساب الفرق بين دخول وخروج
        int diffMinutes = exit.difference(entry).inMinutes;
        dailyMinutes += diffMinutes;
      }
    }

    if (dailyMinutes > 0) {
      attendanceDays++; // زيادة عدد أيام الحضور
      dailyWorkMinutes[date] = dailyMinutes; // تخزين دقائق العمل لليوم
      totalMinutesWorked += dailyMinutes; // إضافة الدقائق الكلية
    }
  });

  // تحويل الدقائق الكلية إلى ساعات ودقائق
  int hours = totalMinutesWorked ~/ 60;
  int minutes = totalMinutesWorked % 60;

  // عرض النتيجة في نافذة منبثقة
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text('تفاصيل ساعات العمل', style: TextStyle(fontFamily: 'arabic')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إجمالي ساعات العمل في الشهر: $hours ساعة و $minutes دقيقة',
              style: TextStyle(fontFamily: 'arabic'),
            ),
            SizedBox(height: 10),
            Text(
              'عدد أيام الحضور: $attendanceDays يوم',
              style: TextStyle(fontFamily: 'arabic'),
            ),
            SizedBox(height: 10),
            Text(
              ':تفاصيل العمل اليومي',
              style: TextStyle(fontFamily: 'arabic', fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...dailyWorkMinutes.entries.map((entry) {
              int dailyHours = entry.value ~/ 60;
              int dailyMinutes = entry.value % 60;
              return Text(
                
                '${entry.key}:   $dailyHours ساعة و $dailyMinutes دقيقة   ', 
                style: TextStyle(fontFamily: 'arabic'),
                textDirection: TextDirection.rtl,
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('إغلاق', style: TextStyle(fontFamily: 'arabic')),
          ),
        ],
      );
    },
  );
}

  // تحويل الوقت من النص إلى DateTime
  DateTime _parseTime(String timeString) {
    List<String> parts = timeString.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return DateTime(0, 1, 1, hour, minute); // استخدام تاريخ ثابت للتحويل فقط
  }
}
