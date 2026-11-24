import 'package:flutter/foundation.dart';

/// Set with --dart-define=BUMPY_REVIEW=true. Never true in a release build.
const bool kReviewBuild = bool.fromEnvironment('BUMPY_REVIEW') && !kReleaseMode;
