import 'package:flutter/material.dart';
import 'dart:math' as math;

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
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

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
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildVideoScreen(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoScreen() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 500,
      constraints: const BoxConstraints(maxWidth: 800),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Floating particles
            _buildParticles(),

            // Wave animation
            _buildWaveAnimation(),

            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHelloText(),
                const SizedBox(height: 20),
                _buildSubtitle(),
                const SizedBox(height: 40),
                _buildVideoControls(),
              ],
            ),

            // Status indicator
            _buildStatusIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildHelloText() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Text(
          'Hey!',
          style: TextStyle(
            fontSize: 60,
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
                fontSize: 24,
                color: Colors.white.withAlpha((0.8 * 255).toInt()),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoControls() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween<double>(begin: 30.0, end: 0.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: 1 - (value / 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: isPlaying ? Icons.pause : Icons.play_arrow,
                  onTap: _toggleVideo,
                  isPlay: true,
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: isMuted ? Icons.volume_off : Icons.volume_up,
                  onTap: _toggleMute,
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: isCameraOn ? Icons.videocam : Icons.videocam_off,
                  onTap: _toggleCamera,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPlay = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isPlay
              ? const Color(0xFF4CAF50).withOpacity(0.7)
              : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Positioned(
      top: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFF4CAF50).withOpacity(_glowAnimation.value),
                  blurRadius: 10,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(9, (index) {
            final progress = (_particleController.value + (index * 0.1)) % 1.0;
            final opacity = progress < 0.1 || progress > 0.9
                ? 0.0
                : (progress > 0.5 ? 0.8 : 1.0);

            return Positioned(
              left: (10 + index * 10) /
                  100 *
                  MediaQuery.of(context).size.width *
                  0.9,
              bottom: 500 * progress,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildWaveAnimation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 100,
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              (MediaQuery.of(context).size.width * 0.9) *
                  (math.sin(_particleController.value * 2 * math.pi) * 0.5),
              0,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
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

// Usage example:
void main() {
  runApp(MaterialApp(
    home: const VideoScreen(),
    debugShowCheckedModeBanner: false,
  ));
}
