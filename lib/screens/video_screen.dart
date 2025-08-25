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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
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
  // Subjects data with different demo videos for each URL
  final List<Subject> subjects = [
    Subject(
      name: 'Mathematics',
      icon: Icons.calculate_outlined,
      color: Colors.blue,
      videos: [
        YouTubeVideo(
          'Algebra Basics',
          'https://youtu.be/WUvTyaaNkzM', // Khan Academy Algebra
          'Learn the fundamentals of algebra',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        ),
        YouTubeVideo(
          'Geometry Fundamentals',
          'https://youtu.be/mhd9FXYdf4s', // Geometry video
          'Master geometric concepts',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        ),
        YouTubeVideo(
          'Calculus Introduction',
          'https://youtu.be/EKvHQc3QEow', // Calculus intro
          'Introduction to calculus concepts',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
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
          'https://youtu.be/ZM8ECpBuQYE', // Physics laws
          'Fundamental laws of physics',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        ),
        YouTubeVideo(
          'Chemistry Basics',
          'https://youtu.be/FSyAehMdpyI', // Chemistry basics
          'Introduction to chemistry',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
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
          'https://youtu.be/xuCn8ux2gbs', // World history
          'A comprehensive world history',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
        ),
        YouTubeVideo(
          'Ancient Civilizations',
          'https://youtu.be/Z_AYXcDOWVg', // Ancient civilizations
          'Explore ancient civilizations',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
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
          'https://youtu.be/VQmPQflsWV0', // Grammar basics
          'Essential grammar rules',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
        ),
        YouTubeVideo(
          'Literature Analysis',
          'https://youtu.be/msVS9qmOEL0', // Literature analysis
          'Analyzing literary works',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
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
          'https://youtu.be/rfscVS0vtbw', // Python tutorial
          'Learn Python programming',
          VideoQuality.hd1080,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
        ),
        YouTubeVideo(
          'Web Development',
          'https://youtu.be/UB1O30fR-EE', // Web development
          'Build websites and web apps',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
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
          'https://youtu.be/pMC0Cx3Uk84', // Drawing tutorial
          'Learn to draw effectively',
          VideoQuality.hd720,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
        YouTubeVideo(
          'Digital Art Basics',
          'https://youtu.be/Nj_O2kqx_fI', // Digital art
          'Create digital artwork',
          VideoQuality.hd1080,
          'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        ),
      ],
    ),
  ];

  // Map to store custom video URLs for pasted URLs
  final Map<String, String> _customVideoUrls = {
    // Default demo videos for common YouTube URLs
    'default': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: _showPasteUrlDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select a subject to explore videos',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: _buildSubjectsList()),
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
      child: InkWell(
        onTap: () => _navigateToVideos(subject),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: subject.color.withOpacity(0.1),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text('${subject.videos.length} videos'),
                  backgroundColor: subject.color.withOpacity(0.1),
                ),
              ],
            ),
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
          title: const Text('Add Video URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'Paste YouTube URL here...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 8),
              Text(
                'Note: This will download a demo video for demonstration purposes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                String url = urlController.text.trim();
                Navigator.of(context).pop();
                if (url.isNotEmpty) {
                  _navigateToUrlDownloader(url);
                }
              },
              child: const Text('Download'),
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
    // Extract a title based on the URL or video ID
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
    // For demonstration, we'll use different demo videos based on the URL
    String videoId = _extractVideoId(originalUrl);
    
    // Map different video IDs to different demo videos
    Map<String, String> demoVideoMap = {
      'dQw4w9WgXcQ': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', // Rick Roll
      'kJQP7kiw5Fk': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', // Despacito
      'fJ9rUzIMcZQ': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4', // Bohemian Rhapsody
      'default': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    };
    
    return demoVideoMap[videoId] ?? demoVideoMap['default']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Video'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildVideoCard(),
      ),
    );
  }

  Widget _buildVideoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (thumbnailUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
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
              const SizedBox(height: 16),
            ],
            
            Text(
              videoTitle ?? 'Unknown Video',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              widget.url,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            
            if (isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: downloadProgress / 100,
              ),
              const SizedBox(height: 8),
              Text(
                'Downloading... ${downloadProgress.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openYouTubeVideo(widget.url),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch on YouTube'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDownloading ? null : _downloadVideo,
                    icon: Icon(
                      isDownloading ? Icons.hourglass_empty : Icons.download,
                    ),
                    label: Text(isDownloading ? 'Downloading...' : 'Download'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadVideo() async {
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

      // Get the appropriate demo video URL for this pasted URL
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
      SnackBar(content: Text(message)),
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
      appBar: AppBar(
        title: Text(widget.subject.name),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.subject.color.withOpacity(0.1),
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
              label: Text('${widget.subject.videos.length} educational videos'),
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
    String videoId = _extractVideoId(video.url);
    String thumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 60,
                    child: Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: widget.subject.color.withOpacity(0.1),
                          child: Icon(
                            Icons.play_circle_filled,
                            color: widget.subject.color,
                            size: 30,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              ),
              const SizedBox(height: 8),
              Text(
                'Downloading... ${progress.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openYouTubeVideo(video.url),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDownloading ? null : () => _downloadVideo(video),
                    icon: Icon(
                      isDownloading ? Icons.hourglass_empty : Icons.download,
                    ),
                    label: Text(isDownloading ? 'Downloading...' : 'Download'),
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
    String qualityText = quality == VideoQuality.hd1080 ? 'HD 1080p' : 'HD 720p';
    return Chip(
      label: Text(qualityText),
      backgroundColor: widget.subject.color.withOpacity(0.1),
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

      // Use the specific demo video URL assigned to this video
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
      SnackBar(content: Text(message)),
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
  final String downloadUrl; // New field for the actual download URL

  YouTubeVideo(
    this.title, 
    this.url, 
    this.description, 
    this.quality, 
    this.downloadUrl, // Added download URL parameter
  );
}
