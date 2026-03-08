import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/task_model.dart';
import '../data/task_repository.dart';
import 'add_task_page.dart';
import 'widgets/task_card.dart';
import 'task_detail_page.dart';
import 'profile_page.dart';
import '../../settings/presentation/settings_page.dart';

class HomeTaskPage extends StatefulWidget {
  const HomeTaskPage({Key? key}) : super(key: key);

  @override
  State<HomeTaskPage> createState() => _HomeTaskPageState();
}

class _HomeTaskPageState extends State<HomeTaskPage> {
  int _selectedIndex = 1;
  late TaskRepository _taskRepository;
  List<TaskModel> tasks = [];
  bool isLoading = false;
  String _selectedFilter = 'All Task';

  final categories = ['All Task', 'Work', 'Reading', 'Personal', 'Health'];

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  // ✅ Initialize Repository dengan userId
  Future<void> _initializeRepository() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _taskRepository = TaskRepositoryImpl(userId: user.uid);
        await _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    try {
      final loadedTasks = await _taskRepository.getAllActiveTasks();
      setState(() {
        tasks = loadedTasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  Future<void> _filterTasks(String category) async {
    setState(() {
      _selectedFilter = category;
      isLoading = true;
    });

    try {
      List<TaskModel> filtered;
      if (category == 'All Task') {
        filtered = await _taskRepository.getAllActiveTasks();
      } else {
        filtered = await _taskRepository.getTasksByCategory(category);
      }
      setState(() {
        tasks = filtered;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error filtering tasks: $e')),
        );
      }
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return DateFormat('dd/MM/yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const SizedBox(),
          _buildHomeView(isDarkMode),
          const ProfilePage(),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTaskPage(),
                  ),
                ).then((newTask) async {
                  if (newTask != null && mounted) {
                    try {
                      // ✅ เพิ่ม task ลง Firebase
                      await _taskRepository.addTask(newTask);

                      // ✅ Refresh list ทันที
                      await _loadTasks();

                      // ✅ แสดง success message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task created successfully!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding task: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
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

  Widget _buildHomeView(bool isDarkMode) {
    return Container(
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(isDarkMode),
            const SizedBox(height: 20),
            _buildFilterButtons(isDarkMode),
            const SizedBox(height: 20),
            _buildTasksList(isDarkMode),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task List',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? Colors.white
                  : const Color.fromARGB(255, 252, 251, 251),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Today, ${_getTodayDate()}',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : const Color.fromARGB(179, 247, 246, 245),
            ),
          ),
          const SizedBox(height: 20),
          _buildDecorationSection(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildDecorationSection(bool isDarkMode) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color.fromARGB(255, 41, 28, 114).withOpacity(0.6)
            : const Color.fromARGB(255, 209, 207, 207),
        borderRadius: BorderRadius.circular(24),
        border: isDarkMode
            ? Border.all(
                color: Colors.white.withOpacity(0.2),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 50),
              painter: WavePainter(isDarkMode: isDarkMode),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 10,
            child: Text(
              '🐱',
              style: TextStyle(fontSize: 85),
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildFilterButtons(bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedFilter == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _filterTasks(category),
              backgroundColor: Colors.transparent,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isDarkMode
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.shade600,
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isDarkMode
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTasksList(bool isDarkMode) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No tasks found',
            style: TextStyle(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.6)
                  : Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          tasks.length,
          (index) {
            final task = tasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCardNew(
                task: task,
                onTaskUpdated: _loadTasks,
              ),
            );
          },
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final bool isDarkMode;

  WavePainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode
          ? const Color.fromARGB(255, 41, 28, 114)
          : const Color(0xFF221B2D)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 20);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 20);
    path.quadraticBezierTo(size.width * 0.75, 40, size.width, 20);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.2, 15), 4, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.4, 25), 6, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.6, 10), 5, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.8, 20), 4, circlePaint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => false;
}