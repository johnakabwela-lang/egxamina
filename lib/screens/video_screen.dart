import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(
    MaterialApp(
      home: const VideoScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF58CC02),
          brightness: Brightness.light,
        ),
      ),
    ),
  );
}

// Custom AppBar Widget for consistency
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Custom Header Card Widget for consistency
class CustomHeaderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<Color>? gradientColors;

  const CustomHeaderCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors ?? [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  // Subjects data with different demo videos for each URL
  final List<Subject> subjects = [
    Subject(
      name: 'Mathematics',
      icon: Icons.calculate_outlined,
      color: const Color(0xFF1CB0F6),
      videos: [
        YouTubeVideo(
          'Algebra Basics',
          'https://youtu.be/WUvTyaaNkzM',
          'Learn the fundamentals of algebra',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        ),
        YouTubeVideo(
          'Geometry Fundamentals',
          'https://youtu.be/mhd9FXYdf4s',
          'Master geometric concepts',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        ),
        YouTubeVideo(
          'Calculus Introduction',
          'https://youtu.be/EKvHQc3QEow',
          'Introduction to calculus concepts',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        ),
      ],
    ),
    Subject(
      name: 'Science',
      icon: Icons.science_outlined,
      color: const Color(0xFF58CC02),
      videos: [
        YouTubeVideo(
          'Physics Laws',
          'https://youtu.be/ZM8ECpBuQYE',
          'Fundamental laws of physics',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        ),
        YouTubeVideo(
          'Chemistry Basics',
          'https://youtu.be/FSyAehMdpyI',
          'Introduction to chemistry',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
        ),
      ],
    ),
    Subject(
      name: 'History',
      icon: Icons.history_edu_outlined,
      color: const Color(0xFF7B68EE),
      videos: [
        YouTubeVideo(
          'World History Overview',
          'https://youtu.be/xuCn8ux2gbs',
          'A comprehensive world history',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
        ),
        YouTubeVideo(
          'Ancient Civilizations',
          'https://youtu.be/Z_AYXcDOWVg',
          'Explore ancient civilizations',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        ),
      ],
    ),
    Subject(
      name: 'English',
      icon: Icons.menu_book_outlined,
      color: const Color(0xFFFF9600),
      videos: [
        YouTubeVideo(
          'Grammar Basics',
          'https://youtu.be/VQmPQflsWV0',
          'Essential grammar rules',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
        ),
        YouTubeVideo(
          'Literature Analysis',
          'https://youtu.be/msVS9qmOEL0',
          'Analyzing literary works',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
        ),
      ],
    ),
    Subject(
      name: 'Programming',
      icon: Icons.code_outlined,
      color: const Color(0xFFDA70D6),
      videos: [
        YouTubeVideo(
          'Python for Beginners',
          'https://youtu.be/rfscVS0vtbw',
          'Learn Python programming',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
        ),
        YouTubeVideo(
          'Web Development',
          'https://youtu.be/UB1O30fR-EE',
          'Build websites and web apps',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
        ),
      ],
    ),
    Subject(
      name: 'Art & Design',
      icon: Icons.palette_outlined,
      color: const Color(0xFFFF4B4B),
      videos: [
        YouTubeVideo(
          'Drawing Fundamentals',
          'https://youtu.be/pMC0Cx3Uk84',
          'Learn to draw effectively',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
        YouTubeVideo(
          'Digital Art Basics',
          'https://youtu.be/Nj_O2kqx_fI',
          'Create digital artwork',
          VideoQuality.hd1080,
          'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: CustomAppBar(
        title: 'Learning Hub',
        automaticallyImplyLeading: false,
        actions: [
          DuolingoStyleCard(
            onTap: _showPasteUrlDialog,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF58CC02).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.add_link,
                color: Color(0xFF58CC02),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Using the custom header card
            CustomHeaderCard(
              icon: Icons.video_library,
              title: 'Educational Videos',
              subtitle: 'Explore subjects and learn at your own pace',
              color: const Color(0xFF58CC02),
              gradientColors: const [Color(0xFF58CC02), Color(0xFF46A302)],
            ),
            const SizedBox(height: 12),
            _buildSubjectsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return _buildAnimatedSubjectCard(subjects[index], index);
        },
      ),
    );
  }

  Widget _buildAnimatedSubjectCard(Subject subject, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(opacity: value, child: _buildSubjectCard(subject)),
        );
      },
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return DuolingoStyleCard(
      onTap: () => _navigateToVideos(subject),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: subject.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: subject.color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(subject.icon, size: 34, color: subject.color),
              ),
              const SizedBox(height: 16),
              Text(
                subject.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: subject.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${subject.videos.length} videos',
                  style: TextStyle(
                    fontSize: 12,
                    color: subject.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasteUrlDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_link,
                  color: Color(0xFF58CC02),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Add Video URL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'Paste YouTube URL here...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.link, color: Color(0xFF58CC02)),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will download a demo video for demonstration',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DuolingoStyleCard(
              onTap: () {
                String url = urlController.text.trim();
                Navigator.of(context).pop();
                if (url.isNotEmpty) {
                  _navigateToUrlDownloader(url);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF58CC02), Color(0xFF46A302)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Download',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
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

  void _navigateToUrlDownloader(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UrlDownloaderScreen(url: url)),
    );
  }
}

// Enhanced URL Downloader Screen with consistent styling
class UrlDownloaderScreen extends StatefulWidget {
  final String url;

  const UrlDownloaderScreen({super.key, required this.url});

  @override
  State<UrlDownloaderScreen> createState() => _UrlDownloaderScreenState();
}

class _UrlDownloaderScreenState extends State<UrlDownloaderScreen> {
  String? videoTitle;
  String? thumbnailUrl;
  bool isLoading = true;
  double downloadProgress = 0.0;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _extractVideoInfo();
  }

  void _extractVideoInfo() {
    String videoId = _extractVideoId(widget.url);

    if (videoId.isNotEmpty) {
      setState(() {
        videoTitle = _getTitleFromUrl(widget.url);
        thumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        isLoading = false;
      });
    } else {
      setState(() {
        videoTitle = 'Custom Video from URL';
        thumbnailUrl = null;
        isLoading = false;
      });
    }
  }

  String _getTitleFromUrl(String url) {
    String videoId = _extractVideoId(url);
    if (videoId.isNotEmpty) {
      return 'YouTube Video ($videoId)';
    }
    return 'Video from URL';
  }

  String _extractVideoId(String url) {
    RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
      multiLine: false,
    );

    Match? match = regExp.firstMatch(url);
    return match?.group(1) ?? '';
  }

  String _getDownloadUrlForPastedUrl(String originalUrl) {
    String videoId = _extractVideoId(originalUrl);

    Map<String, String> demoVideoMap = {
      'dQw4w9WgXcQ':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'kJQP7kiw5Fk':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'fJ9rUzIMcZQ':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      'default':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    };

    return demoVideoMap[videoId] ?? demoVideoMap['default']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: const CustomAppBar(title: 'Download Video'),
      body: Column(
        children: [
          // Custom header card for URL download
          CustomHeaderCard(
            icon: Icons.download_for_offline,
            title: 'Video Download',
            subtitle: 'Download videos for offline viewing',
            color: const Color(0xFF1CB0F6),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF58CC02),
                      ),
                    )
                  : _buildVideoCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (thumbnailUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey[300]!,
                                      Colors.grey[200]!,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.video_library,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    Text(
                      videoTitle ?? 'Unknown Video',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.url,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),

                    if (isDownloading) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF58CC02).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: downloadProgress / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF58CC02),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Downloading... ${downloadProgress.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF58CC02),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: DuolingoStyleCard(
                            onTap: () => _openYouTubeVideo(widget.url),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1CB0F6),
                                    Color(0xFF0E8CC7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Watch on YouTube',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DuolingoStyleCard(
                            onTap: isDownloading ? () {} : _downloadVideo,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isDownloading
                                    ? Colors.grey[300]
                                    : Colors.white,
                                border: Border.all(
                                  color: isDownloading
                                      ? Colors.grey[400]!
                                      : const Color(0xFF58CC02),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isDownloading
                                        ? Icons.hourglass_empty
                                        : Icons.download,
                                    color: isDownloading
                                        ? Colors.grey[600]
                                        : const Color(0xFF58CC02),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isDownloading
                                        ? 'Downloading...'
                                        : 'Download',
                                    style: TextStyle(
                                      color: isDownloading
                                          ? Colors.grey[600]
                                          : const Color(0xFF58CC02),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      },
    );
  }

  Future<void> _downloadVideo() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      bool permissionGranted =
          statuses[Permission.storage]?.isGranted == true ||
          statuses[Permission.manageExternalStorage]?.isGranted == true;

      if (!permissionGranted) {
        _showMessage('Storage permission denied by user');
        return;
      }

      setState(() {
        isDownloading = true;
        downloadProgress = 0.0;
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
          isDownloading = false;
        });
        return;
      }

      String videoId = _extractVideoId(widget.url);
      String fileName = videoId.isNotEmpty
          ? 'video_$videoId.mp4'
          : 'custom_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      String filePath = '${directory.path}/$fileName';

      Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      _showMessage('Starting download...');

      String downloadUrl = _getDownloadUrlForPastedUrl(widget.url);

      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total * 100);
            setState(() {
              downloadProgress = progress;
            });
          }
        },
      );

      setState(() {
        isDownloading = false;
        downloadProgress = 100.0;
      });

      _showMessage('Download completed: $filePath');
    } catch (e) {
      setState(() {
        isDownloading = false;
        downloadProgress = 0.0;
      });
      _showMessage('Download error: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF58CC02),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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

// Enhanced Videos Screen with consistent styling
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: CustomAppBar(
        title: widget.subject.name,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.subject.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.subject.icon,
              color: widget.subject.color,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom header card for subject
          CustomHeaderCard(
            icon: widget.subject.icon,
            title: widget.subject.name,
            subtitle: '${widget.subject.videos.length} educational videos',
            color: widget.subject.color,
          ),
          Expanded(child: _buildVideosList()),
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.subject.videos.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildVideoCard(widget.subject.videos[index], index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideoCard(YouTubeVideo video, int index) {
    bool isDownloading = downloadingStatus[video.title] ?? false;
    double progress = downloadProgress[video.title] ?? 0.0;
    String videoId = _extractVideoId(video.url);
    String thumbnailUrl =
        'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 100,
                    height: 75,
                    child: Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.subject.color.withOpacity(0.2),
                                widget.subject.color.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.play_circle_filled,
                            color: widget.subject.color,
                            size: 40,
                          ),
                        );
                      },
                    ),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        video.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildQualityBadge(video.quality),
                    ],
                  ),
                ),
              ],
            ),

            if (isDownloading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.subject.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.subject.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Downloading... ${progress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.subject.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DuolingoStyleCard(
                    onTap: () => _openYouTubeVideo(video.url),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.subject.color,
                            widget.subject.color.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Watch',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DuolingoStyleCard(
                    onTap: isDownloading ? () {} : () => _downloadVideo(video),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDownloading ? Colors.grey[300] : Colors.white,
                        border: Border.all(
                          color: isDownloading
                              ? Colors.grey[400]!
                              : widget.subject.color,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDownloading
                                ? Icons.hourglass_empty
                                : Icons.download,
                            color: isDownloading
                                ? Colors.grey[600]
                                : widget.subject.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isDownloading ? 'Downloading...' : 'Download',
                            style: TextStyle(
                              color: isDownloading
                                  ? Colors.grey[600]
                                  : widget.subject.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _extractVideoId(String url) {
    RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
      multiLine: false,
    );

    Match? match = regExp.firstMatch(url);
    return match?.group(1) ?? '';
  }

  Widget _buildQualityBadge(VideoQuality quality) {
    String qualityText = quality == VideoQuality.hd1080
        ? 'HD 1080p'
        : 'HD 720p';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.subject.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        qualityText,
        style: TextStyle(
          fontSize: 12,
          color: widget.subject.color,
          fontWeight: FontWeight.w600,
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

      bool permissionGranted =
          statuses[Permission.storage]?.isGranted == true ||
          statuses[Permission.manageExternalStorage]?.isGranted == true;

      if (!permissionGranted) {
        _showMessage('Storage permission denied by user');
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

      String cleanFileName = video.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      String filePath = '${directory.path}/$cleanFileName.mp4';

      Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      _showMessage('Starting download: ${video.title}');

      String downloadUrl = video.downloadUrl;

      await dio.download(
        downloadUrl,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: widget.subject.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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

// Duolingo-style pressable card widget
class DuolingoStyleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration animationDuration;

  const DuolingoStyleCard({
    super.key,
    required this.child,
    required this.onTap,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<DuolingoStyleCard> createState() => _DuolingoStyleCardState();
}

class _DuolingoStyleCardState extends State<DuolingoStyleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              transform: Matrix4.identity()
                ..translate(0.0, 3.0 * _animationController.value),
              child: Opacity(
                opacity: 0.85 + (0.15 * (1 - _animationController.value)),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
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
  final String downloadUrl;

  YouTubeVideo(
    this.title,
    this.url,
    this.description,
    this.quality,
    this.downloadUrl,
  );
}
