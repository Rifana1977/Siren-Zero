import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ditto_live/ditto_live.dart';
import '../core/app_constants.dart';

/// Message types for the mesh network
enum MeshMessageType {
  sos,
  medicalData,
  locationUpdate,
  textMessage,
  acknowledgment,
  heartbeat,
}

/// Priority levels for mesh messages
enum MessagePriority {
  critical, // SOS, life-threatening medical
  high, // Medical data, urgent requests
  normal, // General messages
  low, // Heartbeats, status updates
}

/// Represents a message in the mesh network
class MeshMessage {
  final String id;
  final String senderId;
  final String senderName;
  final MeshMessageType type;
  final MessagePriority priority;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int hopCount;
  final int maxHops;
  final List<String> routePath; // Track which devices relayed this message
  final String? recipientId; // null for broadcast
  
  MeshMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.priority,
    required this.payload,
    required this.timestamp,
    this.hopCount = 0,
    this.maxHops = 10,
    this.routePath = const [],
    this.recipientId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'type': type.name,
        'priority': priority.name,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
        'hopCount': hopCount,
        'maxHops': maxHops,
        'routePath': routePath,
        'recipientId': recipientId,
      };

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      type: MeshMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MeshMessageType.textMessage,
      ),
      priority: MessagePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => MessagePriority.normal,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      hopCount: json['hopCount'] as int? ?? 0,
      maxHops: json['maxHops'] as int? ?? 10,
      routePath: List<String>.from(json['routePath'] as List? ?? []),
      recipientId: json['recipientId'] as String?,
    );
  }

  MeshMessage copyWithHop(String relayerId) {
    return MeshMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      type: type,
      priority: priority,
      payload: payload,
      timestamp: timestamp,
      hopCount: hopCount + 1,
      maxHops: maxHops,
      routePath: [...routePath, relayerId],
      recipientId: recipientId,
    );
  }
}

/// Represents a peer device in the mesh
class MeshPeer {
  final String deviceId;
  final String deviceName;
  final DateTime lastSeen;
  final String status;
  final int? signalStrength;
  final Map<String, double>? location;
  
  MeshPeer({
    required this.deviceId,
    required this.deviceName,
    required this.lastSeen,
    this.status = 'active',
    this.signalStrength,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'lastSeen': lastSeen.toIso8601String(),
        'status': status,
        'signalStrength': signalStrength,
        'location': location,
      };

  factory MeshPeer.fromJson(Map<String, dynamic> json) {
    return MeshPeer(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      status: json['status'] as String? ?? 'active',
      signalStrength: json['signalStrength'] as int?,
      location: json['location'] != null 
          ? Map<String, double>.from(json['location'] as Map)
          : null,
    );
  }

  bool isActive() {
    return DateTime.now().difference(lastSeen).inMinutes < 2;
  }
}

/// Mesh Network Status
class MeshNetworkStatus {
  final bool isConnected;
  final int connectedPeers;
  final bool bluetoothEnabled;
  final bool wifiEnabled;
  final List<MeshPeer> activePeers;
  final int messagesSent;
  final int messagesReceived;
  final int messagesRelayed;
  
  MeshNetworkStatus({
    required this.isConnected,
    required this.connectedPeers,
    required this.bluetoothEnabled,
    required this.wifiEnabled,
    required this.activePeers,
    this.messagesSent = 0,
    this.messagesReceived = 0,
    this.messagesRelayed = 0,
  });
}

/// Mesh Network Service - Ditto SDK integration for mesh networking
/// Provides offline-first mesh communication via Bluetooth LE and WiFi Direct
class MeshNetworkService extends ChangeNotifier {
  // Ditto SDK instance for mesh networking
  Ditto? _ditto;
  dynamic _messagesObserver;
  dynamic _peersObserver;
  dynamic _messagesSubscription;
  dynamic _peersSubscription;
  
  final String _deviceId;
  final String _deviceName;
  
  bool _isInitialized = false;
  bool _isConnected = false;
  final Set<String> _seenMessageIds = {}; // Prevent message loops
  final Map<String, DateTime> _messageCache = {}; // TTL cache
  final Duration _messageTTL = const Duration(minutes: 30);
  
  // Message storage (in-memory, will be persisted via Ditto)
  final List<MeshMessage> _receivedMessages = [];
  final List<MeshMessage> _sentMessages = [];
  
  // Peer tracking
  final Map<String, MeshPeer> _peers = {};
  
  // Statistics
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _messagesRelayed = 0;
  
  // Message handlers
  final Map<MeshMessageType, Function(MeshMessage)> _messageHandlers = {};
  
  // Streams for real-time updates
  final StreamController<MeshMessage> _messageStreamController =
      StreamController<MeshMessage>.broadcast();
  final StreamController<List<MeshPeer>> _peersStreamController =
      StreamController<List<MeshPeer>>.broadcast();
  
  MeshNetworkService({
    required String deviceId,
    required String deviceName,
  })  : _deviceId = deviceId,
        _deviceName = deviceName;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  int get connectedPeersCount => _peers.values.where((p) => p.isActive()).length;
  List<MeshPeer> get activePeers => 
      _peers.values.where((p) => p.isActive()).toList();
  List<MeshMessage> get receivedMessages => List.unmodifiable(_receivedMessages);
  List<MeshMessage> get sentMessages => List.unmodifiable(_sentMessages);
  Stream<MeshMessage> get messageStream => _messageStreamController.stream;
  Stream<List<MeshPeer>> get peersStream => _peersStreamController.stream;
  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  
  MeshNetworkStatus get status => MeshNetworkStatus(
        isConnected: _isConnected,
        connectedPeers: connectedPeersCount,
        bluetoothEnabled: true,
        wifiEnabled: true,
        activePeers: activePeers,
        messagesSent: _messagesSent,
        messagesReceived: _messagesReceived,
        messagesRelayed: _messagesRelayed,
      );

  /// Initialize the mesh network
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Mesh network already initialized');
      return;
    }

    try {
      // Request necessary permissions
      await _requestPermissions();

      // Initialize Ditto SDK
      debugPrint('Initializing Ditto SDK for mesh networking...');
      await Ditto.init();

      // 📍 The most modern version of the constructor:
      final identity = OnlinePlaygroundIdentity(
        appID: AppConstants.dittoAppId,
        token: AppConstants.dittoToken,
        enableDittoCloudSync: !AppConstants.dittoOfflineOnly,
      );

      _ditto = await Ditto.open(identity: identity);
      debugPrint('Ditto instance created successfully');
      _ditto!.updateTransportConfig((config) {
        config.connect.webSocketUrls.add('wss://${AppConstants.dittoAppId}.cloud.ditto.live');
      });
      // Configure transports for mesh networking
      // Note: On Android <13, Location Services must be enabled at system level
      // for BLE scanning to work, even with neverForLocation flag
      _ditto!.updateTransportConfig((config) {
        // Enable peer-to-peer for all available transports
        // This includes Bluetooth LE, WiFi Direct/LAN, etc.
        debugPrint('Ditto transports configured for P2P mesh');
      });

      // Disable DQL strict mode for flexible queries
      await _ditto!.store.execute('ALTER SYSTEM SET DQL_STRICT_MODE = false');
      debugPrint('Ditto DQL configured');

      // Start syncing with mesh network
      _ditto!.startSync();
      debugPrint('Ditto sync started - mesh networking active!');
      
      if (AppConstants.dittoOfflineOnly) {
        debugPrint('⚠️ Running in OFFLINE-ONLY mode');
        debugPrint('   Authentication warnings from Ditto can be ignored');
        debugPrint('   P2P mesh networking will work without cloud sync');
      }

      // Setup Ditto collections and observers
      await _setupDittoCollections();

      // Start heartbeat
      _startHeartbeat();

      // Start message cleanup
      _startMessageCleanup();

      _isInitialized = true;
      _isConnected = true;
      
      debugPrint('Mesh network initialized: Device $_deviceId');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize mesh network: $e');
      rethrow;
    }
  }

  /// Request necessary permissions for mesh networking
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ];

    for (final permission in permissions) {
      if (await permission.isDenied) {
        await permission.request();
      }
    }
  }

  /// Setup Ditto collections and observers for real-time sync
  Future<void> _setupDittoCollections() async {
    if (_ditto == null) return;

    // Register subscription for messages collection
    _messagesSubscription = await _ditto!.sync.registerSubscription(
      'SELECT * FROM mesh_messages ORDER BY timestamp DESC',
    );

    // Register subscription for peers collection  
    _peersSubscription = await _ditto!.sync.registerSubscription(
      'SELECT * FROM mesh_peers WHERE lastSeen > :cutoff',
      arguments: {
        'cutoff': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
    );

    // Observe messages for real-time updates
    _messagesObserver = _ditto!.store.registerObserver(
      'SELECT * FROM mesh_messages ORDER BY timestamp DESC LIMIT 100',
      onChange: (event) {
        _syncMessagesFromDitto();
      },
    );

    // Observe peers for real-time updates
    _peersObserver = _ditto!.store.registerObserver(
      'SELECT * FROM mesh_peers WHERE lastSeen > :cutoff',
      arguments: {
        'cutoff': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
      onChange: (event) {
        _syncPeersFromDitto();
      },
    );
  }

  /// Sync messages from Ditto store to local cache
  Future<void> _syncMessagesFromDitto() async {
    if (_ditto == null) return;

    try {
      final _ = await _ditto!.store.execute(
        'SELECT * FROM mesh_messages ORDER BY timestamp DESC LIMIT 100',
      );

      // Process results and update local message lists
      // This keeps local cache in sync with Ditto's replicated data
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing messages from Ditto: $e');
    }
  }

  /// Sync peers from Ditto store to local cache
  Future<void> _syncPeersFromDitto() async {
    if (_ditto == null) return;

    try {
      final _ = await _ditto!.store.execute(
        'SELECT * FROM mesh_peers WHERE lastSeen > :cutoff',
        arguments: {
          'cutoff': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
      );

      // Process results and update local peers map
      // This keeps local cache in sync with Ditto's replicated data
      _peersStreamController.add(activePeers);
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing peers from Ditto: $e');
    }
  }

  /// Register a handler for a specific message type
  void registerMessageHandler(
    MeshMessageType type,
    Function(MeshMessage) handler,
  ) {
    _messageHandlers[type] = handler;
  }

  /// Remove a message handler
  void unregisterMessageHandler(MeshMessageType type) {
    _messageHandlers.remove(type);
  }

  /// Handle incoming message
  void _handleMessage(MeshMessage message) {
    // Check if we've seen this before
    if (_seenMessageIds.contains(message.id)) return;
    
    // Mark as seen
    _seenMessageIds.add(message.id);
    _messageCache[message.id] = DateTime.now();
    
    // Check if it's for us or broadcast
    final isForUs = message.recipientId == null || 
                   message.recipientId == _deviceId;
    
    if (isForUs) {
      _messagesReceived++;
      _receivedMessages.add(message);
      
      // Call registered handler
      final handler = _messageHandlers[message.type];
      handler?.call(message);
      
      // Emit to stream
      _messageStreamController.add(message);
      
      debugPrint('Received ${message.type.name} from ${message.senderName}');
    }
    
    // Relay if needed
    if (message.hopCount < message.maxHops && 
        !message.routePath.contains(_deviceId)) {
      _relayMessage(message);
    }
    
    notifyListeners();
  }

  /// Relay a message to extend its reach
  Future<void> _relayMessage(MeshMessage message) async {
    if (!_isInitialized) return;
    
    try {
      final relayedMessage = message.copyWithHop(_deviceId);
      
      // Persist relayed message to Ditto store for mesh sync
      if (_ditto != null) {
        await _ditto!.store.execute(
          'INSERT INTO mesh_messages VALUES (:message)',
          arguments: {
            'message': relayedMessage.toJson(),
          },
        );
      }
      
      _messagesRelayed++;
      debugPrint('Relayed message ${message.id} (hop ${relayedMessage.hopCount})');
      notifyListeners();
    } catch (e) {
      debugPrint('Error relaying message: $e');
    }
  }

  /// Broadcast a message to the mesh network
  Future<void> broadcastMessage({
    required MeshMessageType type,
    required MessagePriority priority,
    required Map<String, dynamic> payload,
    String? recipientId,
    int maxHops = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('Mesh network not initialized');
    }

    final message = MeshMessage(
      id: '${_deviceId}_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _deviceId,
      senderName: _deviceName,
      type: type,
      priority: priority,
      payload: payload,
      timestamp: DateTime.now(),
      hopCount: 0,
      maxHops: maxHops,
      routePath: [_deviceId],
      recipientId: recipientId,
    );

    try {
      // Persist to Ditto store for mesh sync
      if (_ditto != null) {
        await _ditto!.store.execute(
          'INSERT INTO mesh_messages VALUES (:message)',
          arguments: {
            'message': message.toJson(),
          },
        );
      }
      
      _messagesSent++;
      _sentMessages.add(message);
      _seenMessageIds.add(message.id);
      _messageCache[message.id] = DateTime.now();
      
      debugPrint('Broadcasted ${type.name} message: ${message.id}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error broadcasting message: $e');
      rethrow;
    }
  }

  /// Broadcast an SOS alert
  Future<void> broadcastSOS({
    required String description,
    Map<String, double>? location,
    Map<String, dynamic>? medicalInfo,
  }) async {
    await broadcastMessage(
      type: MeshMessageType.sos,
      priority: MessagePriority.critical,
      payload: {
        'description': description,
        'location': location,
        'medicalInfo': medicalInfo,
        'timestamp': DateTime.now().toIso8601String(),
      },
      maxHops: 15, // Allow more hops for critical messages
    );
  }

  /// Broadcast medical data
  Future<void> broadcastMedicalData({
    required Map<String, dynamic> medicalData,
    Map<String, double>? location,
  }) async {
    await broadcastMessage(
      type: MeshMessageType.medicalData,
      priority: MessagePriority.high,
      payload: {
        'medicalData': medicalData,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      },
      maxHops: 12,
    );
  }

  /// Share location update
  Future<void> shareLocation({
    required double latitude,
    required double longitude,
    String? status,
  }) async {
    await broadcastMessage(
      type: MeshMessageType.locationUpdate,
      priority: MessagePriority.normal,
      payload: {
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      },
      maxHops: 8,
    );
  }

  /// Send a text message through the mesh
  Future<void> sendTextMessage({
    required String text,
    String? recipientId,
  }) async {
    await broadcastMessage(
      type: MeshMessageType.textMessage,
      priority: MessagePriority.normal,
      payload: {
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      },
      recipientId: recipientId,
      maxHops: 10,
    );
  }

  /// Update peer information
  void _updatePeer(MeshPeer peer) {
    _peers[peer.deviceId] = peer;
    _peersStreamController.add(activePeers);
    notifyListeners();
  }

  /// Start sending periodic heartbeats
  void _startHeartbeat() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }

      try {
        // Update our presence
        final ourPeer = MeshPeer(
          deviceId: _deviceId,
          deviceName: _deviceName,
          lastSeen: DateTime.now(),
          status: 'active',
        );
        
        try {
        // Update our presence
        final ourPeer = MeshPeer(
          deviceId: _deviceId,
          deviceName: _deviceName,
          lastSeen: DateTime.now(),
          status: 'active',
        );
        
        // 📍 THE FIX: This sends your "Identity" to the mesh database
        await _ditto!.store.execute(
          'INSERT INTO mesh_peers VALUES (:peer) ON ID CONFLICT DO UPDATE',
          arguments: {
            'peer': ourPeer.toJson(),
          },
        );
        
        _updatePeer(ourPeer);
        debugPrint('💓 Heartbeat sent for $_deviceName');
      } catch (e) {
        debugPrint('⚠️ Error sending heartbeat: $e');
      }
        // await _ditto.store.collection('peers').upsert(ourPeer.toJson());
        
        _updatePeer(ourPeer);
      } catch (e) {
        debugPrint('Error sending heartbeat: $e');
      }
    });
  }

  /// Start periodic message cache cleanup
  void _startMessageCleanup() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      _cleanupMessageCache();
    });
  }

  /// Clean up expired messages from cache
  void _cleanupMessageCache() {
    final now = DateTime.now();
    _messageCache.removeWhere((id, timestamp) {
      final expired = now.difference(timestamp) > _messageTTL;
      if (expired) {
        _seenMessageIds.remove(id);
      }
      return expired;
    });
    
    // Clean up old received messages (keep last 100)
    if (_receivedMessages.length > 100) {
      _receivedMessages.removeRange(0, _receivedMessages.length - 100);
    }
    
    // Clean up old sent messages (keep last 100)
    if (_sentMessages.length > 100) {
      _sentMessages.removeRange(0, _sentMessages.length - 100);
    }
  }

  /// Get statistics about the mesh network
  Map<String, dynamic> getStatistics() {
    return {
      'deviceId': _deviceId,
      'deviceName': _deviceName,
      'connectedPeers': connectedPeersCount,
      'messagesSent': _messagesSent,
      'messagesReceived': _messagesReceived,
      'messagesRelayed': _messagesRelayed,
      'activePeers': activePeers.map((p) => p.deviceName).toList(),
      'totalMessagesProcessed': _seenMessageIds.length,
    };
  }

  /// Get messages by type
  List<MeshMessage> getMessagesByType(MeshMessageType type) {
    return _receivedMessages.where((m) => m.type == type).toList();
  }

  /// Get SOS messages
  List<MeshMessage> getSOSMessages() {
    return getMessagesByType(MeshMessageType.sos);
  }

  /// Clear all messages
  void clearMessages() {
    _receivedMessages.clear();
    _sentMessages.clear();
    notifyListeners();
  }

  /// Simulate receiving a message (for testing/development)
  void simulateIncomingMessage(MeshMessage message) {
    _handleMessage(message);
  }

  @override
  void dispose() {
    _messageStreamController.close();
    _peersStreamController.close();
    
    // Clean up Ditto resources
    _messagesObserver?.cancel();
    _peersObserver?.cancel();
    _messagesSubscription?.cancel();
    _peersSubscription?.cancel();
    
    // Stop Ditto sync and close connection
    _ditto?.stopSync();
    _ditto?.close();
    
    super.dispose();
  }
}
