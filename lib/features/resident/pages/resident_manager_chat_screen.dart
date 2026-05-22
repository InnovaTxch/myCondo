import 'package:flutter/material.dart';
import 'package:mycondo/features/shared/pages/chat_screen.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/services/shared/chat_services.dart';
import 'package:mycondo/utils/user_friendly_error.dart';

class ResidentManagerChatScreen extends StatefulWidget {
  const ResidentManagerChatScreen({super.key});

  @override
  State<ResidentManagerChatScreen> createState() =>
      _ResidentManagerChatScreenState();
}

class _ResidentManagerChatScreenState extends State<ResidentManagerChatScreen> {
  final _service = MessagingService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
      ({int conversationId, String managerId, String managerName})
    >(
      future: _loadConversation(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            '[ResidentManagerChatScreen.loadConversation] ${snapshot.error}\n${snapshot.stackTrace ?? ''}',
          );
          return Scaffold(
            body: AppErrorState(
              message: UserFriendlyError.messageFor(
                snapshot.error!,
                fallback: 'Unable to open chat. Please try again.',
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: AppLoadingState());
        }

        final conversation = snapshot.data!;
        return ChatScreen(
          name: conversation.managerName,
          conversationId: conversation.conversationId,
          otherProfileId: conversation.managerId,
          showBackButton: false,
        );
      },
    );
  }

  Future<({int conversationId, String managerId, String managerName})>
  _loadConversation() async {
    final residentId = await _service.currentProfileId;
    if (residentId == null) {
      throw StateError('Please log in.');
    }

    final manager = await _service.fetchResidentManager(residentId);
    if (manager == null) {
      throw StateError('No manager found for this resident.');
    }

    final conversationId = await _service.getOrCreateResidentConversation(
      residentId,
    );

    return (
      conversationId: conversationId,
      managerId: manager['id'].toString(),
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
