import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/model_service.dart';
import '../theme/app_theme.dart';
import 'emergency_chat_view.dart';
import 'emergency_voice_view.dart';
import 'emergency_guide_view.dart';
import 'protocol_library_view.dart';
import '../services/mesh_service.dart';
import 'mesh_chat_page.dart';

/// Siren-Zero Main Screen
/// Emergency-first UI for rapid access to life-saving guidance
class SirenZeroHomeView extends StatefulWidget {
  const SirenZeroHomeView({super.key});

  @override
  State<SirenZeroHomeView> createState() => _SirenZeroHomeViewState();
}

class _SirenZeroHomeViewState extends State<SirenZeroHomeView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final mesh = MeshService();   
  List<String> getSteps(String category) {
  final c = category.toLowerCase();

  if (c.contains("bleed")) {
    return [
      "Call 911 for severe bleeding",
      "Wear gloves if available",
      "Apply direct pressure",
      "Press firmly for 10 minutes",
      "Add more cloth if soaked",
      "Elevate injured area",
    ];
  }

  if (c.contains("breath")) {
    return [
      "Check responsiveness",
      "Call emergency services",
      "Start CPR (30 compressions)",
      "Give 2 rescue breaths",
      "Repeat until help arrives",
    ];
  }

  if (c.contains("unconscious")) {
    return [
      "Check responsiveness (tap and shout)",
      "Call emergency services immediately",
      "Check breathing for 10 seconds",
      "If breathing, place in recovery position",
      "Loosen tight clothing",
      "Monitor breathing continuously",
    ];
  }

  if (c.contains("burn")) {
    return [
      "Remove person from heat source",
      "Cool burn under running water (10–20 minutes)",
      "Remove tight items (rings, clothing)",
      "Cover with clean, non-stick cloth",
      "Do NOT apply ice or creams",
      "Seek medical help if severe",
    ];
  }

  return ["No steps available"];
}
  @override
  void initState() {
    super.initState();
    _checkModelStatus();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkModelStatus() async {
    final modelService = Provider.of<ModelService>(context, listen: false);
    // Auto-load models if they're downloaded but not loaded
    final isDownloaded = await modelService.isModelDownloaded(ModelService.llmModelId);
    if (!modelService.isLLMLoaded && isDownloaded) {
      await modelService.downloadAndLoadLLM();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSystemStatusCard(),
                      const SizedBox(height: 20),
                      _buildMeshCard(),
                      const SizedBox(height: 28),
                      _buildSirenZeroCard(),
                      const SizedBox(height: 28),
                      _buildQuickActions(),
                      const SizedBox(height: 28),
                      _buildToolsSection(),
                      const SizedBox(height: 20),
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

  Widget _buildMeshCard() {
  return GestureDetector(
    onTap: () {
      if (mesh.connectedDevices.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MeshChatPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No devices connected"),
          ),
        );
      }
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // 🔥 LEFT ICON
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.hub,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          // 🔥 TEXT SECTION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mesh Communication",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Offline peer-to-peer emergency network",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  mesh.connectedDevices.isEmpty
                      ? "🔴 No peers nearby"
                      : "🟢 Connected to ${mesh.connectedDevices.length} device(s)",
                  style: TextStyle(
                    color: mesh.connectedDevices.isEmpty
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (mesh.connectedDevices.isNotEmpty)
                  const SizedBox(height: 6),

                if (mesh.connectedDevices.isNotEmpty)
                  const Text(
                    "Tap to chat →",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // 🔥 SCAN BUTTON
          IconButton(
            icon: const Icon(Icons.radar, color: Colors.white),
            onPressed: () async {
              try {
                print("📡 STARTING MESH...");

                await mesh.initPermissions();
                print("✅ Permissions granted");

                await mesh.startAdvertising();
                print("📡 Advertising started");

                await mesh.startDiscovery();
                print("🔍 Discovery started");

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Scanning for nearby devices..."),
                  ),
                );
              } catch (e) {
                print("❌ ERROR: $e");

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                  ),
                );
              }
            },
          ),
        ],
      ),
    ),
  )
      .animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.08, end: 0);
}
Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    child: Row(
      children: const [
        Icon(Icons.emergency, color: Colors.red, size: 32),
        SizedBox(width: 12),
        Text(
          "SIREN-ZERO",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSystemStatusCard() {
  return Consumer<ModelService>(
    builder: (context, modelService, child) {
      final isReady = modelService.isLLMLoaded;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08), // glass feel
          borderRadius: BorderRadius.circular(20),

          // 🔥 Neon border
          border: Border.all(
            color: isReady
                ? const Color(0xFF1A4DFF)
                : AppColors.warningYellow,
            width: 1.5,
          ),

          // 💡 Premium shadow
          boxShadow: [
            BoxShadow(
              color: isReady
                  ? const Color(0xFF1A4DFF).withOpacity(0.25)
                  : AppColors.warningYellow.withOpacity(0.25),
              blurRadius: 25,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 🔷 ICON BOX
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isReady
                        ? const Color(0xFF1A4DFF).withOpacity(0.15)
                        : AppColors.warningYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isReady
                        ? Icons.verified_rounded
                        : Icons.download_rounded,
                    color: isReady
                        ? const Color(0xFF1A4DFF)
                        : AppColors.warningYellow,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 16),

                // 🔤 TEXT SECTION
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReady ? 'SYSTEM READY' : 'SETUP REQUIRED',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: isReady
                                      ? const Color(0xFF1A4DFF) // 🔥 clean blue
                                      : AppColors.warningYellow,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isReady
                            ? '100% Offline • All systems operational'
                            : 'Download AI models to enable offline mode',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                      ),
                    ],
                  ),
                ),

                // ⚡ SETUP BUTTON
                if (!isReady)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warningYellow,
                          AppColors.warningYellow.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showModelSetup(),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          child: Text(
                            'SETUP',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // 🚨 ALERT BOX
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emergencyRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.emergencyRed.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.emergencyRed,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Always call emergency services when available (911)',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 11.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 700.ms)
          .slideY(begin: 0.08, end: 0);
    },
  );
}


  Widget _buildSirenZeroCard() {
  return Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.red.withOpacity(0.25),
          blurRadius: 25,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // 🔴 TOP SECTION
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF2D2D),
                  Color(0xFFB30000),
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Chat with',
                          style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 4),
                      Text(
                        'Siren Zero',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Your personal AI emergency assistant 🚨',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                TweenAnimationBuilder(
                  tween: Tween(begin: 0.9, end: 1.1),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ⚪ BOTTOM SECTION
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // 🔥 FIXED CHIPS (NO CUT + SAME LINE)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickChip(
                        "How to perform CPR?",
                        Icons.favorite,
                      ),
                      const SizedBox(width: 10),
                      _buildQuickChip(
                        "Treating burns",
                        Icons.local_fire_department,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 💬 INPUT BOX
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyChatView(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [

                        const Expanded(
                          child: Text(
                            'Describe your emergency...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 6),

                        _buildIconBox(
                          Icons.image,
                          Colors.blue,
                          _handleImageInput,
                        ),

                        const SizedBox(width: 6),

                        _buildIconBox(
                          Icons.mic,
                          Colors.orange,
                          _handleVoiceInput,
                        ),

                        const SizedBox(width: 6),

                        Container(
                          height: 40,
                          width: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF2D2D),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send,
                                color: Colors.white, size: 18),
                            onPressed: _handleSendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 🔵 DOTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedDot(),
                    const SizedBox(width: 6),
                    _buildAnimatedDot(delay: 200),
                    const SizedBox(width: 6),
                    _buildAnimatedDot(delay: 400),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  )
      .animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.08, end: 0);
}
  Widget _buildIconBox(IconData icon, Color color, VoidCallback onTap) {
  return Container(
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
      icon: Icon(icon, color: color, size: 18),
      onPressed: onTap,
    ),
  );
}
  Widget _buildQuickChip(String label, IconData icon) {
  return Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min, // 🔥 key fix
      children: [
        Icon(icon, size: 14, color: Colors.red),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
}
  Widget _buildAnimatedDot({int delay = 0}) {
  return TweenAnimationBuilder(
    tween: Tween(begin: 0.3, end: 1.0),
    duration: Duration(milliseconds: 800 + delay),
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            shape: BoxShape.circle,
          ),
        ),
      );
    },
  );
}

  void _handleImageInput() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image input coming soon!')),
    );
  }

  void _handleVoiceInput() {
    // Navigate to voice view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyVoiceView(),
      ),
    );
  }

  void _handleSendMessage() {
    // Navigate to chat view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyChatView(),
      ),
    );
  }

  // ================= QUICK ACTION CARD =================

Widget _buildQuickActionCard(
    Map<String, String> item, int index) {

  // ✅ SAFE EXTRACTION
  final String title = item['title'] ?? '';
  final String emoji = item['emoji'] ?? '';
  final String desc = item['desc'] ?? '';

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _handleQuickAction(title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12), // 🔥 reduced padding
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textMuted.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

// 🔥 FIXED LAYOUT (NO OVERFLOW)
      child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    // 🔝 TOP ROW
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20), // 🔥 slightly smaller
          ),
        ),
        const Icon(
          Icons.arrow_forward,
          size: 16,
          color: AppColors.infoBlue,
        ),
      ],
    ),

    const SizedBox(height: 6),

    // 🔽 TEXT AREA
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

        // TITLE
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 11, // 🔥 smaller
                  ),
              maxLines: 2, // 🔥 IMPORTANT
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 2),

          // DESC
          Text(
            desc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black87,
                  fontSize: 10,
                ),
            maxLines: 1, // 🔥 IMPORTANT
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  ],
)
  .animate()
  .fadeIn(duration: 500.ms, delay: (1200 + (index * 80)).ms)
  .slideY(begin: 0.1, end: 0),
      ),
    ));
}


// ================= QUICK ACTION GRID =================
Widget _buildQuickActions() {
  final List<Map<String, String>> actions = [
    {
      'emoji': '🚨',
      'title': 'NOT BREATHING',
      'desc': 'Start CPR asap',
    },
    {
      'emoji': '🩸',
      'title': 'BLEEDING',
      'desc': 'Stop bleeding fast',
    },
    {
      'emoji': '🧠',
      'title': 'UNCONSCIOUS',
      'desc': 'Check response',
    },
    {
      'emoji': '🔥',
      'title': 'BURN / INJURY',
      'desc': 'Treat injury safely',
    },
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 1.18,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: actions.length,
    itemBuilder: (context, index) {
      return _buildQuickActionCard(actions[index], index);
    },
  );
}


// ================= HANDLER =================

void _handleQuickAction(String category) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EmergencyGuideView(
        title: category,
        steps: getSteps(category),
      ),
    ),
  );
}

Widget _buildToolCard(
  String title,
  String subtitle,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}

// ================= TOOLS SECTION =================

Widget _buildToolsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Resources',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
      ),
      const SizedBox(height: 16),

      _buildToolCard(
        'Protocol Library',
        'Step-by-step medical emergency procedures',
        Icons.library_books,
        AppColors.alertOrange,
        () => _navigateToProtocolLibrary(),
      ).animate().fadeIn(duration: 500.ms, delay: 1600.ms),
    ],
  );
}

  void _navigateToProtocolLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProtocolLibraryView(initialCategory: 'general'),
      ),
    );
  }

  void _showModelSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModelSetupSheet(),
    );
  }
}

/// Model setup bottom sheet
class ModelSetupSheet extends StatelessWidget {
  const ModelSetupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Required',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Download AI models to enable offline emergency guidance. This only needs to be done once.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ModelService>(
              builder: (context, modelService, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildModelItem(
                        context,
                        'Language Model (LLM)',
                        'SmolLM2 for emergency guidance',
                        '~400MB',
                        false, // Will check async
                        modelService.isLLMLoaded,
                        modelService.isLLMDownloading ? modelService.llmDownloadProgress : null,
                        () => modelService.downloadAndLoadLLM(),
                      ),
                      const SizedBox(height: 12),
                      _buildModelItem(
                        context,
                        'Speech-to-Text (STT)',
                        'Whisper Tiny for voice input',
                        '~80MB',
                        false, // Will check async
                        modelService.isSTTLoaded,
                        modelService.isSTTDownloading ? modelService.sttDownloadProgress : null,
                        () => modelService.downloadAndLoadSTT(),
                      ),
                      const SizedBox(height: 12),
                      _buildModelItem(
                        context,
                        'Text-to-Speech (TTS)',
                        'Piper TTS for voice output',
                        '~100MB',
                        false, // Will check async
                        modelService.isTTSLoaded,
                        modelService.isTTSDownloading ? modelService.ttsDownloadProgress : null,
                        () => modelService.downloadAndLoadTTS(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelItem(
    BuildContext context,
    String title,
    String subtitle,
    String size,
    bool isDownloaded,
    bool isLoaded,
    double? progress,
    VoidCallback onDownload,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$subtitle • $size',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isLoaded)
                const Icon(Icons.check_circle, color: AppColors.safeGreen)
              else if (progress != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                  ),
                )
              else
                IconButton(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
