import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_network_service.dart';
import 'package:geolocator/geolocator.dart';

/// SOS Emergency View with Mesh Network Broadcasting
class MeshSOSView extends StatefulWidget {
  const MeshSOSView({Key? key}) : super(key: key);

  @override
  State<MeshSOSView> createState() => _MeshSOSViewState();
}

class _MeshSOSViewState extends State<MeshSOSView> {
  final TextEditingController _descriptionController = TextEditingController();
  Position? _currentPosition;
  bool _isGettingLocation = false;
  bool _isSendingSOS = false;
  
  // Medical info
  String? _bloodType;
  String? _allergies;
  String? _medications;
  bool _hasChronicConditions = false;
  String? _chronicConditions;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location Services must be enabled!\n'
                'Required for: 1) Sharing your location in SOS\n'
                '2) Mesh network radios (Bluetooth) to work',
                style: TextStyle(fontSize: 13),
              ),
              duration: const Duration(seconds: 7),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: Geolocator.openLocationSettings,
              ),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
              ),
            );
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Please enable in settings.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _broadcastSOS() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the emergency')),
      );
      return;
    }

    setState(() => _isSendingSOS = true);

    try {
      final meshService = context.read<MeshNetworkService>();
      
      // Prepare medical info
      final medicalInfo = <String, dynamic>{};
      if (_bloodType != null) medicalInfo['bloodType'] = _bloodType;
      if (_allergies != null) medicalInfo['allergies'] = _allergies;
      if (_medications != null) medicalInfo['medications'] = _medications;
      if (_hasChronicConditions && _chronicConditions != null) {
        medicalInfo['chronicConditions'] = _chronicConditions;
      }

      // Prepare location
      Map<String, double>? location;
      if (_currentPosition != null) {
        location = {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        };
      }

      // Broadcast SOS
      await meshService.broadcastSOS(
        description: _descriptionController.text.trim(),
        location: location,
        medicalInfo: medicalInfo.isNotEmpty ? medicalInfo : null,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('SOS Broadcast'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your SOS has been broadcast to the mesh network!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Nearby devices: ${meshService.connectedPeersCount}'),
                const SizedBox(height: 8),
                const Text(
                  'The message will hop across devices to reach help, even without internet.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSendingSOS = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        actions: [
          Consumer<MeshNetworkService>(
            builder: (context, meshService, _) {
              return IconButton(
                icon: Badge(
                  label: Text('${meshService.connectedPeersCount}'),
                  isLabelVisible: meshService.connectedPeersCount > 0,
                  child: Icon(
                    meshService.isConnected 
                        ? Icons.wifi_tethering 
                        : Icons.wifi_tethering_off,
                    color: meshService.isConnected ? Colors.green : Colors.red,
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _MeshStatusDialog(),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Emergency Warning Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will broadcast an SOS to all nearby devices in the mesh network',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Emergency Description
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Emergency Description *',
                hintText: 'Describe what happened and what help you need...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.emergency),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Location Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _currentPosition != null 
                            ? Icons.location_on 
                            : Icons.location_off,
                        color: _currentPosition != null 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isGettingLocation
                              ? 'Getting your location...'
                              : _currentPosition != null
                                  ? 'Location: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                  : 'Location unavailable - Tap refresh to get location',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (!_isGettingLocation)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _getCurrentLocation,
                          tooltip: 'Refresh location',
                        ),
                    ],
                  ),
                  if (_currentPosition == null && !_isGettingLocation)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Location helps responders find you faster. Grant permission when prompted.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Medical Information Section
            ExpansionTile(
              title: const Text('Medical Information (Optional)'),
              subtitle: const Text('Help responders assist you better'),
              leading: const Icon(Icons.medical_information),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _bloodType,
                        decoration: const InputDecoration(
                          labelText: 'Blood Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _bloodType = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Allergies',
                          hintText: 'e.g., Penicillin, Peanuts',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _allergies = value,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Current Medications',
                          hintText: 'List any medications you\'re taking',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _medications = value,
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Chronic Medical Conditions'),
                        value: _hasChronicConditions,
                        onChanged: (value) {
                          setState(() => _hasChronicConditions = value ?? false);
                        },
                      ),
                      if (_hasChronicConditions)
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Describe Conditions',
                            hintText: 'e.g., Diabetes, Heart Disease',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _chronicConditions = value,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Broadcast SOS Button
            ElevatedButton.icon(
              onPressed: _isSendingSOS ? null : _broadcastSOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSendingSOS
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sos, size: 28),
              label: Text(
                _isSendingSOS ? 'Broadcasting...' : 'BROADCAST SOS',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Text
            const Text(
              'Your SOS will propagate through the mesh network via Bluetooth and Wi-Fi Direct, reaching devices even without cellular or internet connectivity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}

/// Mesh Status Dialog
class _MeshStatusDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MeshNetworkService>(
      builder: (context, meshService, _) {
        final status = meshService.status;
        
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_tethering, color: Colors.blue),
              SizedBox(width: 8),
              Text('Mesh Network Status'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusRow(
                  'Network Status',
                  status.isConnected ? 'Connected' : 'Disconnected',
                  status.isConnected ? Colors.green : Colors.red,
                ),
                const Divider(),
                _buildStatusRow(
                  'Connected Peers',
                  '${status.connectedPeers}',
                  Colors.blue,
                ),
                _buildStatusRow(
                  'Messages Sent',
                  '${status.messagesSent}',
                  Colors.orange,
                ),
                _buildStatusRow(
                  'Messages Received',
                  '${status.messagesReceived}',
                  Colors.green,
                ),
                _buildStatusRow(
                  'Messages Relayed',
                  '${status.messagesRelayed}',
                  Colors.purple,
                ),
                const Divider(),
                if (status.activePeers.isNotEmpty) ...[
                  const Text(
                    'Active Peers:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...status.activePeers.map((peer) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.device_hub, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(peer.deviceName)),
                          ],
                        ),
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
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
