import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:sachdientudemo/services/ai_service.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/contact_page.dart';
import 'pages/admin_page.dart';
import 'utils/app_colors.dart';
import 'utils/responsive_utils.dart';
import 'widgets/floating_particles.dart';
import 'services/ai_server_manager.dart';
import 'utils/server_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Handle Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
  };
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Khởi động Backend Server (chỉ trên desktop platforms)
  try {
    if (!kIsWeb) {
      print('🤖 Auto-starting Backend Server from main.dart...');
      print('📁 Working directory: ${Directory.current.path}');

      // Force start backend từ main.dart
      final backendStarted = await _startBackendFromMain();
      if (backendStarted) {
        print('✅ Backend started successfully from main.dart');
      } else {
        print('⚠️ Backend auto-start failed, trying ServerManager...');
        final serverStarted = await ServerManager.startServers();
        if (serverStarted) {
          print('✅ Backend started via ServerManager');
        } else {
          print('⚠️ Backend not available - check deployment config');
          print('💡 For local dev: python backend/app.py');
        }
      }
    } else {
      print('🌐 Web platform - Backend should be hosted separately');
      print('💡 Using backend URL: ${AIService.baseUrl}');
    }
  } catch (e) {
    print('❌ Backend initialization error: $e');
  }
  
  runApp(const EBookMobileApp());
}

/// Khởi động backend server trực tiếp từ main.dart
Future<bool> _startBackendFromMain() async {
  try {
    // Chỉ start trên desktop platforms
    if (kIsWeb) {
      print('🌐 Web platform - Backend should be hosted separately');
      return false;
    }

    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      print('📱 Mobile platform - Backend should be hosted separately');
      return false;
    }

    print('💻 Desktop platform detected - Starting local backend...');

    // Tìm backend/app.py
    final backendPath = 'backend/app.py';
    final backendFile = File(backendPath);

    if (!await backendFile.exists()) {
      print('❌ Backend file not found: $backendPath');
      return false;
    }

    print('📄 Found backend at: ${backendFile.absolute.path}');

    // Thử các Python commands
    final pythonCommands = ['python', 'python3', 'py'];

    for (final pythonCmd in pythonCommands) {
      try {
        print('🐍 Trying to start backend with: $pythonCmd');

        final process = await Process.start(
          pythonCmd,
          [backendPath],
          workingDirectory: Directory.current.path,
        );

        // Listen to output
        process.stdout.transform(SystemEncoding().decoder).listen((data) {
          print('Backend: $data');
        });

        process.stderr.transform(SystemEncoding().decoder).listen((data) {
          print('Backend Error: $data');
        });

        // Wait for backend to start
        await Future.delayed(const Duration(seconds: 8));

        // Test health check
        try {
          final response = await http.get(Uri.parse('http://localhost:5001/health'));
          if (response.statusCode == 200) {
            print('✅ Backend health check passed with $pythonCmd');
            return true;
          }
        } catch (e) {
          print('❌ Backend health check failed: $e');
        }

        // Kill process if health check failed
        process.kill();

      } catch (e) {
        print('❌ Failed to start with $pythonCmd: $e');
      }
    }

    print('❌ Failed to start backend with any Python command');
    return false;

  } catch (e) {
    print('❌ Error in _startBackendFromMain: $e');
    return false;
  }
}

class EBookMobileApp extends StatelessWidget {
  const EBookMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sách Điện Tử Hóa Học',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          titleLarge: TextStyle(color: AppColors.textPrimary),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        platform: TargetPlatform.fuchsia,
      ),
      home: const MainLayout(),
      routes: {
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HomePage(),
    const ContactPage(),
    const ContactPage(), // Placeholder cho Thư Viện
    const ContactPage(), // Placeholder cho Đã Lưu
    const ContactPage(), // Placeholder cho Cá Nhân
    const ContactPage(), // Placeholder cho Cài Đặt
    const ContactPage(), // Placeholder cho Trợ Giúp
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(Icons.home, Icons.home_outlined, 'Trang Chủ'),
    NavigationItem(Icons.library_books, Icons.library_books_outlined, 'Thư Viện'),
    NavigationItem(Icons.bookmark, Icons.bookmark_outline, 'Đã Lưu'),
    NavigationItem(Icons.person, Icons.person_outline, 'Cá Nhân'),
  ];

  final List<NavigationItem> _settingsItems = [
    NavigationItem(Icons.settings, Icons.settings_outlined, 'Cài Đặt'),
    NavigationItem(Icons.help, Icons.help_outline, 'Trợ Giúp'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0a0e27),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0a0e27),
                  Color(0xFF1a1f3a),
                  Color(0xFF2d1b69),
                ],
              ),
            ),
          ),
          // Floating particles animation
          const FloatingParticles(),
          // Main content
          SafeArea(
            child: ResponsiveUtils.isMobile(context)
                ? _buildMobileLayout()
                : _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildMobileAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_stories,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Reading No Limit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1f3a).withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF667eea),
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang Chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Thư Viện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Đã Lưu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá Nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildSideNavigation(),
        Expanded(
          child: Column(
            children: [
              _buildDesktopHeader(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideNavigation() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Section
          _buildLogoSection(),
          const SizedBox(height: 40),
          // Main Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionTitle('ĐIỀU HƯỚNG'),
                const SizedBox(height: 12),
                ..._navigationItems.asMap().entries.map((entry) {
                  return _buildNavItem(
                    entry.value.activeIcon,
                    entry.value.inactiveIcon,
                    entry.value.title,
                    entry.key,
                  );
                }),
                const SizedBox(height: 32),
                const Divider(color: Colors.white24, thickness: 1),
                const SizedBox(height: 24),
                _buildSectionTitle('CÀI ĐẶT'),
                const SizedBox(height: 12),
                ..._settingsItems.asMap().entries.map((entry) {
                  return _buildNavItem(
                    entry.value.activeIcon,
                    entry.value.inactiveIcon,
                    entry.value.title,
                    entry.key + 4, // Offset by main nav items
                  );
                }),
              ],
            ),
          ),
          // User Profile Section
          _buildUserProfile(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reading No Limit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Nền tảng sách điện tử',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, String title, int index) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF667eea).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                  ? Border.all(color: const Color(0xFF667eea).withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected 
                      ? const Color(0xFF667eea) 
                      : Colors.white.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF667eea) 
                          : Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF667eea),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Người dùng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'user@example.com',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_vert,
            color: Colors.white.withOpacity(0.5),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Khám Phá Thế Giới Hóa Học',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Search button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.search,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Notifications
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {},
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String title;

  NavigationItem(this.activeIcon, this.inactiveIcon, this.title);
}
