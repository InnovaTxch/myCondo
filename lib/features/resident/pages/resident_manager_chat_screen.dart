import 'package:flutter/material.dart';
import 'package:mycondo/features/shared/pages/chat_screen.dart';
import 'package:mycondo/services/shared/chat_services.dart';

class ResidentManagerChatScreen extends StatefulWidget {
  const ResidentManagerChatScreen({super.key});

  @override
  State<ResidentManagerChatScreen> createState() =>
      _ResidentManagerChatScreenState();
}

class _ResidentManagerChatScreenState
    extends State<ResidentManagerChatScreen> {
  final _service = MessagingService();

  @override
  Widget build(BuildContext context) {
    final residentId = _service.currentUserId;
    if (residentId == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return FutureBuilder<({int conversationId, String managerName})>(
      future: _loadConversation(residentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Unable to open chat: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final conversation = snapshot.data!;
        return ChatScreen(
          name: conversation.managerName,
          conversationId: conversation.conversationId,
          showBackButton: false,
        );
      },
    );
  }

  Future<({int conversationId, String managerName})> _loadConversation(
    String residentId,
  ) async {
    final manager = await _service.fetchResidentManager(residentId);
    if (manager == null) {
      throw StateError('No manager found for this resident.');
    }

    final conversationId =
        await _service.getOrCreateResidentConversation(residentId);

    return (
      conversationId: conversationId,
      managerName: _displayName(manager),
    );
  }

  String _displayName(Map<String, dynamic> profile) {
    final firstName = (profile['first_name'] ?? '').toString().trim();
    final lastName = (profile['last_name'] ?? '').toString().trim();
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Manager' : name;
  }
}
