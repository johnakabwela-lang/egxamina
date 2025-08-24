import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

void main() {
  runApp(
    MaterialApp(
      home: const VideoScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    ),
  );
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool isPlaying = false;
  bool isMuted = false;
  bool isCameraOn = true;

  // Subjects data
  final List<Subject> subjects = [
    Subject(
      name: 'Mathematics',
      icon: Icons.calculate,
      color: const Color(0xFF2196F3),
      videos: [
        YouTubeVideo(
          'Algebra Basics',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Geometry Fundamentals',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Calculus Introduction',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Statistics Made Easy',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      ],
    ),
    Subject(
      name: 'Science',
      icon: Icons.science,
      color: const Color(0xFF4CAF50),
      videos: [
        YouTubeVideo('Physics Laws', 'https://youtube.com/watch?v=dQw4w9WgXcQ'),
        YouTubeVideo(
          'Chemistry Basics',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Biology Fundamentals',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Earth Sciences',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      ],
    ),
    Subject(
      name: 'History',
      icon: Icons.history_edu,
      color: const Color(0xFF9C27B0),
      videos: [
        YouTubeVideo(
          'World History Overview',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Ancient Civilizations',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Modern History',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'African History',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      ],
    ),
    Subject(
      name: 'English',
      icon: Icons.menu_book,
      color: const Color(0xFFFF9800),
      videos: [
        YouTubeVideo(
          'Grammar Basics',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Literature Analysis',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Creative Writing',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Reading Comprehension',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      ],
    ),
    Subject(
      name: 'Programming',
      icon: Icons.code,
      color: const Color(0xFF607D8B),
      videos: [
        YouTubeVideo(
          'Python for Beginners',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Web Development',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Mobile App Development',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Data Structures',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      ],
    ),
    Subject(
      name: 'Art & Design',
      icon: Icons.palette,
      color: const Color(0xFFE91E63),
      videos: [
        YouTubeVideo(
          'Drawing Fundamentals',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo(
          'Digital Art Basics',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        YouTubeVideo('Color Theory', 'https://youtube.com/watch?v=dQw4w9WgXcQ'),
        YouTubeVideo(
          'Design Principles',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start entrance animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with welcome message
              _buildHeader(),

              // Subjects list
              Expanded(child: _buildSubjectsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHelloText(),
                  const SizedBox(height: 10),
                  _buildSubtitle(),
                  const SizedBox(height: 20),
                  Text(
                    'Select a subject to explore videos',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelloText() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Text(
          'Hey!',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(_glowAnimation.value * 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween<double>(begin: 30.0, end: 0.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: 1 - (value / 30),
            child: Text(
              'Kabwela pano mwaice',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withAlpha((0.8 * 255).toInt()),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectsList() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.2,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                return _buildSubjectCard(subjects[index], index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectCard(Subject subject, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 200)),
      tween: Tween<double>(begin: 50.0, end: 0.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: GestureDetector(
            onTap: () => _navigateToVideos(subject),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: subject.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(subject.icon, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subject.videos.length} videos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToVideos(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideosScreen(subject: subject)),
    );
  }

  void _toggleVideo() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      _glowController.duration = const Duration(seconds: 1);
    } else {
      _glowController.duration = const Duration(seconds: 2);
    }
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
  }

  void _toggleCamera() {
    setState(() {
      isCameraOn = !isCameraOn;
    });
  }
}

class VideosScreen extends StatelessWidget {
  final Subject subject;

  const VideosScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              subject.color.withOpacity(0.8),
              subject.color.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Videos list
              Expanded(child: _buildVideosList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${subject.videos.length} educational videos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(subject.icon, color: Colors.white, size: 30),
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: subject.videos.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween<double>(begin: 50.0, end: 0.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: _buildVideoCard(subject.videos[index], index),
            );
          },
        );
      },
    );
  }

  Widget _buildVideoCard(YouTubeVideo video, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: subject.color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          video.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'Tap to watch on YouTube',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
        trailing: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
        onTap: () => _openYouTubeVideo(video.url),
      ),
    );
  }

  Future<void> _openYouTubeVideo(String url) async {
    final Uri videoUri = Uri.parse(url);

    try {
      if (await canLaunchUrl(videoUri)) {
        await launchUrl(videoUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      // You could show a snackbar or dialog here to inform the user
    }
  }
}

// Data models
class Subject {
  final String name;
  final IconData icon;
  final Color color;
  final List<YouTubeVideo> videos;

  Subject({
    required this.name,
    required this.icon,
    required this.color,
    required this.videos,
  });
}

class YouTubeVideo {
  final String title;
  final String url;

  YouTubeVideo(this.title, this.url);
}
