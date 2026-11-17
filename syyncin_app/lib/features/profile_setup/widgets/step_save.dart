import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../data/meta.dart';
import '../../../core/widgets/widgets.dart';

/// Run a save call; show the API's message on failure. Returns true on success.
Future<bool> saveStep(BuildContext context, Future<void> Function() save) async {
  try {
    await save();
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  }
}

/// Multi-select skills from the admin-managed list (GET /meta/skills). Returns names, or null if dismissed.
Future<List<String>?> showSkillPicker(BuildContext context, {required List<String> selected, int max = 5}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true, // never slide under the status bar / notch
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _SkillSheet(selected: selected, max: max),
  );
}

class _SkillSheet extends StatefulWidget {
  const _SkillSheet({required this.selected, required this.max});
  final List<String> selected;
  final int max;

  @override
  State<_SkillSheet> createState() => _SkillSheetState();
}

class _SkillSheetState extends State<_SkillSheet> {
  late final Set<String> _picked = {...widget.selected};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = Meta.instance.skills.map((s) => s.name).toList();
    final shown = all.where((s) => s.toLowerCase().contains(_q.toLowerCase())).toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x4, AppSpace.screen, AppSpace.x4 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Text('Skills', style: AppText.sectionTitle)),
                  Text('${_picked.length}/${widget.max}', style: AppText.counter),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line)),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  style: AppText.fieldInput,
                  decoration: const InputDecoration.collapsed(hintText: 'Search skills', hintStyle: AppText.fieldHint),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: all.isEmpty
                    ? const Center(child: Text("Skills couldn't be loaded. Check your connection.", style: AppText.helper))
                    : ListView(
                        children: [
                          for (final s in shown)
                            InkWell(
                              onTap: () => setState(() {
                                if (_picked.contains(s)) {
                                  _picked.remove(s);
                                } else if (_picked.length < widget.max) {
                                  _picked.add(s);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can choose up to ${widget.max} skills.')));
                                }
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    AppCheckbox(checked: _picked.contains(s), size: 20, look: CheckboxLook.filled, radius: 5, borderColor: AppColors.line, borderWidth: 1.5),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(s, style: AppText.fieldInput.copyWith(fontSize: 15))),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).pop(_picked.toList())),
            ],
          ),
        ),
      ),
    );
  }
}
