import 'package:flutter/material.dart';
import 'package:mycondo/utils/responsive.dart';
import 'package:mycondo/features/manager/pages/manager_dashboard.dart';
import 'package:mycondo/features/resident/pages/resident_dashboard.dart';

class Dashboard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Responsive(
      mobile: ResidentDashboard(),
      desktop: ManagerDashboard(),
    );

  }
}