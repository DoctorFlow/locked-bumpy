import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';
import '../widgets/data_confirmation.dart';
import '../widgets/pregnancy_date_picker.dart';
import '../widgets/pause_button.dart';
import '../widgets/skin_tone_picker.dart';
import '../widgets/whole_word_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  static Future<void> open(BuildContext context, AppState state) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: state,
          builder: (context, _) => SettingsScreen(state: state),
        ),
      ),
    );
  }

  Future<void> _editNickname(BuildContext context) async {
    var value = state.nickname;
    var saving = false;
    var failed = false;
    await showDialog<void>(
      context: context,
      animationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) {
          Future<void> save() async {
            if (saving || state.isPaused) return;
            update(() {
              saving = true;
              failed = false;
            });
            final saved = await state.saveNickname(value);
            if (!context.mounted || state.isPaused || state.isFirstRun) return;
            if (saved) {
              Navigator.pop(context);
            } else {
              update(() {
                saving = false;
                failed = true;
              });
            }
          }

          return AlertDialog(
            scrollable: true,
            title: Row(
              children: [
                const Expanded(child: Text('Baby nickname')),
                PauseButton(
                  onPressed: state.pause,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
            content: TextFormField(
              initialValue: value,
              autofocus: true,
              readOnly: saving,
              maxLength: 24,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nickname (optional)',
                errorText: failed ? 'Couldn’t save on this device.' : null,
              ),
              onChanged: (text) => value = text,
              onFieldSubmitted: (_) => save(),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: saving ? null : save,
                child: Text(failed ? 'Retry save' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 17;
    final title = AppText.heading.copyWith(color: palette.ink);
    final reading = AppText.body.copyWith(color: palette.inkSoft);
    Widget rule() => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
      child: Divider(height: 1, thickness: 1, color: palette.rule),
    );
    final heading = Semantics(
      header: true,
      child: WholeWordText(
        'Settings',
        style: AppText.title.copyWith(color: palette.moonlight),
      ),
    );
    // An outlined button on the page (theme outline edge, moonlight label),
    // like "Erase all data" below, not an underlined link.
    final pause = Tooltip(
      message: 'Pause',
      child: OutlinedButton.icon(
        onPressed: state.pause,
        style: OutlinedButton.styleFrom(foregroundColor: palette.moonlight),
        icon: largeText ? null : const Icon(Icons.pause_circle_outline),
        label: Text(largeText ? 'Pause' : 'Pause app'),
      ),
    );
    return Scaffold(
      backgroundColor: palette.skyBottom,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // At large text the title takes its own line under the
                // back and pause controls, so it never breaks mid-word.
                if (largeText) ...[
                  Row(
                    children: [
                      BackButton(color: palette.moonlight),
                      const Spacer(),
                      pause,
                      const SizedBox(width: AppSpace.page),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.page,
                    ),
                    child: heading,
                  ),
                ] else
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSpace.row),
                    child: Row(
                      children: [
                        BackButton(color: palette.moonlight),
                        Expanded(child: heading),
                        pause,
                        const SizedBox(width: AppSpace.page),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.page,
                      AppSpace.s,
                      AppSpace.page,
                      AppSpace.xl,
                    ),
                    children: [
                      PaperCard(
                        padding: const EdgeInsets.all(AppSpace.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _EditableDetail(
                              label: 'Due date',
                              value: state.dueDate == null
                                  ? ''
                                  : MaterialLocalizations.of(
                                      context,
                                    ).formatShortDate(state.dueDate!),
                              action: 'Change due date',
                              palette: palette,
                              onTap: () async {
                                state.refreshDay();
                                final picked = await pickPregnancyDate(
                                  context,
                                  today: state.today,
                                  useDueDate: true,
                                  onPause: state.pause,
                                  selected: state.dueDate,
                                );
                                if (picked != null &&
                                    context.mounted &&
                                    !state.isPaused &&
                                    !state.isFirstRun) {
                                  final saved = await state.saveDueDate(picked);
                                  if (!saved &&
                                      context.mounted &&
                                      !state.isPaused) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Couldn’t save the due date. Please try again.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            _EditableDetail(
                              label: 'Nickname',
                              value: state.babyDisplayName,
                              action: 'Edit nickname',
                              palette: palette,
                              onTap: () => _editNickname(context),
                            ),
                            rule(),
                            Semantics(
                              header: true,
                              child: Text('Appearance', style: title),
                            ),
                            const SizedBox(height: AppSpace.s),
                            Wrap(
                              spacing: AppSpace.s,
                              runSpacing: AppSpace.s,
                              children: [
                                for (final mode in [false, true])
                                  ChoiceChip(
                                    label: Text(
                                      mode ? 'Halloween' : 'Everyday',
                                    ),
                                    selected: mode == state.isHalloween,
                                    onSelected: (_) {
                                      if (mode != state.isHalloween) {
                                        state.toggleMode();
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.xl),
                            SkinTonePicker(
                              selected: state.skinTone,
                              onSelected: state.saveSkinTone,
                              foreground: palette.ink,
                              showPreview: true,
                            ),
                            rule(),
                            Semantics(
                              header: true,
                              child: Text('Privacy', style: title),
                            ),
                            const SizedBox(height: AppSpace.s),
                            Text(
                              kIsWeb
                                  ? 'Your data stays in this browser on this device. No accounts. No tracking. No ads.'
                                  : AppConstants.privacyStatement,
                              style: reading,
                            ),
                            const SizedBox(height: AppSpace.xl),
                            Text('Medical disclaimer', style: title),
                            const SizedBox(height: AppSpace.s),
                            Text(AppConstants.disclaimer, style: reading),
                            rule(),
                            Wrap(
                              spacing: AppSpace.s,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('Little Bumpy', style: title),
                                Text(
                                  AppConstants.appVersion,
                                  style: AppText.small.copyWith(
                                    color: palette.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.moonlight,
                          ),
                          onPressed: () => confirmErase(context, state),
                          child: const Text('Erase all data'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableDetail extends StatelessWidget {
  const _EditableDetail({
    required this.label,
    required this.value,
    required this.action,
    required this.palette,
    required this.onTap,
  });
  final String label;
  final String value;
  final String action;
  final AppPalette palette;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action,
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.only(
          start: AppSpace.s,
          end: AppSpace.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
        onTap: onTap,
        title: Text(
          label,
          style: AppText.small.copyWith(color: palette.inkSoft),
        ),
        subtitle: Text(
          value,
          style: AppText.bodyStrong.copyWith(color: palette.ink),
        ),
        trailing: Icon(Icons.edit_outlined, color: palette.ink, size: 24),
      ),
    );
  }
}
