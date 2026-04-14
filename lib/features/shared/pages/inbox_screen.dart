import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final supabase = Supabase.instance.client;

  Future<int> _getOrCreateConversation(String myId, String otherId) async {
    try {
      // 1. Try to find existing conversation first
      final existing = await supabase
          .from('conversations')
          .select('id')
          .or('and(manager_id.eq.$myId,resident_id.eq.$otherId),and(manager_id.eq.$otherId,resident_id.eq.$myId)')
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as int;
      }

      // 2. If not found, create new (wrapped in try/catch for unique constraint safety)
      final newConvo = await supabase
          .from('conversations')
          .insert({
            'manager_id': myId,
            'resident_id': otherId,
          })
          .select('id')
          .single();

      return newConvo['id'] as int;
    } catch (e) {
      // 3. Fallback if insert failed due to a race condition/unique constraint
      final fallback = await supabase
          .from('conversations')
          .select('id')
          .or('and(manager_id.eq.$myId,resident_id.eq.$otherId),and(manager_id.eq.$otherId,resident_id.eq.$myId)')
          .limit(1)
          .single();
      return fallback['id'] as int;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Please Login")));
    final myId = currentUser.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        title: const Text('Messages', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Urbanist')
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('profiles').select('id, first_name, last_name, role').neq('id', myId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final String name = "${user['first_name'] ?? 'User'} ${user['last_name'] ?? ''}";

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF4A90D9),
                  child: Text((user['first_name'] ?? "U")[0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text(name, style: const TextStyle(fontFamily: 'Urbanist', fontWeight: FontWeight.w600)),
                subtitle: Text(user['role'] ?? 'resident', style: const TextStyle(fontFamily: 'Urbanist')),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (res) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final id = await _getOrCreateConversation(myId, user['id']);
                    if (!mounted) return;
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(name: name, conversationId: id),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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