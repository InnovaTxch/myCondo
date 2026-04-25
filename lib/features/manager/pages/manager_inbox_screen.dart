import 'package:flutter/material.dart';
import 'package:mycondo/features/shared/pages/chat_screen.dart';
import 'package:mycondo/services/shared/chat_services.dart';

class ManagerInboxScreen extends StatefulWidget {
  const ManagerInboxScreen({super.key});

  @override
  State<ManagerInboxScreen> createState() => _ManagerInboxScreenState();
}

class _ManagerInboxScreenState extends State<ManagerInboxScreen> {
  final _service = MessagingService();

  @override
  Widget build(BuildContext context) {
    final managerId = _service.currentUserId;
    if (managerId == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Urbanist',
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.fetchResidentsForManager(managerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final residents = snapshot.data!;
          if (residents.isEmpty) {
            return const Center(child: Text('No residents available.'));
          }

          return ListView.builder(
            itemCount: residents.length,
            itemBuilder: (context, index) {
              final resident = residents[index];
              final residentId = resident['id'].toString();
              final name = _displayName(resident);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF4A90D9),
                  child: Text(
                    _initial(name),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Resident',
                  style: TextStyle(fontFamily: 'Urbanist'),
                ),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () => _openChat(
                  residentId: residentId,
                  residentName: name,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openChat({
    required String residentId,
    required String residentName,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final conversationId =
          await _service.getOrCreateResidentConversation(residentId);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            name: residentName,
            conversationId: conversationId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _displayName(Map<String, dynamic> profile) {
    final firstName = (profile['first_name'] ?? '').toString().trim();
    final lastName = (profile['last_name'] ?? '').toString().trim();
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Resident' : name;
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'R';
    return trimmed[0].toUpperCase();
  }
}
