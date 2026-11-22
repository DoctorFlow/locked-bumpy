import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

enum MaternalNeed {
  iron(
    name: 'IRON',
    costume: 'VAMPIRE',
    color: AppPalette.needIron,
    foodExamples: 'Lentils or beans',
  ),
  brain(
    name: 'BRAIN',
    costume: 'ZOMBIE',
    color: AppPalette.needBrain,
    foodExamples: 'Leafy greens or beans',
  ),
  bones(
    name: 'BONES',
    costume: 'SKELETON',
    color: AppPalette.needBones,
    foodExamples: 'Milk, yogurt or cheese',
  ),
  water(
    name: 'WATER',
    costume: 'MUMMY',
    color: AppPalette.needWater,
    foodExamples: 'A refreshing glass of water',
  ),
  rest(
    name: 'REST',
    costume: 'GHOST',
    color: AppPalette.needRest,
    foodExamples: 'Put your feet up for five',
  ),
  vitamin(
    name: 'VITAMIN',
    costume: 'WITCH',
    color: AppPalette.needVitamin,
    foodExamples: 'The vitamin your doctor chose',
  );

  final String name;
  final String costume;
  final Color color;
  final String foodExamples;

  const MaternalNeed({
    required this.name,
    required this.costume,
    required this.color,
    required this.foodExamples,
  });

  String tag({required bool isHalloween}) {
    if (isHalloween) {
      return '$costume · $name';
    } else {
      return 'TODAY · $name';
    }
  }
}
