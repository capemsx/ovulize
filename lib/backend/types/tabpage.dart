import 'package:flutter/material.dart';

class TabPage {
  String title;
  IconData icon;
  Widget page;

  TabPage({
    required this.title,
    required this.icon,
    required this.page,
  });
}
