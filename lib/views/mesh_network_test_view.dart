import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_network_service.dart';
import '../widgets/mesh_network_widgets.dart';

/// Demo/Test view for mesh networking features
/// Use this to test mesh functionality without full app integration
class MeshNetworkTestView extends StatefulWidget {
  const MeshNetworkTestView({super.key});

  @override
  State<MeshNetworkTestView> createState() => _MeshNetworkTestViewState();
}

class _MeshNetworkTestViewState extends State<MeshNetworkTestView> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    final meshService = context.read<MeshNetworkService>();
    
    // Listen to all incoming messages
    meshService.messageStream.listen((message) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New ${message.type.name} from ${message.senderName}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _sendTestSOS() async {
    final meshService = context.read<MeshNetworkService>();
    
    try {
      await meshService.broadcastSOS(
        description: 'TEST: This is a test SOS message',
        location: {
          'latitude': 37.7749,
          'longitude': -122.4194,
        },
        medicalInfo: {
          'bloodType': 'O+',
          'allergies': 'None',
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test SOS sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _simulateIncomingSOS() {
    final meshService = context.read<MeshNetworkService>();
    
    meshService.simulateIncomingMessage(
      MeshMessage(
        id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'test_sender',
        senderName: 'Test User',
        type: MeshMessageType.sos,
        priority: MessagePriority.critical,
        payload: {
          'description': 'SIMULATED: Heart attack, need immediate help!',
          'location': {
            'latitude': 37.7749,
            'longitude': -122.4194,
          },
          'medicalInfo': {
            'bloodType': 'A+',
            'allergies': 'Penicillin',
            'medications': 'Aspirin',
          },
        },
        timestamp: DateTime.now(),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📥 Simulated SOS received!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final meshService = context.read<MeshNetworkService>();
    
    try {
      await meshService.sendTextMessage(
        text: _messageController.text.trim(),
      );
      
      _messageController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Message sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatistics() {
    final meshService = context.read<MeshNetworkService>();
    final stats = meshService.getStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesh Network Statistics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Device ID', stats['deviceId']),
              _buildStatRow('Device Name', stats['deviceName']),
              const Divider(),
              _buildStatRow('Connected Peers', '${stats['connectedPeers']}'),
              _buildStatRow('Messages Sent', '${stats['messagesSent']}'),
              _buildStatRow('Messages Received', '${stats['messagesReceived']}'),
              _buildStatRow('Messages Relayed', '${stats['messagesRelayed']}'),
              _buildStatRow('Total Processed', '${stats['totalMessagesProcessed']}'),
              const Divider(),
              if (stats['activePeers'] is List && (stats['activePeers'] as List).isNotEmpty) ...[
                const Text(
                  'Active Peers:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(stats['activePeers'] as List).map((peer) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text('• $peer'),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesh Network Test'),
        actions: [
          MeshNetworkStatusWidget(
            onTap: _showStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showStatistics,
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mesh Status Card
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: MeshNetworkStatusWidget(showDetails: true),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Buttons
            const Text(
              'Test Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _sendTestSOS,
              icon: const Icon(Icons.sos),
              label: const Text('Send Test SOS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _simulateIncomingSOS,
              icon: const Icon(Icons.inbox),
              label: const Text('Simulate Incoming SOS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/mesh-sos'),
              icon: const Icon(Icons.emergency),
              label: const Text('Open SOS Broadcast View'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/mesh-sos-monitor'),
              icon: const Icon(Icons.monitor_heart),
              label: const Text('Open SOS Monitor View'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Text Message Test
            const Text(
              'Send Text Message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendTextMessage,
                ),
              ),
              onSubmitted: (_) => _sendTextMessage(),
            ),
            
            const SizedBox(height: 24),
            
            // Message History
            const Text(
              'Recent Messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Consumer<MeshNetworkService>(
              builder: (context, meshService, _) {
                final messages = meshService.receivedMessages;
                
                if (messages.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No messages received yet'),
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: messages.reversed.take(5).map((message) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _getIconForMessageType(message.type),
                          color: _getColorForMessageType(message.type),
                        ),
                        title: Text(message.senderName),
                        subtitle: Text(
                          message.type.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${message.hopCount} hops',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMessageType(MeshMessageType type) {
    switch (type) {
      case MeshMessageType.sos:
        return Icons.sos;
      case MeshMessageType.medicalData:
        return Icons.medical_information;
      case MeshMessageType.locationUpdate:
        return Icons.location_on;
      case MeshMessageType.textMessage:
        return Icons.message;
      case MeshMessageType.acknowledgment:
        return Icons.check_circle;
      case MeshMessageType.heartbeat:
        return Icons.favorite;
    }
  }

  Color _getColorForMessageType(MeshMessageType type) {
    switch (type) {
      case MeshMessageType.sos:
        return Colors.red;
      case MeshMessageType.medicalData:
        return Colors.orange;
      case MeshMessageType.locationUpdate:
        return Colors.blue;
      case MeshMessageType.textMessage:
        return Colors.green;
      case MeshMessageType.acknowledgment:
        return Colors.teal;
      case MeshMessageType.heartbeat:
        return Colors.pink;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
