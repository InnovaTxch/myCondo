import 'package:flutter/material.dart';
import 'package:mycondo/services/shared/chat_services.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _service = MessagingService();

  Future<int> _getOrCreateConversation(String myId, String otherId) {
    return _service.getOrCreateConversation(myId, otherId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _service.currentUserId;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please Login")));
    }
    final myId = currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        title: const Text('Messages',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Urbanist')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.fetchOtherUsers(myId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final String name =
                  "${user['first_name'] ?? 'User'} ${user['last_name'] ?? ''}";

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF4A90D9),
                  child: Text((user['first_name'] ?? "U")[0],
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.w600)),
                subtitle: Text(user['role'] ?? 'resident',
                    style: const TextStyle(fontFamily: 'Urbanist')),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (res) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final id =
                        await _getOrCreateConversation(myId, user['id']);
                    if (!mounted) return;
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(name: name, conversationId: id),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}