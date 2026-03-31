import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'emergency_prompts.dart';

/// Protocol detail bottom sheet
class ProtocolDetailSheet extends StatelessWidget {
  final QuickActionProtocol protocol;

  const ProtocolDetailSheet({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceCard
            : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMuted
                  : AppColors.lightTextMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.emergencyGradient,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(
                  protocol.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        protocol.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        protocol.category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Warning message
          if (protocol.warningMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warningYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warningYellow,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.warningYellow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      protocol.warningMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textPrimary
                                : const Color(0xFF92400E), // Deep amber for legibility
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),

          // Steps
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              itemCount: protocol.steps.length,
              itemBuilder: (context, index) {
                return _buildStep(context, index + 1, protocol.steps[index]);
              },
            ),
          ),

          // Emergency call button
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ).copyWith(
                elevation: MaterialStateProperty.all(0),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'In emergency: Call 911 or local emergency number'),
                  ),
                );
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B).withOpacity(0.4)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.emergencyRed.withOpacity(0.8),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergencyRed.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16), // Added horizontal padding
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7), // Slightly smaller
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_in_talk_rounded,
                              color: AppColors.emergencyRed, size: 20), // Smaller icon
                        ),
                        const SizedBox(width: 8), // Reduced gap
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "CALL EMERGENCY SERVICES",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 13, // Significant reduction if needed
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int number, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.emergencyGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceElevated
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.lightTextPrimary,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Protocol Library View
/// Browse and view step-by-step emergency procedures
class ProtocolLibraryView extends StatelessWidget {
  final String initialCategory; // ✅ accept String

  const ProtocolLibraryView({
    super.key,
    required this.initialCategory,
  });

  @override
  Widget build(BuildContext context) {
    final protocols =
        quickActionProtocols; // Initialize empty list or import the correct variable

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.primaryBg
          : AppColors.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0F172A).withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF0F172A)),
        title: Text("Emergency Protocols",
            style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: protocols.length,
        itemBuilder: (context, index) {
          return _buildProtocolCard(context, protocols[index]);
        },
      ),
    );
  }

  Widget _buildProtocolCard(
      BuildContext context, QuickActionProtocol protocol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B).withOpacity(0.8)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showProtocolDetail(context, protocol),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    protocol.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        protocol.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        protocol.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white60
                                  : AppColors.lightTextSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : AppColors.lightTextSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProtocolDetail(BuildContext context, QuickActionProtocol protocol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProtocolDetailSheet(protocol: protocol),
    );
  }
}
