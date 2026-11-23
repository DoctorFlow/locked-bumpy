# Design: Baby Paper Doll Avatar

## Asset map (from master-context.md §4)
| Asset file | Used when |
|---|---|
| `assets/images/everyday.png` | Everyday mode (any need) |
| `assets/images/body-vampire.png` | Halloween + IRON |
| `assets/images/body-mummy.png` | Halloween + WATER |
| `assets/images/body-witch.png` | Halloween + VITAMIN |
| `assets/images/body-ghost.png` | Halloween + REST |
| `assets/images/body-skeleton.png` | Halloween + BONES |
| `assets/images/body-zombie.png` | Halloween + BRAIN |

## BabyAvatar widget interface

```dart
class BabyAvatar extends StatelessWidget {
  const BabyAvatar({
    super.key,
    required this.need,
    required this.palette,
    this.hopAnimation,          // null = no animation
  });

  final MaternalNeed need;
  final AppPalette palette;
  final Animation<double>? hopAnimation;
}
```

## Rendering logic (inside BabyAvatar.build)
```
assetPath = palette.isHalloween
  ? _costumeAsset(need)   // e.g. 'assets/images/body-vampire.png'
  : 'assets/images/everyday.png'

child = Image.asset(assetPath, width: 120, height: 120, fit: BoxFit.contain)
       with error builder → emoji fallback

if hopAnimation != null && !MediaQuery.disableAnimationsOf(context):
  wrap in AnimatedBuilder + Transform.translate(offset: Offset(0, hopAnimation.value))
```

## pubspec.yaml change required
```yaml
flutter:
  assets:
    - assets/images/
    - assets/content/
```

## Size
Avatar container: 120×120 dp, `BoxFit.contain`, transparent background.
Sits inside the existing baby card `Container` on TodayScreen and ThisWeekScreen.
