import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_network_service.dart';

/// Widget showing mesh network connection status
class MeshNetworkStatusWidget extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onTap;
  
  const MeshNetworkStatusWidget({
    Key? key,
    this.showDetails = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshNetworkService>(
      builder: (context, meshService, _) {
        final status = meshService.status;
        
        if (!showDetails) {
          // Compact view - just an indicator
          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status.isConnected ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: status.isConnected ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status.isConnected 
                        ? Icons.wifi_tethering 
                        : Icons.wifi_tethering_off,
                    color: status.isConnected ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${status.connectedPeers} peers',
                    style: TextStyle(
                      color: status.isConnected ? Colors.green.shade900 : Colors.red.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Detailed view
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      status.isConnected 
                          ? Icons.wifi_tethering 
                          : Icons.wifi_tethering_off,
                      color: status.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mesh Network',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            status.isConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: status.isConnected ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatRow('Connected Peers', '${status.connectedPeers}'),
                _buildStatRow('Messages Sent', '${status.messagesSent}'),
                _buildStatRow('Messages Received', '${status.messagesReceived}'),
                _buildStatRow('Messages Relayed', '${status.messagesRelayed}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Action Button for quick SOS broadcast
class QuickSOSButton extends StatefulWidget {
  const QuickSOSButton({Key? key}) : super(key: key);

  @override
  State<QuickSOSButton> createState() => _QuickSOSButtonState();
}

class _QuickSOSButtonState extends State<QuickSOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;
  double _holdProgress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {
          _holdProgress = _controller.value;
          if (_holdProgress >= 1.0 && _isHolding) {
            _triggerSOS();
          }
        });
      });
  }

  void _triggerSOS() async {
    _controller.reset();
    setState(() => _isHolding = false);
    
    final meshService = context.read<MeshNetworkService>();
    
    try {
      // Quick SOS without details
      await meshService.broadcastSOS(
        description: 'Emergency! Need immediate assistance!',
        location: null, // Will need to get location
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('SOS Broadcast to ${meshService.connectedPeersCount} peers'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send SOS: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() => _isHolding = true);
        _controller.forward();
      },
      onLongPressEnd: (_) {
        setState(() => _isHolding = false);
        _controller.reset();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring
          if (_isHolding)
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: _holdProgress,
                strokeWidth: 4,
                backgroundColor: Colors.red.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
          // Main button
          FloatingActionButton(
            onPressed: () {
              // Navigate to full SOS view
              Navigator.pushNamed(context, '/mesh-sos');
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.sos, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Banner showing incoming SOS alerts
class SOSAlertBanner extends StatelessWidget {
  const SOSAlertBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshNetworkService>(
      builder: (context, meshService, _) {
        final sosMessages = meshService.getSOSMessages();
        
        if (sosMessages.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final latestSOS = sosMessages.last;
        final timeAgo = DateTime.now().difference(latestSOS.timestamp);
        
        // Only show if recent (last 5 minutes)
        if (timeAgo.inMinutes > 5) {
          return const SizedBox.shrink();
        }
        
        return Material(
          color: Colors.red,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/mesh-sos-monitor');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.sos, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'NEW SOS ALERT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'From ${latestSOS.senderName} • ${timeAgo.inMinutes}m ago',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Badge showing unread SOS count
class SOSBadge extends StatelessWidget {
  final Widget child;
  
  const SOSBadge({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshNetworkService>(
      builder: (context, meshService, _) {
        final sosCount = meshService.getSOSMessages().length;
        
        return Badge(
          label: Text('$sosCount'),
          isLabelVisible: sosCount > 0,
          backgroundColor: Colors.red,
          child: child,
        );
      },
    );
  }
}
