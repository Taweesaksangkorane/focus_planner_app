import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import '../../../features/tasks/data/task_repository.dart';

class CompletedPage extends StatefulWidget {
  final String taskTitle;
  final int focusTimeMinutes;
  final String taskId;

  const CompletedPage({
    Key? key,
    required this.taskTitle,
    required this.focusTimeMinutes,
    required this.taskId,
  }) : super(key: key);

  @override
  State<CompletedPage> createState() => _CompletedPageState();
}

class _CompletedPageState extends State<CompletedPage> {
  late ConfettiController _confettiController;
  late TaskRepository _repository;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize Repository with userId
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _repository = TaskRepositoryImpl(userId: user.uid);
    }
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    _saveCompletedTask();
  }

  Future<void> _saveCompletedTask() async {
    setState(() => _isSaving = true);
    try {
      final task = await _repository.getTaskById(widget.taskId);
      if (task != null) {
        await _repository.completeTask(task, widget.focusTimeMinutes);
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
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
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // ✅ Checkmark Circle with Cat
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '✓',
                              style: TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          child: Text(
                            '🎉',
                            style: TextStyle(fontSize: 60),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Completed!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.taskTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Focus Time: ${widget.focusTimeMinutes} minutes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  // ✅ Navigate back to Home
                                  Navigator.of(context).popUntil(
                                    (route) =>
                                        route.settings.name == '/' ||
                                        route.isFirst,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isSaving ? 'Saving...' : 'Back to Tasks',
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
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: 3.14159,
                  maxBlastForce: 36,
                  minBlastForce: 8,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).popUntil(
              (route) => route.isFirst,
            );
          } else if (index == 2) {
            Navigator.of(context).popUntil(
              (route) => route.isFirst,
            );
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