import 'package:flutter/material.dart';
import 'palette.dart';

/// The app's [ThemeData] for one look ([AppPalette.everyday] or
/// [AppPalette.halloween]).
ThemeData buildTheme(AppPalette p) => ThemeData(
  brightness: p.isHalloween ? Brightness.dark : Brightness.light,
  scaffoldBackgroundColor: p.skyBottom,
  extensions: [p],
);
