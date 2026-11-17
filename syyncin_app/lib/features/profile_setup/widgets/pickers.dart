import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Bottom-sheet single-select list used by dropdown fields.
Future<String?> showOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true, // never slide under the status bar / notch
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x4, AppSpace.screen, AppSpace.x2),
              child: Text(title, style: AppText.sectionTitle),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.x4),
                itemCount: options.length,
                separatorBuilder: (_, __) => const DividerLine(),
                itemBuilder: (context, i) {
                  final o = options[i];
                  final sel = o == selected;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(o),
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(o, style: sel ? AppText.fieldInput.copyWith(color: AppColors.blue, fontWeight: FontWeight.w500) : AppText.fieldInput),
                          ),
                          if (sel) const AppIcon(AppIcons.check, size: 18, color: AppColors.blue),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

/// Simple in-memory store for the setup flow (replace with your state
/// management / API layer when wiring the backend).
class SetupDraft {
  SetupDraft._();
  static final instance = SetupDraft._();

  String fullName = '';
  DateTime? dateOfBirth;
  String linkedIn = '';
  String? gender;

  String jobTitle = '';
  String? industry;
  String company = '';
  String? experience;
  String skills = '';

  final Set<String> interests = {};
  final Set<String> reasons = {};
  final Map<int, String> mindset = {};

  String city = '';
  String locality = '';
  int connectMode = 2;
  int distance = 2;
  final Set<String> availability = {'Flexible'};
  bool nearbyDiscovery = true;
  bool openToConnect = true;

  // Read-only, filled from GET /me.
  String about = '';
  String? photoUrl;
  String verificationStatus = 'none';

  /// Forget everything (log out / different account).
  void reset() {
    fullName = linkedIn = jobTitle = company = skills = city = locality = about = '';
    dateOfBirth = null;
    gender = industry = experience = photoUrl = null;
    interests.clear();
    reasons.clear();
    mindset.clear();
    connectMode = 2;
    distance = 2;
    availability
      ..clear()
      ..add('Flexible');
    nearbyDiscovery = true;
    openToConnect = true;
    verificationStatus = 'none';
  }
}
