import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
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
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: const Color.fromRGBO(28, 28, 30, 1),
        fontFamily: '.SF UI Text',
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
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;

  // Subjects data with test URL
  final List<Subject> subjects = [
    Subject(
      name: 'Mathematics',
      icon: CupertinoIcons.number,
      color: const Color.fromRGBO(52, 120, 246, 1), // iOS Blue
      videos: [
        YouTubeVideo(
          'Algebra Basics',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Learn the fundamentals of algebra',
          VideoQuality.hd720,
        ),
        YouTubeVideo(
          'Geometry Fundamentals',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Master geometric concepts',
          VideoQuality.hd1080,
        ),
        YouTubeVideo(
          'Calculus Introduction',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Introduction to calculus concepts',
          VideoQuality.hd720,
        ),
      ],
    ),
    Subject(
      name: 'Science',
      icon: CupertinoIcons.lab_flask,
      color: const Color.fromRGBO(52, 199, 89, 1), // iOS Green
      videos: [
        YouTubeVideo(
          'Physics Laws',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Fundamental laws of physics',
          VideoQuality.hd1080,
        ),
        YouTubeVideo(
          'Chemistry Basics',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Introduction to chemistry',
          VideoQuality.hd720,
        ),
      ],
    ),
    Subject(
      name: 'History',
      icon: CupertinoIcons.book,
      color: const Color.fromRGBO(175, 82, 222, 1), // iOS Purple
      videos: [
        YouTubeVideo(
          'World History Overview',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'A comprehensive world history',
          VideoQuality.hd1080,
        ),
        YouTubeVideo(
          'Ancient Civilizations',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Explore ancient civilizations',
          VideoQuality.hd720,
        ),
      ],
    ),
    Subject(
      name: 'English',
      icon: CupertinoIcons.textformat,
      color: const Color.fromRGBO(255, 159, 10, 1), // iOS Orange
      videos: [
        YouTubeVideo(
          'Grammar Basics',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Essential grammar rules',
          VideoQuality.hd720,
        ),
        YouTubeVideo(
          'Literature Analysis',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Analyzing literary works',
          VideoQuality.hd1080,
        ),
      ],
    ),
    Subject(
      name: 'Programming',
      icon: CupertinoIcons.chevron_left_slash_chevron_right,
      color: const Color.fromRGBO(90, 200, 250, 1), // iOS Light Blue
      videos: [
        YouTubeVideo(
          'Python for Beginners',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Learn Python programming',
          VideoQuality.hd1080,
        ),
        YouTubeVideo(
          'Web Development',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Build websites and web apps',
          VideoQuality.hd720,
        ),
      ],
    ),
    Subject(
      name: 'Art & Design',
      icon: CupertinoIcons.paintbrush,
      color: const Color.fromRGBO(255, 45, 85, 1), // iOS Pink
      videos: [
        YouTubeVideo(
          'Drawing Fundamentals',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Learn to draw effectively',
          VideoQuality.hd720,
        ),
        YouTubeVideo(
          'Digital Art Basics',
          'https://youtu.be/SeCmnHhCP74?si=TBCTNjouhrnQ_ji5',
          'Create digital artwork',
          VideoQuality.hd1080,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _floatingAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0.95),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color.fromRGBO(25, 25, 40, 0.8),
              Color.fromRGBO(0, 0, 0, 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
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
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Column(
                children: [
                  _buildHelloText(),
                  const SizedBox(height: 12),
                  _buildSubtitle(),
                  const SizedBox(height: 20),
                  Text(
                    'Select a subject to explore videos',
                    style: TextStyle(
                      fontSize: 17,
                      color: const Color.fromRGBO(235, 235, 245, 0.6),
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.24,
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
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.1),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(52, 120, 246, 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              'Hey! 👋',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [
                      Color.fromRGBO(52, 120, 246, 1),
                      Color.fromRGBO(90, 200, 250, 1),
                      Color.fromRGBO(175, 82, 222, 1)
                    ],
                  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                letterSpacing: -1.0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 20.0, end: 0.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: 1 - (value / 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.12),
                  width: 0.5,
                ),
              ),
              child: const Text(
                'Kabwela pano mwaice',
                style: TextStyle(
                  fontSize: 18,
                  color: Color.fromRGBO(235, 235, 245, 0.8),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.24,
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
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
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
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween<double>(begin: 30.0, end: 0.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: GestureDetector(
            onTap: () => _navigateToVideos(subject),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: subject.color.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: subject.color.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        subject.color.withOpacity(0.08),
                        subject.color.withOpacity(0.03),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: subject.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: subject.color.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          subject.icon,
                          size: 28,
                          color: subject.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(235, 235, 245, 0.9),
                          letterSpacing: -0.24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: subject.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${subject.videos.length} videos',
                          style: TextStyle(
                            fontSize: 12,
                            color: subject.color,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.08,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
      CupertinoPageRoute(builder: (context) => VideosScreen(subject: subject)),
    );
  }
}

class VideosScreen extends StatefulWidget {
  final Subject subject;

  const VideosScreen({super.key, required this.subject});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  Map<String, double> downloadProgress = {};
  Map<String, bool> downloadingStatus = {};

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0.95),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              widget.subject.color.withOpacity(0.1),
              const Color.fromRGBO(0, 0, 0, 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildVideosList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.12),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Color.fromRGBO(235, 235, 245, 0.9),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subject.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color.fromRGBO(235, 235, 245, 0.9),
                    letterSpacing: -0.6,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.subject.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.subject.videos.length} educational videos',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.subject.color,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.08,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.subject.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.subject.icon,
              color: widget.subject.color,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: widget.subject.videos.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 80)),
          tween: Tween<double>(begin: 30.0, end: 0.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: _buildVideoCard(widget.subject.videos[index], index, context),
            );
          },
        );
      },
    );
  }

  Widget _buildVideoCard(YouTubeVideo video, int index, BuildContext context) {
    bool isDownloading = downloadingStatus[video.title] ?? false;
    double progress = downloadProgress[video.title] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.subject.color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.subject.color.withOpacity(0.05),
                const Color.fromRGBO(255, 255, 255, 0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: widget.subject.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.subject.color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.play_circle_fill,
                        color: widget.subject.color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color.fromRGBO(235, 235, 245, 0.9),
                              letterSpacing: -0.24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color.fromRGBO(235, 235, 245, 0.6),
                              letterSpacing: -0.16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildQualityBadge(video.quality),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (isDownloading) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.1),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.subject.color,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloading... ${progress.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: widget.subject.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.08,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: CupertinoIcons.play_fill,
                        label: 'Watch on YouTube',
                        isPrimary: true,
                        onTap: () => _openYouTubeVideo(video.url),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: isDownloading 
                            ? CupertinoIcons.hourglass 
                            : CupertinoIcons.cloud_download,
                        label: isDownloading ? 'Downloading...' : 'Download',
                        isPrimary: false,
                        isDisabled: isDownloading,
                        onTap: isDownloading ? null : () => _downloadVideo(video),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityBadge(VideoQuality quality) {
    String qualityText = quality == VideoQuality.hd1080 ? 'HD 1080p' : 'HD 720p';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.subject.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        qualityText,
        style: TextStyle(
          fontSize: 11,
          color: widget.subject.color,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.06,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isDisabled = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isPrimary
              ? widget.subject.color.withOpacity(isDisabled ? 0.1 : 0.15)
              : const Color.fromRGBO(255, 255, 255, isDisabled ? 0.03 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? widget.subject.color.withOpacity(isDisabled ? 0.1 : 0.2)
                : const Color.fromRGBO(255, 255, 255, isDisabled ? 0.05 : 0.12),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary
                  ? widget.subject.color.withOpacity(isDisabled ? 0.5 : 1.0)
                  : Color.fromRGBO(235, 235, 245, isDisabled ? 0.3 : 0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isPrimary
                    ? widget.subject.color.withOpacity(isDisabled ? 0.5 : 1.0)
                    : Color.fromRGBO(235, 235, 245, isDisabled ? 0.3 : 0.8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadVideo(YouTubeVideo video) async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      bool permissionGranted = statuses[Permission.storage]?.isGranted == true ||
          statuses[Permission.manageExternalStorage]?.isGranted == true;

      if (!permissionGranted) {
        _showMessage('Storage permission denied');
        return;
      }

      setState(() {
        downloadingStatus[video.title] = true;
        downloadProgress[video.title] = 0.0;
      });

      Directory? directory;
      
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        _showMessage('Could not access storage directory');
        setState(() {
          downloadingStatus[video.title] = false;
        });
        return;
      }

      String cleanFileName = video.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      String filePath = '${directory.path}/${cleanFileName}.mp4';

      Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      _showMessage('Starting download: ${video.title}');

      // Note: This is a placeholder URL for demonstration
      // In a real app, you'd need to extract the actual video file URL from YouTube
      String demoVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

      await dio.download(
        demoVideoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total * 100);
            setState(() {
              downloadProgress[video.title] = progress;
            });
          }
        },
      );

      setState(() {
        downloadingStatus[video.title] = false;
        downloadProgress[video.title] = 100.0;
      });

      _showMessage('Download completed: $filePath');

    } catch (e) {
      setState(() {
        downloadingStatus[video.title] = false;
        downloadProgress[video.title] = 0.0;
      });
      _showMessage('Download error: $e');
    }
  }

  void _showMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromRGBO(235, 235, 245, 0.9),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: widget.subject.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openYouTubeVideo(String url) async {
    final Uri videoUri = Uri.parse(url);

    try {
      if (await canLaunchUrl(videoUri)) {
        await launchUrl(videoUri, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Could not launch $url');
      }
    } catch (e) {
      _showMessage('Error launching URL: $e');
    }
  }
}

// Data models
enum VideoQuality { hd720, hd1080 }

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
  final VideoQuality quality;

  YouTubeVideo(this.title, this.url, this.description, this.quality);
}
