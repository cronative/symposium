import 'package:flutter/material.dart';
import '../core/theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: AppSpace.buttonHeight,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppSpace.buttonRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.32),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.buttonRadius)),
      ),
      child: loading
          ? const SizedBox(height: 21, width: 21, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: AppSpace.buttonHeight,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.buttonRadius)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
    ),
  );
}

class TextAction extends StatelessWidget {
  const TextAction({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => TextButton(onPressed: onPressed, child: Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)));
}

class FormFieldGroup extends StatelessWidget {
  const FormFieldGroup({super.key, required this.label, required this.controller, required this.hint, this.validator, this.keyboardType, this.maxLines = 1, this.readOnly = false, this.onTap});
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
    const SizedBox(height: 9),
    TextFormField(controller: controller, validator: validator, keyboardType: keyboardType, maxLines: maxLines, readOnly: readOnly, onTap: onTap, decoration: InputDecoration(hintText: hint)),
  ]);
}

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({super.key, required this.step, required this.title, required this.subtitle, required this.children, required this.buttonLabel, required this.onNext});
  final int step;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String buttonLabel;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.maybePop(context)), backgroundColor: Colors.white, surfaceTintColor: Colors.white),
    body: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpace.page), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('STEP $step OF 4', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      const SizedBox(height: 13),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: step / 4, minHeight: 5, backgroundColor: AppColors.primaryLight, color: AppColors.primary)),
      const SizedBox(height: 28),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 9),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 29),
      Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (int i = 0; i < children.length; i++) ...[children[i], if (i != children.length - 1) const SizedBox(height: 19)],
      ]))),
      Padding(padding: const EdgeInsets.only(top: 12, bottom: 15), child: PrimaryButton(label: buttonLabel, onPressed: onNext)),
    ]))),
  );
}

class ChoiceChips extends StatelessWidget {
  const ChoiceChips({super.key, required this.options, required this.selected, required this.onToggle});
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 9, runSpacing: 10, children: options.map((option) {
    final active = selected.contains(option);
    return FilterChip(
      label: Text(option), selected: active, onSelected: (_) => onToggle(option),
      selectedColor: AppColors.primaryLight, backgroundColor: AppColors.surface,
      side: BorderSide(color: active ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(color: active ? AppColors.primary : AppColors.text, fontWeight: active ? FontWeight.w600 : FontWeight.w400),
      showCheckmark: false, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    );
  }).toList());
}
