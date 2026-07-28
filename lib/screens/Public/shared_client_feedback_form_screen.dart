import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/client_feedback/client_feedback_bloc.dart';
import '../../services/audio_recording_service.dart';

class SharedClientFeedbackFormScreen extends StatefulWidget {
  final String? clientName;
  final String? clientId;
  final String? projectId;

  const SharedClientFeedbackFormScreen({
    super.key,
    this.clientName,
    this.clientId,
    this.projectId,
  });

  @override
  State<SharedClientFeedbackFormScreen> createState() => _SharedClientFeedbackFormScreenState();
}

class _SharedClientFeedbackFormScreenState extends State<SharedClientFeedbackFormScreen> {
  final Map<String, double> _categoryRatings = {};
  final TextEditingController _commentsCtrl = TextEditingController();

  bool _isRecording = false;
  int _recordSeconds = 0;
  File? _recordedAudioFile;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    context.read<ClientFeedbackBloc>().add(LoadClientFeedbackEvent());
  }

  @override
  void dispose() {
    _commentsCtrl.dispose();
    super.dispose();
  }

  void _toggleRecord() async {
    if (!_isRecording) {
      final success = await AudioRecordingService.instance.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
        });
        AudioRecordingService.instance.durationStream.listen((sec) {
          if (mounted && _isRecording) {
            setState(() => _recordSeconds = sec);
          }
        });
      }
    } else {
      final file = await AudioRecordingService.instance.stopRecording();
      setState(() {
        _isRecording = false;
        _recordedAudioFile = file;
      });
    }
  }

  void _submitForm() {
    if (_commentsCtrl.text.trim().isEmpty) {
      AppSnackBar.showCustom(context, 
        const SnackBar(content: Text('Please enter your comments.')),
      );
      return;
    }

    final cId = widget.clientId ?? '00000000-0000-0000-0000-000000000000';
    double overallSum = 0.0;
    if (_categoryRatings.isNotEmpty) {
      _categoryRatings.forEach((_, v) => overallSum += v);
      overallSum /= _categoryRatings.length;
    } else {
      overallSum = 5.0;
    }

    context.read<ClientFeedbackBloc>().add(AddClientFeedbackEvent(
      clientId: cId,
      projectId: widget.projectId,
      rating: overallSum,
      categoryRatings: Map.from(_categoryRatings),
      feedbackType: 'General',
      comments: _commentsCtrl.text.trim(),
      status: 'pending',
      audioFile: _recordedAudioFile,
    ));

    setState(() {
      _submitted = true;
    });
  }

  Widget _buildCategoryRow(String catName) {
    final rating = _categoryRatings[catName] ?? 5.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              catName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          Row(
            children: List.generate(5, (idx) {
              final starVal = idx + 1.0;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _categoryRatings[catName] = starVal;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    starVal <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '${rating.toInt()}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text('Thank You!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text(
                  'Your feedback has been submitted successfully to Ecraftz CRM.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final categoriesState = context.watch<ClientFeedbackBloc>().state.categories;
    final catList = categoriesState.isNotEmpty
        ? categoriesState.map((c) => c.name).toList()
        : ['Service Quality', 'Communication', 'Timeliness & Delivery'];

    // Ensure default 5.0 for all categories
    for (final c in catList) {
      _categoryRatings.putIfAbsent(c, () => 5.0);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark web-identical background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Dark container card matching Screenshot 2
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ecraftz 3D Logo / Header matching Screenshot 2
                Image.asset(
                  'assets/logo3d.png',
                  height: 48,
                  errorBuilder: (_, __, ___) => Image.asset('assets/ecraftzlogolight.png', height: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Share Your Feedback',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tell us how we did on your recent project.',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 24),

                // Dynamic Categories Star Pickers (Screenshot 2)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rate our services in these areas:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: catList.map((cName) => _buildCategoryRow(cName)).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Comments & Suggestions
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Comments & Suggestions',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[300]),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _commentsCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tell us what you liked, what went well, or what we can improve...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                  ),
                ),
                const SizedBox(height: 20),

                // Optional Voice Note Recorder (Screenshot 2)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Voice Note (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[300]),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isRecording
                              ? 'Recording voice message... ${_recordSeconds}s'
                              : (_recordedAudioFile != null ? 'Voice note recorded!' : 'Record a short voice message'),
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording ? Colors.red : const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 16, color: Colors.white),
                        label: Text(_isRecording ? 'Stop' : 'Record', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: _toggleRecord,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Feedback Button (Screenshot 2 gradient)
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _submitForm,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Submit Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
