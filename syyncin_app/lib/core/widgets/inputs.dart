import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Label used above setup fields: "Full name *" or "LinkedIn URL (Optional)".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.suffix});
  final String text;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: AppText.fieldLabel,
        children: [
          if (suffix != null)
            TextSpan(
              text: ' $suffix',
              style: AppText.fieldLabel.copyWith(fontWeight: FontWeight.w400, color: AppColors.sub),
            ),
        ],
      ),
    );
  }
}

/// Profile-setup input: 46 h · radius 8 · 1 px #E1E7F2 border · no fill.
/// Pass [onTap] to turn it into a read-only picker (date / dropdown).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.labelSuffix,
    this.controller,
    this.value,
    this.leadingIcon,
    this.trailingIcon,
    this.helper,
    this.onTap,
    this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.labelGap = 6,
    this.autofillHints,
  });

  final String label;
  final String? labelSuffix;
  final String hint;
  final TextEditingController? controller;

  /// Displayed text when the field is a picker (onTap != null).
  final String? value;
  final String? leadingIcon;
  final String? trailingIcon;
  final String? helper;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final double labelGap;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPicker = widget.onTap != null;
    final hasValue = (widget.value ?? '').isNotEmpty;

    final box = Container(
      height: 46,
      padding: const EdgeInsets.only(left: 14, right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _focused ? AppColors.blue : AppColors.line, width: 1),
      ),
      child: Row(
        children: [
          if (widget.leadingIcon != null) ...[
            AppIcon(widget.leadingIcon!, size: 18, color: AppColors.iconBlue),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: isPicker
                ? Text(
                    hasValue ? widget.value! : widget.hint,
                    style: hasValue ? AppText.fieldInput : AppText.fieldHint,
                    overflow: TextOverflow.ellipsis,
                  )
                : TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    onChanged: widget.onChanged,
                    keyboardType: widget.keyboardType,
                    textCapitalization: widget.textCapitalization,
                    autofillHints: widget.autofillHints,
                    style: AppText.fieldInput,
                    decoration: InputDecoration.collapsed(hintText: widget.hint, hintStyle: AppText.fieldHint),
                  ),
          ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: 8),
            AppIcon(widget.trailingIcon!, size: 18, color: AppColors.sub),
          ],
        ],
      ),
    );

    final fieldContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(widget.label, suffix: widget.labelSuffix),
        SizedBox(height: widget.labelGap),
        box,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        isPicker
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: fieldContent,
              )
            : fieldContent,
        if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(widget.helper!, style: AppText.helper),
        ],
      ],
    );
  }
}

/// Auth input: 56 h · radius 5 · Inter 16 · bold navy label above.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.helper,
    this.onChanged,
  });

  final String label;
  final String hint;
  final String? helper;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: AppText.authLabel),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: _focused ? AppColors.blue : AppColors.line, width: 1),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            onChanged: widget.onChanged,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
            style: AppText.authInput,
            decoration: InputDecoration.collapsed(
              hintText: widget.hint,
              hintStyle: AppText.authInput.copyWith(color: AppColors.authPlaceholder),
            ),
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 8),
          Text(widget.helper!, style: AppText.authBody),
        ],
      ],
    );
  }
}

/// Six 50×56 boxes (radius 10). Red borders when [hasError].
class OtpInput extends StatefulWidget {
  const OtpInput({super.key, required this.onChanged, this.hasError = false, this.length = 6});

  final ValueChanged<String> onChanged;
  final bool hasError;
  final int length;

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  void clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final filled = i < code.length;
              final active = _focus.hasFocus && i == code.length.clamp(0, widget.length - 1);
              final borderColor = widget.hasError ? AppColors.error : (active ? AppColors.blue : AppColors.line);
              return Container(
                width: 50,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: widget.hasError || active ? 1.5 : 1),
                ),
                child: Text(
                  filled ? code[i] : '•',
                  style: AppText.otpDigit.copyWith(color: filled ? AppColors.navy : AppColors.dotInactive),
                ),
              );
            }),
          ),
          // Invisible field that owns the keyboard / SMS autofill.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                showCursor: false,
                enableInteractiveSelection: false,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged(v);
                },
                decoration: const InputDecoration.collapsed(hintText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
