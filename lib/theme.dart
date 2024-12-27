import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const colorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color.fromARGB(255, 0, 128, 128),
  secondary: Color.fromARGB(255, 19, 111, 99),
  onPrimary: Color.fromARGB(255, 255, 255, 255),
  onSecondary: Color.fromARGB(255, 255, 255, 255),
  surface: Color.fromARGB(255, 230, 240, 250),
  onSurface: Color.fromARGB(255, 0, 0, 0),
  error: Color.fromARGB(255, 230, 57, 70),
  onError: Color.fromARGB(255, 255, 255, 255),
);

final theme = ThemeData().copyWith(
  colorScheme: colorScheme,
  scaffoldBackgroundColor: colorScheme.surface,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
  ),
  textTheme: GoogleFonts.robotoTextTheme(),
);