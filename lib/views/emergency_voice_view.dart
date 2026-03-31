import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';
import '../services/model_service.dart';
import '../services/emergency_prompts.dart';
import '../theme/app_theme.dart';

/// Emergency Voice Assistant View
/// Hands-free emergency guidance using VAD → STT → LLM → TTS pipeline
class EmergencyVoiceView extends StatefulWidget {
  const EmergencyVoiceView({super.key});

  @override
  State<EmergencyVoiceView> createState() => _EmergencyVoiceViewState();
}

class _EmergencyVoiceViewState extends State<EmergencyVoiceView> {
  VoiceSessionHandle? _session;
  List<_ConversationTurn> _conversation = [];
  double _audioLevel = 0.0;
  String _status = 'Tap to start voice assistant';
  bool _isActive = false;
  EmergencyCategory _category = EmergencyCategory.general;

  @override
  void dispose() {
    _session?.stop();
    super.dispose();
  }

  Future<void> _toggleSession() async {
    if (_session != null) {
      _session!.stop();
      setState(() {
        _session = null;
        _isActive = false;
        _status = 'Stopped';
      });
      return;
    }

    final modelService = Provider.of<ModelService>(context, listen: false);

    // Check if all models are ready
    if (!modelService.isVoiceAgentReady) {
      setState(() => _status = 'Loading models...');

      // Load all models
      if (!modelService.isSTTLoaded) {
        await modelService.downloadAndLoadSTT();
      }
      if (!modelService.isLLMLoaded) {
        await modelService.downloadAndLoadLLM();
      }
      if (!modelService.isTTSLoaded) {
        await modelService.downloadAndLoadTTS();
      }
    }

    // Start voice session
    try {
      _session = await RunAnywhere.startVoiceSession(
        config: VoiceSessionConfig(
          silenceDuration: 1.5,
          autoPlayTTS: true,
          continuousMode: true,
        ),
      );

      setState(() => _isActive = true);

      // Handle events
      _session!.events.listen((event) {
        if (!mounted) return;

        setState(() {
          switch (event) {
            case VoiceSessionListening(:final audioLevel):
              _audioLevel = audioLevel;
              _status = 'Listening... (speak now)';

            case VoiceSessionSpeechStarted():
              _status = 'Speech detected...';

            case VoiceSessionProcessing():
              _status = 'Processing...';

            case VoiceSessionTranscribed(:final text):
              _conversation.add(_ConversationTurn(text: text, isUser: true));
              _status = 'Generating response...';

            case VoiceSessionResponded(:final text):
              _conversation.add(_ConversationTurn(text: text, isUser: false));
              _status = 'Speaking response...';

            case VoiceSessionSpeaking():
              _status = 'Speaking...';

            case VoiceSessionTurnCompleted():
              _status = 'Listening...';

            case VoiceSessionError(:final message):
              _status = 'Error: $message';

            case VoiceSessionStopped():
              _status = 'Stopped';
              _isActive = false;

            default:
              break;
          }
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: const Color(0xFF0F172A).withOpacity(0.8),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Voice Assistant',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        actions: [
          PopupMenuButton<EmergencyCategory>(
            icon: const Icon(Icons.category),
            onSelected: (category) {
              setState(() => _category = category);
            },
            itemBuilder: (context) {
              return EmergencyCategory.values.map((category) {
                return PopupMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Text(category.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(category.title),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _conversation.length,
              itemBuilder: (context, index) {
                final turn = _conversation[index];
                return _buildMessageBubble(turn.text, turn.isUser);
              },
            ),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildCategoryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(_category.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _category.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                ),
                Text(
                  'Voice-guided emergency assistance',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser
              ? null
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border:
              isUser ? null : Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? const Color(0xFF38BDF8).withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.volume_up_rounded,
                    size: 18, color: Color(0xFF38BDF8)),
              ),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          isUser ? Colors.white : Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F172A).withOpacity(0.85)
                : Colors.white.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Audio level indicator
                if (_isActive)
                  Container(
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(
                      value: _audioLevel.clamp(0.0, 1.0),
                      backgroundColor: AppColors.surfaceElevated,
                      color: AppColors.infoBlue,
                    ),
                  ),

                // Status text
                Text(
                  _status,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Main control button with dynamic scale based on audio volume
                GestureDetector(
                  onTap: _toggleSession,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 90 + (_isActive ? (_audioLevel * 40) : 0),
                    height: 90 + (_isActive ? (_audioLevel * 40) : 0),
                    decoration: BoxDecoration(
                      gradient: _isActive
                          ? const LinearGradient(
                              colors: [Color(0xFFFF2D55), Color(0xFFE6003B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isActive
                                  ? const Color(0xFFFF2D55)
                                  : const Color(0xFF38BDF8))
                              .withOpacity(0.4 + (_audioLevel * 0.4)),
                          blurRadius: 25 + (_audioLevel * 20),
                          spreadRadius: _audioLevel * 10,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isActive ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isActive ? 'TAP TO STOP' : 'TAP TO START',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white54,
                        letterSpacing: 1.5,
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

class _ConversationTurn {
  final String text;
  final bool isUser;

  _ConversationTurn({required this.text, required this.isUser});
}
