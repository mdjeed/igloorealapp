import 'package:flutter/material.dart';


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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),

              const SizedBox(height: 20),

             
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: chartCard,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),

              const SizedBox(height: 24),

         
              Row(
                children: [
                  Expanded(child: _smallCard(greenCard)),
                  const SizedBox(width: 12),
                  Expanded(child: _smallCard(purpleCard)),
                  const SizedBox(width: 12),
                  Expanded(child: _smallCard(brownCard)),
                ],
              ),
            ],
          ),
        ),
      ),

   
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() {});
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: ""),
        ],
      ),
    );
  }


  Widget _smallCard(Color color) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
