import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // We'll add providers here as we build them
      ],
      child: const IHAApp(),
    ),
  );
}