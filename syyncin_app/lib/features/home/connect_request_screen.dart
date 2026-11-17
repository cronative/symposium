import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api.dart';
import 'models/discovery_state.dart';
import 'models/person.dart';
import 'widgets/person_card.dart' show InitialsAvatar;

const _maxChars = 300;

/// Opens "Send Connection Request" and, once sent, shows a snackbar whose
/// "View" action jumps to Inbox → Requests → Sent.
Future<void> openConnectFlow(BuildContext context, Person person) async {
  final sent = await Navigator.of(context).pushNamed<String>(Routes.connect, arguments: person);
  if (sent == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(sent),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            AppNav.openInbox(InboxSegment.requests, sent: true);
            Navigator.of(context).popUntil((r) => r.settings.name == Routes.home || r.isFirst);
          },
        ),
      ),
    );
}

/// Figma 17 (v3) — Send Connection Request with optional message + suggestions.
class ConnectRequestScreen extends StatefulWidget {
  const ConnectRequestScreen({super.key, required this.person});
  final Person person;

  @override
  State<ConnectRequestScreen> createState() => _ConnectRequestScreenState();
}

class _ConnectRequestScreenState extends State<ConnectRequestScreen> {
  final _msg = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;

  String get _first => widget.person.firstName;

  late List<String> _suggestions = [
    "Hi $_first, I'd love to connect and exchange ideas.",
    'We share a few interests. It would be great to connect.',
    "I'm new to the area and would love to meet more professionals.",
  ];

  @override
  void initState() {
    super.initState();
    // Personalised suggestions (shared interests, same area) from the API.
    DiscoverApi.icebreakers(widget.person.id).then((s) {
      if (mounted && s.isNotEmpty) setState(() => _suggestions = s);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _msg.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _useSuggestion(String s) {
    _msg.text = s;
    _msg.selection = TextSelection.collapsed(offset: s.length);
    _focus.requestFocus();
    setState(() {});
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final (_, message) = await NetworkApi.sendRequest(widget.person.id, _msg.text);
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(e.message),
          action: e.code == 'REQUEST_RECEIVED'
              ? SnackBarAction(
                  label: 'Open Inbox',
                  onPressed: () {
                    AppNav.openInbox(InboxSegment.requests);
                    Navigator.of(context).popUntil((r) => r.settings.name == Routes.home || r.isFirst);
                  },
                )
              : null,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: const AppTopBar(title: 'Send Connection Request'),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // ── Body ────────────────────────────────────────
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x5, AppSpace.screen, AppSpace.x6),
                  children: [
                    const Text('Start with a hello.', style: AppText.setupTitle),
                    const SizedBox(height: 6),
                    Text("You're reaching out to ${p.name}, ${p.role}.", style: AppText.setupSubtitle),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                      child: Row(
                        children: [
                          InitialsAvatar(initials: p.initials),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
                                const SizedBox(height: 4),
                                Text(p.role, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const AppIcon(AppIcons.pin, size: 14, color: AppColors.sub),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        p.placeLine.isEmpty ? 'SyyncIn member' : p.placeLine,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sub),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text('Add a personal message (optional)', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    const SizedBox(height: 10),
                    Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _focus.hasFocus ? AppColors.blue : AppColors.line),
                      ),
                      child: Focus(
                        onFocusChange: (_) => setState(() {}),
                        child: TextField(
                          controller: _msg,
                          focusNode: _focus,
                          maxLines: null,
                          expands: true,
                          inputFormatters: [LengthLimitingTextInputFormatter(_maxChars)],
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                          style: AppText.fieldInput.copyWith(height: 20 / 14),
                          decoration: InputDecoration.collapsed(
                            hintText: "Tell $_first why you'd like to connect…",
                            hintStyle: AppText.fieldHint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_msg.text.characters.length}/$_maxChars characters',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.placeholder),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Need a little inspiration?', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    const Text('Tap a suggestion to use or edit it.', style: AppText.helper),
                    const SizedBox(height: 12),
                    for (final s in _suggestions) ...[
                      _SuggestionCard(text: s, selected: _msg.text == s, onTap: () => _useSuggestion(s)),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const AppIcon(AppIcons.lock, size: 14, color: AppColors.sub),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Your message will be visible to $_first with your request.', style: AppText.helper)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── CTA ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x3, AppSpace.screen, AppSpace.x3),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                child: PrimaryButton(
                  label: 'Send Request',
                  height: 52,
                  loading: _sending,
                  leading: const AppIcon(AppIcons.userPlus, size: 20, color: AppColors.white),
                  onPressed: _send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedFill : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.blue : AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AppIcon(AppIcons.chat, size: 16, color: selected ? AppColors.blue : AppColors.placeholder),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 20 / 14, color: AppColors.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
