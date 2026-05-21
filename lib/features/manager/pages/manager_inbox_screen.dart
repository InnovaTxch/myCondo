import 'package:flutter/material.dart';
import 'package:mycondo/features/shared/pages/chat_screen.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/features/shared/widgets/app_page.dart';
import 'package:mycondo/services/shared/chat_services.dart';
import 'package:mycondo/services/shared/presence_service.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class ManagerInboxScreen extends StatefulWidget {
  const ManagerInboxScreen({super.key});

  @override
  State<ManagerInboxScreen> createState() => _ManagerInboxScreenState();
}

class _ManagerInboxScreenState extends State<ManagerInboxScreen> {
  final _service = MessagingService();
  late final void Function(Set<String>) _presenceListener;
  Set<String> _onlineResidentIds = const <String>{};
  Future<List<Map<String, dynamic>>>? _residentsFuture;
  String? _managerId;
  bool _isLoadingProfile = true;
  String _searchQuery = '';

  // Blue color palette (consistent with chat_screen.dart)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color softBlue = Color(0xFFEFF6FF);
  static const Color midBlue = Color(0xFFBFDBFE);
  static const Color bgColor = Color(0xFFF0F4FF);

  @override
  void initState() {
    super.initState();
    _presenceListener = (onlineProfileIds) {
      if (!mounted) return;
      setState(() => _onlineResidentIds = onlineProfileIds);
    };
    presenceService.addListener(_presenceListener);
    presenceService.start();
    _loadManagerProfile();
  }

  @override
  void dispose() {
    presenceService.removeListener(_presenceListener);
    super.dispose();
  }

  Future<void> _loadManagerProfile() async {
    final managerId = await _service.currentProfileId;
    if (!mounted) return;
    if (managerId != null) {
      _residentsFuture = _service.fetchResidentsForManager(managerId);
    }
    setState(() {
      _managerId = managerId;
      _isLoadingProfile = false;
    });
  }

  Future<void> _refreshResidents() async {
    final managerId = _managerId;
    if (managerId == null) return;
    final future = _service.fetchResidentsForManager(managerId);
    setState(() => _residentsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const AppPageScaffold(
        backgroundColor: bgColor,
        body: AppLoadingState(color: primaryBlue, strokeWidth: 2),
      );
    }

    final managerId = _managerId;
    if (managerId == null) {
      return const AppPageScaffold(
        backgroundColor: bgColor,
        body: AppEmptyState(
          icon: Icons.login_rounded,
          title: 'Please log in',
          message: 'Sign in to view resident messages.',
          card: false,
        ),
      );
    }

    return AppPageScaffold(
      backgroundColor: bgColor,
      onRefresh: _refreshResidents,
      refreshIndicatorColor: primaryBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildSectionLabel(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future:
                  _residentsFuture ?? _service.fetchResidentsForManager(managerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AppScrollableCentered(
                    heightFactor: 0.5,
                    child: AppErrorState(
                      message: 'Unable to load residents. Try again.',
                      details: '${snapshot.error}',
                      onRetry: _refreshResidents,
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const AppScrollableCentered(
                    heightFactor: 0.5,
                    child: AppLoadingState(
                      color: primaryBlue,
                      strokeWidth: 2,
                    ),
                  );
                }

                final residents = snapshot.data!;
                final filtered = _searchQuery.isEmpty
                    ? residents
                    : residents.where((r) {
                        final name = _displayName(r).toLowerCase();
                        return name.contains(_searchQuery.toLowerCase());
                      }).toList();

                if (filtered.isEmpty) {
                  return AppScrollableCentered(
                    heightFactor: 0.5,
                    child: AppEmptyState(
                      icon: Icons.inbox_outlined,
                      title: _searchQuery.isNotEmpty ? 'No results' : 'No residents',
                      message: _searchQuery.isNotEmpty
                          ? 'No residents match your search.'
                          : 'No residents available.',
                      card: false,
                    ),
                  );
                }

                return StreamBuilder<Set<String>>(
                  stream: _service.managerUnreadResidentIdsStream(managerId),
                  builder: (context, unreadSnapshot) {
                    final unreadResidentIds = unreadSnapshot.data ?? <String>{};

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final resident = filtered[index];
                        final residentId = resident['id'].toString();
                        final name = _displayName(resident);

                        return _buildResidentTile(
                          residentId: residentId,
                          name: name,
                          hasUnread: unreadResidentIds.contains(residentId),
                          isOnline: _onlineResidentIds.contains(residentId),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Inbox',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Resident Messages',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_chat_read_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: midBlue, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Search residents...',
            hintStyle: TextStyle(
              fontFamily: 'Urbanist',
              color: Colors.blueGrey.shade300,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                color: primaryBlue, size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'All Residents',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryBlue,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentTile({
    required String residentId,
    required String name,
    bool hasUnread = false,
    bool isOnline = false,
  }) {
    final initials = _initials(name);
    final avatarColors = [
      [const Color(0xFF2563EB), const Color(0xFF60A5FA)],
      [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
      [const Color(0xFF1E40AF), const Color(0xFF93C5FD)],
      [const Color(0xFF3B82F6), const Color(0xFFBAE6FD)],
    ];
    final colorPair =
        avatarColors[name.codeUnitAt(0) % avatarColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChat(
              residentId: residentId, residentName: name),
          borderRadius: BorderRadius.circular(16),
          splashColor: softBlue,
          highlightColor: softBlue.withValues(alpha: 0.5),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasUnread ? softBlue : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasUnread ? primaryBlue : const Color(0xFFE2EAFF),
                width: hasUnread ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colorPair,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: colorPair[0].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Name + role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                          fontSize: hasUnread ? 16 : 15,
                          color: hasUnread ? Colors.black : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            isOnline ? 'Active now' : 'Resident',
                            style: const TextStyle(
                              fontFamily: 'Urbanist',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chat button
                if (hasUnread)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: softBlue,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: primaryBlue,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
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
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: primaryBlue),
      ),
    );

    try {
      final conversationId =
          await _service.getOrCreateResidentConversation(residentId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            name: residentName,
            conversationId: conversationId,
            otherProfileId: residentId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.showAppSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _displayName(Map<String, dynamic> profile) {
    final firstName = (profile['first_name'] ?? '').toString().trim();
    final lastName = (profile['last_name'] ?? '').toString().trim();
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Resident' : name;
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'R';
  }

}
