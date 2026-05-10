import 'package:flutter/material.dart';
import 'package:mycondo/features/shared/pages/chat_screen.dart';
import 'package:mycondo/services/shared/chat_services.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class ManagerInboxScreen extends StatefulWidget {
  const ManagerInboxScreen({super.key});

  @override
  State<ManagerInboxScreen> createState() => _ManagerInboxScreenState();
}

class _ManagerInboxScreenState extends State<ManagerInboxScreen> {
  final _service = MessagingService();
  Future<List<Map<String, dynamic>>>? _residentsFuture;
  String? _managerId;
  bool _isLoadingProfile = true;
  String _searchQuery = '';

  // Blue color palette (consistent with chat_screen.dart)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color deepBlue = Color(0xFF1D4ED8);
  static const Color softBlue = Color(0xFFEFF6FF);
  static const Color midBlue = Color(0xFFBFDBFE);
  static const Color bgColor = Color(0xFFF0F4FF);

  @override
  void initState() {
    super.initState();
    _loadManagerProfile();
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
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryBlue),
        ),
      );
    }

    final managerId = _managerId;
    if (managerId == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildSectionLabel(),
            Expanded(
              child: RefreshIndicator(
                color: primaryBlue,
                onRefresh: _refreshResidents,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _residentsFuture ??
                      _service.fetchResidentsForManager(managerId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildScrollableMessage(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return _buildScrollableMessage(
                        child: const CircularProgressIndicator(
                          color: primaryBlue,
                        ),
                      );
                    }

                    final residents = snapshot.data!;
                    final filtered = _searchQuery.isEmpty
                        ? residents
                        : residents.where((r) {
                            final name =
                                _displayName(r).toLowerCase();
                            return name.contains(
                                _searchQuery.toLowerCase());
                          }).toList();

                    if (filtered.isEmpty) {
                      return _buildScrollableMessage(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 56,
                                color: midBlue),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No residents match your search.'
                                  : 'No residents available.',
                              style: const TextStyle(
                                fontFamily: 'Urbanist',
                                color: Color(0xFF64748B),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                          top: 4, bottom: 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final resident = filtered[index];
                        final residentId =
                            resident['id'].toString();
                        final name = _displayName(resident);
                        return _buildResidentTile(
                            residentId: residentId, name: name);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
                  color: primaryBlue.withOpacity(0.35),
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
              color: primaryBlue.withOpacity(0.06),
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
          highlightColor: softBlue.withOpacity(0.5),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFE2EAFF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
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
                        color: colorPair[0].withOpacity(0.3),
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
                const SizedBox(width: 14),
                // Name + role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Resident',
                            style: TextStyle(
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

  Widget _buildScrollableMessage({required Widget child}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: Center(child: child),
        ),
      ],
    );
  }
}
