import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'stay_focused_page.dart';

class TakeABreakPage extends StatefulWidget {
  final int breakMinutes;

  const TakeABreakPage({
    Key? key,
    this.breakMinutes = 5,
  }) : super(key: key);

  @override
  State<TakeABreakPage> createState() => _TakeABreakPageState();
}

class _TakeABreakPageState extends State<TakeABreakPage> {
  late int _remainingSeconds;
  late Timer _timer;
  late int _breakTime;

  @override
  void initState() {
    super.initState();
    _loadBreakTimeFromSettings();
    _remainingSeconds = widget.breakMinutes * 60;
    _startTimer();
  }

  Future<void> _loadBreakTimeFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _breakTime = prefs.getInt('breakTime') ?? 5;
      });
    } catch (e) {
      setState(() {
        _breakTime = 5;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _backToFocus();
        }
      });
    });
  }

  void _backToFocus() {
    _timer.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const StayFocusedPage(
          taskTitle: 'Finish UI Design',
          taskId: 'task123',
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        // ✅ เปลี่ยน gradient เป็นสีเข้มเหมือน login
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? const [
                    Color.fromARGB(255, 3, 1, 59),
                    Color.fromARGB(255, 41, 28, 114),
                  ]
                : [Colors.orange.shade400, Colors.orange.shade200],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ✅ Header
                Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 100),
                      painter: WaveHeaderPainter(isDarkMode: isDarkMode),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: const Text(
                        'Take a Break',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // ✅ Sleeping Cat
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ✅ เปลี่ยนสี background ตามธีม
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                  ),
                  child: Center(
                    child: Text(
                      '😴',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // ✅ Timer Circle
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // ✅ Message
                Text(
                  'Rest Your Eyes',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 60),
                // ✅ Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _timer.cancel();
                            _backToFocus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.white.withOpacity(0.12)
                                : Colors.black.withOpacity(0.1),
                            side: BorderSide(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.2),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _timer.cancel();
                            Navigator.of(context).pushNamed('/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Give Up',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.black87
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            _timer.cancel();
            Navigator.of(context).pushNamed('/home');
          } else if (index == 2) {
            _timer.cancel();
            Navigator.of(context).pushNamed('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class WaveHeaderPainter extends CustomPainter {
  final bool isDarkMode;

  WaveHeaderPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width * 0.5, 10, size.width, 40);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveHeaderPainter oldDelegate) => false;
}