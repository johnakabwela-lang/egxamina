import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:math' as math;

void main() {
  runApp(
    MaterialApp(
      home: const VideoScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFF0F0F23),
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

  // Subjects data with actual video URLs for demonstration
  final List<Subject> subjects = [
    Subject(
      name: 'Mathematics',
      icon: Icons.calculate,
      color: const Color(0xFF6366F1), // Indigo
      videos: [
        YouTubeVideo(
          'Algebra Basics',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          'Learn the fundamentals of algebra',
        ),
        YouTubeVideo(
          'Geometry Fundamentals',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          'Master geometric concepts',
        ),
        YouTubeVideo(
          'Calculus Introduction',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          'Introduction to calculus concepts',
        ),
        YouTubeVideo(
          'Statistics Made Easy',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
          'Understanding statistics basics',
        ),
      ],
    ),
    Subject(
      name: 'Science',
      icon: Icons.science,
      color: const Color(0xFF10B981), // Emerald
      videos: [
        YouTubeVideo(
          'Physics Laws',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
          'Fundamental laws of physics',
        ),
        YouTubeVideo(
          'Chemistry Basics',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
          'Introduction to chemistry',
        ),
        YouTubeVideo(
          'Biology Fundamentals',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
          'Basic biological concepts',
        ),
        YouTubeVideo(
          'Earth Sciences',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
          'Understanding our planet',
        ),
      ],
    ),
    Subject(
      name: 'History',
      icon: Icons.history_edu,
      color: const Color(0xFF8B5CF6), // Violet
      videos: [
        YouTubeVideo(
          'World History Overview',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Subaru.mp4',
          'A comprehensive world history',
        ),
        YouTubeVideo(
          'Ancient Civilizations',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
          'Explore ancient civilizations',
        ),
        YouTubeVideo(
          'Modern History',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
          'Modern historical events',
        ),
        YouTubeVideo(
          'African History',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
          'Rich history of Africa',
        ),
      ],
    ),
    Subject(
      name: 'English',
      icon: Icons.menu_book,
      color: const Color(0xFFF59E0B), // Amber
      videos: [
        YouTubeVideo(
          'Grammar Basics',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          'Essential grammar rules',
        ),
        YouTubeVideo(
          'Literature Analysis',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          'Analyzing literary works',
        ),
        YouTubeVideo(
          'Creative Writing',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          'Develop writing skills',
        ),
        YouTubeVideo(
          'Reading Comprehension',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
          'Improve reading skills',
        ),
      ],
    ),
    Subject(
      name: 'Programming',
      icon: Icons.code,
      color: const Color(0xFF06B6D4), // Cyan
      videos: [
        YouTubeVideo(
          'Python for Beginners',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
          'Learn Python programming',
        ),
        YouTubeVideo(
          'Web Development',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
          'Build websites and web apps',
        ),
        YouTubeVideo(
          'Mobile App Development',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
          'Create mobile applications',
        ),
        YouTubeVideo(
          'Data Structures',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
          'Master data structures',
        ),
      ],
    ),
    Subject(
      name: 'Art & Design',
      icon: Icons.palette,
      color: const Color(0xFFEC4899), // Pink
      videos: [
        YouTubeVideo(
          'Drawing Fundamentals',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Subaru.mp4',
          'Learn to draw effectively',
        ),
        YouTubeVideo(
          'Digital Art Basics',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
          'Create digital artwork',
        ),
        YouTubeVideo(
          'Color Theory',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
          'Understanding colors',
        ),
        YouTubeVideo(
          'Design Principles',
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
          'Core design concepts',
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
            colors: [
              Color(0xFF0F0F23), // Dark navy
              Color(0xFF1E1E3F), // Dark purple
              Color(0xFF2D1B69), // Deep purple
            ],
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
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w300,
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(_glowAnimation.value * 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Text(
            'Hey! 👋',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
            ),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Text(
                'Kabwela pano mwaice',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
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
                childAspectRatio: 1.1,
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    subject.color.withOpacity(0.2),
                    subject.color.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: subject.color.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: subject.color.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          subject.color,
                          subject.color.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: subject.color.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(subject.icon, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: subject.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${subject.videos.length} videos',
                      style: TextStyle(
                        fontSize: 12,
                        color: subject.color,
                        fontWeight: FontWeight.w500,
                      ),
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
              const Color(0xFF0F0F23),
              subject.color.withOpacity(0.2),
              const Color(0xFF1E1E3F),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [subject.color.withOpacity(0.3), subject.color.withOpacity(0.1)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: subject.color.withOpacity(0.3)),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: subject.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${subject.videos.length} educational videos',
                    style: TextStyle(
                      fontSize: 12,
                      color: subject.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [subject.color, subject.color.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(subject.icon, color: Colors.white, size: 24),
          ),
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: subject.color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: subject.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [subject.color, subject.color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: subject.color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        video.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openVideoPlayer(video),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text('Watch', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: subject.color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadVideo(video),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text('Download', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: subject.color.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: subject.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _openYouTubeVideo(video.url),
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoPlayer(YouTubeVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          video: video,
          subject: subject,
        ),
      ),
    );
  }

  Future<void> _downloadVideo(YouTubeVideo video) async {
    // Request storage permission
    var status = await Permission.storage.request();
    if (status != PermissionStatus.granted) {
      return;
    }

    try {
      // Get the downloads directory
      Directory? downloadsDirectory = await getExternalStorageDirectory();
      if (downloadsDirectory == null) return;

      String filePath = '${downloadsDirectory.path}/${video.title}.mp4';

      // Create Dio instance for downloading
      Dio dio = Dio();

      // Show download progress (you might want to show a dialog or snackbar)
      print('Starting download: ${video.title}');

      await dio.download(
        video.url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      print('Download completed: $filePath');
      // Show success message
    } catch (e) {
      print('Download error: $e');
      // Show error message
    }
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
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final YouTubeVideo video;
  final Subject subject;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.subject,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isControlsVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    // Hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });

    if (_isControlsVisible) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isControlsVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Video player
              Center(
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
              ),

              // Controls overlay
              AnimatedOpacity(
                opacity: _isControlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    children: [
                      // Top bar
                      _buildTopBar(),

                      // Spacer
                      const Spacer(),

                      // Bottom controls
                      _buildBottomControls(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.subject.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.subject.color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.subject.icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: widget.subject.color,
              bufferedColor: Colors.white.withOpacity(0.3),
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 16),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous button
              IconButton(
                onPressed: () {
                  Duration currentPosition = _controller.value.position;
                  Duration targetPosition = currentPosition - const Duration(seconds: 10);
                  _controller.seekTo(targetPosition);
                },
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
              ),

              // Play/Pause button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.subject.color, widget.subject.color.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.subject.color.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),

              // Next button
              IconButton(
                onPressed: () {
                  Duration currentPosition = _controller.value.position;
                  Duration targetPosition = currentPosition + const Duration(seconds: 10);
                  _controller.seekTo(targetPosition);
                },
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 30),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Time and additional controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_controller.value.position),
                style: const TextStyle(color: Colors.white),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _controller.setVolume(_controller.value.volume == 0 ? 1 : 0);
                      });
                    },
                    icon: Icon(
                      _controller.value.volume == 0 ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Toggle fullscreen (you might want to implement proper fullscreen)
                    },
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                  ),
                ],
              ),
              Text(
                _formatDuration(_controller.value.duration),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
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
  final String description;

  YouTubeVideo(this.title, this.url, this.description);
}
