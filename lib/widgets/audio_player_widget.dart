import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String? title;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.title,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  double _progress = 0.0;

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      // Simulate playback progress
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isPlaying) {
          setState(() => _progress = 0.3);
        }
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _isPlaying) {
          setState(() => _progress = 0.7);
        }
      });
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _isPlaying) {
          setState(() {
            _progress = 1.0;
            _isPlaying = false;
          });
        }
      });
    }
  }

  Future<void> _openAudioLink() async {
    final Uri uri = Uri.parse(widget.audioUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open audio URL: ${widget.audioUrl}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: const Color(0xFF2196F3),
              size: 32,
            ),
            onPressed: _togglePlay,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title ?? 'Voice Note Recording',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      _isPlaying ? '0:15 / 0:30' : '0:30',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.blue, size: 20),
            onPressed: _openAudioLink,
            tooltip: 'Download Voice Note',
          ),
        ],
      ),
    );
  }
}
