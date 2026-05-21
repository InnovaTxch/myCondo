import 'package:flutter/material.dart';

class DashboardTabItem {
  const DashboardTabItem({
    required this.root,
    this.navigatorKey,
  });

  final Widget root;
  final GlobalKey<NavigatorState>? navigatorKey;
}

class DashboardTabScaffold extends StatefulWidget {
  const DashboardTabScaffold({
    super.key,
    required this.tabs,
    required this.routes,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.bottomNavigationBar,
  });

  final List<DashboardTabItem> tabs;
  final Map<String, WidgetBuilder> routes;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget Function(int currentIndex, ValueChanged<int> onIndexChanged)
      bottomNavigationBar;

  @override
  State<DashboardTabScaffold> createState() => _DashboardTabScaffoldState();
}

class _DashboardTabScaffoldState extends State<DashboardTabScaffold> {
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = widget.tabs
        .map((t) => t.navigatorKey ?? GlobalKey<NavigatorState>())
        .toList(growable: false);
  }

  bool _handleBackPressed() {
    final navigator = _navigatorKeys[widget.currentIndex].currentState;
    if (navigator == null) return true;
    if (navigator.canPop()) {
      navigator.pop();
      return false;
    }
    if (widget.currentIndex != 0) {
      widget.onIndexChanged(0);
      return false;
    }
    return true;
  }

  void _selectTab(int index) {
    final navigator = _navigatorKeys[index].currentState;

    if (index == widget.currentIndex) {
      navigator?.popUntil((route) => route.isFirst);
      return;
    }

    navigator?.popUntil((route) => route.isFirst);
    widget.onIndexChanged(index);
  }

  Route<dynamic> _onGenerateRoute(int tabIndex, RouteSettings settings) {
    if (settings.name == Navigator.defaultRouteName) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => widget.tabs[tabIndex].root,
      );
    }

    final builder = widget.routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: builder,
      );
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Unknown route: ${settings.name}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _handleBackPressed(),
      child: Scaffold(
        body: IndexedStack(
          index: widget.currentIndex,
          children: List.generate(widget.tabs.length, (index) {
            return Offstage(
              offstage: widget.currentIndex != index,
              child: TickerMode(
                enabled: widget.currentIndex == index,
                child: Navigator(
                  key: _navigatorKeys[index],
                  onGenerateRoute: (settings) => _onGenerateRoute(index, settings),
                ),
              ),
            );
          }),
        ),
        bottomNavigationBar:
            widget.bottomNavigationBar(widget.currentIndex, _selectTab),
      ),
    );
  }
}
