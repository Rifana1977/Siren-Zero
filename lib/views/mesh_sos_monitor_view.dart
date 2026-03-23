import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_network_service.dart';
import 'package:intl/intl.dart';

/// View to display and monitor SOS messages from the mesh network
class MeshSOSMonitorView extends StatefulWidget {
  const MeshSOSMonitorView({Key? key}) : super(key: key);

  @override
  State<MeshSOSMonitorView> createState() => _MeshSOSMonitorViewState();
}

class _MeshSOSMonitorViewState extends State<MeshSOSMonitorView> {
  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    final meshService = context.read<MeshNetworkService>();
    
    // Register handler for SOS messages
    meshService.registerMessageHandler(MeshMessageType.sos, (message) {
      // Show notification when SOS is received
      _showSOSNotification(message);
    });
  }

  void _showSOSNotification(MeshMessage message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sos, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'NEW SOS from ${message.senderName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message.payload['description'] ?? 'Emergency alert',
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navigate to detailed view
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Monitor'),
        actions: [
          Consumer<MeshNetworkService>(
            builder: (context, meshService, _) {
              final sosCount = meshService.getSOSMessages().length;
              return Badge(
                label: Text('$sosCount'),
                isLabelVisible: sosCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // TODO: Add filtering options
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<MeshNetworkService>(
        builder: (context, meshService, _) {
          final sosMessages = meshService.getSOSMessages();
          
          if (sosMessages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active SOS Alerts',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connected to ${meshService.connectedPeersCount} peers',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sosMessages.length,
            itemBuilder: (context, index) {
              final message = sosMessages[sosMessages.length - 1 - index];
              return _SOSMessageCard(message: message);
            },
          );
        },
      ),
    );
  }
}

/// Card to display an individual SOS message
class _SOSMessageCard extends StatelessWidget {
  final MeshMessage message;
  
  const _SOSMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final payload = message.payload;
    final location = payload['location'] as Map<String, dynamic>?;
    final medicalInfo = payload['medicalInfo'] as Map<String, dynamic>?;
    final description = payload['description'] as String?;
    
    final timeAgo = _getTimeAgo(message.timestamp);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sos, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${message.hopCount} hops',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) ...[
                  const Text(
                    'Emergency Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Location
                if (location != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location: ${location['latitude']?.toStringAsFixed(6)}, ${location['longitude']?.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map, size: 20),
                        onPressed: () {
                          // TODO: Open in maps
                        },
                        tooltip: 'Open in maps',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Medical Info
                if (medicalInfo != null && medicalInfo.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Medical Information:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (medicalInfo['bloodType'] != null)
                        _MedicalChip(
                          label: 'Blood: ${medicalInfo['bloodType']}',
                          icon: Icons.bloodtype,
                        ),
                      if (medicalInfo['allergies'] != null)
                        _MedicalChip(
                          label: 'Allergies: ${medicalInfo['allergies']}',
                          icon: Icons.warning,
                        ),
                      if (medicalInfo['medications'] != null)
                        _MedicalChip(
                          label: 'Meds: ${medicalInfo['medications']}',
                          icon: Icons.medication,
                        ),
                      if (medicalInfo['chronicConditions'] != null)
                        _MedicalChip(
                          label: medicalInfo['chronicConditions'],
                          icon: Icons.medical_information,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Respond to SOS
                  },
                  icon: const Icon(Icons.reply),
                  label: const Text('Respond'),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Share/forward
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }
}

/// Chip to display medical information
class _MedicalChip extends StatelessWidget {
  final String label;
  final IconData icon;
  
  const _MedicalChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: Colors.red.shade50,
      side: BorderSide(color: Colors.red.shade200),
    );
  }
}
