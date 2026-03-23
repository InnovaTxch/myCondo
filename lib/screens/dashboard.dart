import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'tenant_dashboard.dart';
import 'manager_dashboard.dart';

class Dashboard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Responsive(
      mobile: TenantDashboard(),
      desktop: ManagerDashboard(),
    );

  }
}