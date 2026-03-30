import 'package:flutter/material.dart';
import '../services/mesh_service.dart';

class MeshChatPage extends StatefulWidget {
  const MeshChatPage({super.key});

  @override
  State<MeshChatPage> createState() => _MeshChatPageState();
}

class _MeshChatPageState extends State<MeshChatPage> {
  final mesh = MeshService();
  final TextEditingController controller = TextEditingController();
  List<String> messages = [];

  @override
  void initState() {
  super.initState();

  mesh.onMessageReceived = (msg) {
    print("📥 CHAT PAGE RECEIVED: $msg");

    setState(() {
      messages.add("Peer: $msg");
    });
  };
}
  @override
  void dispose() {
    mesh.onMessageReceived = null; // 🔥 IMPORTANT
    super.dispose();
  }

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    mesh.sendMessage(text);

    setState(() {
      messages.add("You: $text");
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mesh Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(messages[i]),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Send message...",
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: send,
              )
            ],
          )
        ],
      ),
    );
  }
}