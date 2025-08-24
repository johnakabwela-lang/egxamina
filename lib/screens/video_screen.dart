import 'package:flutter/material.dart';
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
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
      ),
    ),
  );
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  // Subjects data with test URL
  final List<Subject> subjects = [
    Subject(
      name: 'Mathematics',
      icon: Icons.calculate_outlined,
      color: Colors.blue,
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
      icon: Icons.science_outlined,
      color: Colors.green,
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
      icon: Icons.history_edu_outlined,
      color: Colors.purple,
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
      icon: Icons.menu_book_outlined,
      color: Colors.orange,
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
      icon: Icons.code_outlined,
      color: Colors.indigo,
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
      icon: Icons.palette_outlined,
      color: Colors.pink,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildSubjectsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Hub',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a subject to explore videos',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return _buildSubjectCard(subjects[index]);
        },
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return Card(
      elevation: 2,
      color: Colors.white.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToVideos(subject),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                subject.color.withOpacity(0.1),
                Colors.white.withOpacity(0.5),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: subject.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    subject.icon,
                    size: 32,
                    color: subject.color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    '${subject.videos.length} videos',
                    style: TextStyle(
                      fontSize: 12,
                      color: subject.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: subject.color.withOpacity(0.1),
                  side: BorderSide.none,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToVideos(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideosScreen(subject: subject)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.subject.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Chip(
              label: Text(
                '${widget.subject.videos.length} educational videos',
                style: TextStyle(
                  color: widget.subject.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: widget.subject.color.withOpacity(0.1),
              side: BorderSide.none,
            ),
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
        return _buildVideoCard(widget.subject.videos[index], index);
      },
    );
  }

  Widget _buildVideoCard(YouTubeVideo video, int index) {
    bool isDownloading = downloadingStatus[video.title] ?? false;
    double progress = downloadProgress[video.title] ?? 0.0;

    return Card(
      elevation: 2,
      color: Colors.white.withOpacity(0.7),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.subject.color.withOpacity(0.05),
              Colors.white.withOpacity(0.5),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    ),
                    child: Icon(
                      Icons.play_circle_filled,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
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
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                  color: widget.subject.color,
                ),
                const SizedBox(height: 8),
                Text(
                  'Downloading... ${progress.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: widget.subject.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openYouTubeVideo(video.url),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Watch on YouTube'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.subject.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isDownloading ? null : () => _downloadVideo(video),
                      icon: Icon(
                        isDownloading ? Icons.hourglass_empty : Icons.download,
                        size: 18,
                      ),
                      label: Text(isDownloading ? 'Downloading...' : 'Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.subject.color,
                        side: BorderSide(color: widget.subject.color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityBadge(VideoQuality quality) {
    String qualityText = quality == VideoQuality.hd1080 ? 'HD 1080p' : 'HD 720p';
    return Chip(
      label: Text(
        qualityText,
        style: TextStyle(
          fontSize: 11,
          color: widget.subject.color,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: widget.subject.color.withOpacity(0.1),
      side: BorderSide.none,
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
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
