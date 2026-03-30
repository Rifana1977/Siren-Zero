import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/emergency_response_service.dart';
import '../services/emergency_prompts.dart';
import '../theme/app_theme.dart';
import '../services/mesh_service.dart';

/// Emergency Chat View
/// Premium text-based emergency guidance with multimodal input

class EmergencyChatView extends StatefulWidget {
  final EmergencyCategory initialCategory;

  const EmergencyChatView({
    super.key,
    this.initialCategory = EmergencyCategory.general,
  });

  @override
  State<EmergencyChatView> createState() => _EmergencyChatViewState();
}

class _EmergencyChatViewState extends State<EmergencyChatView> {
  late EmergencyResponseService _emergencyService;
  final mesh = MeshService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isStreaming = false;
  String _streamingText = '';

  @override
  void initState() {
    super.initState();

    _emergencyService = EmergencyResponseService();
    _emergencyService.setCategory(widget.initialCategory);

  setupMesh(); // 🔥 ADD THIS
}
  void setupMesh() async {
  await mesh.initPermissions();

  // 🔥 Receive messages from other phones
  mesh.onMessageReceived = (msg) {
    setState(() {
      _emergencyService.conversationHistory.add(
        EmergencyMessage(
          text: "📡 $msg",
          isUser: false,
          timestamp: DateTime.now(),
          category: widget.initialCategory,
        ),
      );
    });

    _scrollToBottom();
  };
}

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _emergencyService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
  final text = _textController.text.trim();
  if (text.isEmpty) return;

  _textController.clear();

  // 🔥 SHOW USER MESSAGE
  setState(() {
    _emergencyService.conversationHistory.add(
      EmergencyMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        category: widget.initialCategory,
      ),
    );
  });

  _scrollToBottom();

  // 🔥 SEND VIA MESH (OFFLINE)
  await mesh.sendMessage(text);

  // 🔥 ALSO KEEP AI RESPONSE (optional)
  setState(() {
    _isStreaming = true;
    _streamingText = '';
  });

  try {
    await for (final token in _emergencyService.streamEmergencyResponse(text)) {
      setState(() {
        _streamingText += token;
      });
      _scrollToBottom();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  } finally {
    setState(() {
      _isStreaming = false;
      _streamingText = '';
    });
    _scrollToBottom();
  }
}

  void _handleImageInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image input coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.primaryBg,
    resizeToAvoidBottomInset: true,

    // 🔥 FIXED APPBAR
    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      titleSpacing: 0,

      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),

      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.emergencyGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),

          const SizedBox(width: 8),

          // 🔥 CRITICAL FIX
          Expanded(
            child: Text(
              'AI Emergency Assistant',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
            ),
          ),
        ],
      ),
    ),

    body: Column(
      children: [
        Expanded(
          child: _emergencyService.conversationHistory.isEmpty && !_isStreaming
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _emergencyService.conversationHistory.length +
                      (_isStreaming ? 1 : 0),
                  itemBuilder: (context, index) {

                    if (_isStreaming &&
                        index == _emergencyService.conversationHistory.length) {
                      return _buildMessageBubble(
                        _streamingText,
                        false,
                        isStreaming: true,
                      );
                    }

                    final message =
                        _emergencyService.conversationHistory[index];

                    return _buildMessageBubble(
                      message.text,
                      message.isUser,
                    );
                  },
                ),
        ),

        _buildInputArea(),
      ],
    ),
  );
}

  Widget _buildEmptyState() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        const SizedBox(height: 20), // 🔥 reduced

        // ICON
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.emergencyGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.emergencyRed.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
        ).animate().scale(duration: 600.ms),

        const SizedBox(height: 20),

        // TITLE
        Text(
          'Start a Conversation',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),

        const SizedBox(height: 8),

        // SUBTEXT
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Ask me anything about emergency procedures, first aid, or medical guidance',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),

        const SizedBox(height: 24),

      // 🔥 FINAL CHIP FIX
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildQuickPrompt('How to perform CPR?', Icons.favorite),
          const SizedBox(height: 10),

          _buildQuickPrompt('Treating burns', Icons.local_fire_department),
          const SizedBox(height: 10),

          _buildQuickPrompt('Stop bleeding', Icons.bloodtype),
        ],
      ),
      const SizedBox(height: 30),
      ],
    ),
  );
}

  Widget _buildQuickPrompt(String text, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _textController.text = text;
          _sendMessage();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.textMuted.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.emergencyRed),
              const SizedBox(width: 8),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, {bool isStreaming = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? AppColors.emergencyGradient
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? AppColors.emergencyRed.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isUser ? Colors.white : AppColors.textPrimary,
                    height: 1.5,
                  ),
            ),
            if (isStreaming)
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.emergencyRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Generating...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.textMuted.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Image Button
                  _buildInputIconButton(
                    Icons.image_outlined,
                    AppColors.infoBlue,
                    'Add Image',
                    _handleImageInput,
                  ),
                  const SizedBox(width: 8),
                  
                  // Voice Button
                  _buildInputIconButton(
                    Icons.mic_outlined,
                    AppColors.alertOrange,
                    'Voice Input',
                    _handleVoiceInput,
                  ),
                  const SizedBox(width: 12),
                  
                  // Text Field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Describe your emergency...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: null,
                      minLines: 1,
                      enabled: !_isStreaming,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Send Button
                  _buildSendButton(),
                ],
              ),
            ),
            
            // Feature Pills
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeaturePill(Icons.offline_bolt, 'Offline'),
                  const SizedBox(width: 6),
                  _buildFeaturePill(Icons.lock_outline, 'Private'),
                  const SizedBox(width: 6),
                  _buildFeaturePill(Icons.speed, '7ms'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputIconButton(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isStreaming ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isStreaming
                  ? AppColors.textMuted.withOpacity(0.1)
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isStreaming
                    ? AppColors.textMuted.withOpacity(0.2)
                    : color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: _isStreaming ? AppColors.textMuted : color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isStreaming ? null : _sendMessage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: _isStreaming ? null : AppColors.emergencyGradient,
            color: _isStreaming ? AppColors.textMuted : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isStreaming
                ? null
                : [
                    BoxShadow(
                      color: AppColors.emergencyRed.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(
            _isStreaming ? Icons.stop_rounded : Icons.send_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: AppColors.darkBlue),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBlue,
                ),
          ),
        ],
      ),
    );
  }
}
