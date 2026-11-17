import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../core/network/api_client.dart';
import '../../data/api.dart';
import '../profile_setup/widgets/pickers.dart';
import 'models/discovery_state.dart';
import 'widgets/person_card.dart' show OutlineActionButton;

const _allProfessions = 'All professions';
const _myCity = 'My city';

/// Figma 11b — Filters. Pops with the chosen [DiscoveryFilters].
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, required this.initial});
  final DiscoveryFilters initial;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late DiscoveryFilters _f = widget.initial;
  FilterOptions? _opts;
  String? _loadError;
  int? _count;
  Timer? _countTimer;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _recount();
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final o = await DiscoverApi.filterOptions();
      if (mounted) setState(() => _opts = o);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  /// "Show N people" — same query as KYN with limit=1 (debounced).
  void _recount() {
    _countTimer?.cancel();
    _countTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final n = await DiscoverApi.count(_f.toQuery());
        if (mounted) setState(() => _count = n);
      } catch (_) {}
    });
  }

  void _set(DiscoveryFilters f) {
    setState(() => _f = f);
    _recount();
  }

  String _nameOf(List<(int, String)> list, int? id, String fallback) =>
      list.firstWhere((e) => e.$1 == id, orElse: () => (0, fallback)).$2;

  Future<void> _pickProfession() async {
    final o = _opts;
    if (o == null) return;
    final v = await showOptionSheet(
      context,
      title: 'Profession',
      options: [_allProfessions, ...o.professions.map((e) => e.$2)],
      selected: _nameOf(o.professions, _f.industryId, _allProfessions),
    );
    if (v == null) return;
    final match = o.professions.where((e) => e.$2 == v);
    _set(match.isEmpty ? _f.copyWith(clearIndustry: true) : _f.copyWith(industryId: match.first.$1));
  }

  Future<void> _pickCity() async {
    final o = _opts;
    if (o == null) return;
    final v = await showOptionSheet(
      context,
      title: 'Location',
      options: o.cities.map((e) => e.$2).toList(),
      selected: _nameOf(o.cities, _f.cityId ?? o.defaultCityId, _myCity),
    );
    if (v == null) return;
    final match = o.cities.where((e) => e.$2 == v);
    if (match.isNotEmpty) _set(_f.copyWith(cityId: match.first.$1));
  }

  void _toggleInterest(int id) {
    final next = {..._f.interestIds};
    next.contains(id) ? next.remove(id) : next.add(id);
    _set(_f.copyWith(interestIds: next));
  }

  @override
  Widget build(BuildContext context) {
    final o = _opts;
    final count = _count;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppTopBar(
        title: 'Filters',
        actions: [AppBarTextAction(label: 'Reset', onPressed: () => _set(DiscoveryFilters.defaults))],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Body ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x5, AppSpace.screen, AppSpace.x6),
                children: [
                  if (_loadError != null) ...[
                    Text(_loadError!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.error)),
                    const SizedBox(height: 16),
                  ],
                  const _Label('Profession'),
                  _SelectBox(value: o == null ? _allProfessions : _nameOf(o.professions, _f.industryId, _allProfessions), onTap: _pickProfession),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(child: _Label('Distance', bottom: 0)),
                      Text(
                        'Within ${_f.maxDistanceKm.round()} km',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GradientSlider(
                    value: _f.maxDistanceKm,
                    min: 5,
                    max: 50,
                    onChanged: (v) => _set(_f.copyWith(maxDistanceKm: v.roundToDouble())),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5 km', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.sub)),
                      Text('50 km', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.sub)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _Label('Interests'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final i in o?.interests ?? const <(int, String)>[])
                        _OutlineChip(
                          label: i.$2,
                          selected: _f.interestIds.contains(i.$1),
                          showCheck: true,
                          onTap: () => _toggleInterest(i.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _Label('Experience'),
                  LayoutBuilder(
                    builder: (context, c) {
                      final w = (c.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: w,
                            child: _OutlineChip(
                              label: 'Any',
                              selected: _f.experienceLevelId == null,
                              height: 44,
                              center: true,
                              onTap: () => _set(_f.copyWith(clearExperience: true)),
                            ),
                          ),
                          for (final e in o?.experienceLevels ?? const <(int, String)>[])
                            SizedBox(
                              width: w,
                              child: _OutlineChip(
                                label: e.$2,
                                selected: _f.experienceLevelId == e.$1,
                                height: 44,
                                center: true,
                                onTap: () => _set(_f.copyWith(experienceLevelId: e.$1)),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const _Label('Location'),
                  _SelectBox(value: o == null ? _myCity : _nameOf(o.cities, _f.cityId ?? o.defaultCityId, _myCity), onTap: _pickCity),
                  const SizedBox(height: 22),
                  const _Label('Sort by', bottom: 8),
                  Wrap(
                    spacing: 24,
                    runSpacing: 10,
                    children: [
                      _RadioOption(label: 'Best match', selected: _f.sortBy == SortBy.match, onTap: () => _set(_f.copyWith(sortBy: SortBy.match))),
                      _RadioOption(label: 'Nearest', selected: _f.sortBy == SortBy.nearest, onTap: () => _set(_f.copyWith(sortBy: SortBy.nearest))),
                      _RadioOption(label: 'Name', selected: _f.sortBy == SortBy.name, onTap: () => _set(_f.copyWith(sortBy: SortBy.name))),
                      _RadioOption(label: 'Newest', selected: _f.sortBy == SortBy.newest, onTap: () => _set(_f.copyWith(sortBy: SortBy.newest))),
                    ],
                  ),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x3, AppSpace.screen, AppSpace.x3),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlineActionButton(label: 'Clear filters', height: 52, radius: 10, onTap: () => _set(DiscoveryFilters.defaults)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: PrimaryButton(
                      label: count == null ? 'Show people' : 'Show $count ${count == 1 ? 'person' : 'people'}',
                      height: 52,
                      radius: 10,
                      onPressed: () => Navigator.of(context).pop(_f),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.bottom = 12});
  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
      );
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: value,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 14, right: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line)),
          child: Row(
            children: [
              Expanded(
                child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink)),
              ),
              const AppIcon(AppIcons.chevronDown, size: 20, color: AppColors.sub),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outline chip — selected = light-blue fill + blue border (+ optional tick).
class _OutlineChip extends StatelessWidget {
  const _OutlineChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    this.height = 36,
    this.center = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;
  final double height;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedFill : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.blue : AppColors.line),
          ),
          child: Row(
            mainAxisSize: center ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showCheck && selected) ...[
                const AppIcon(AppIcons.check, size: 14, color: AppColors.blue),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: selected ? AppColors.blue : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AppRadio(selected: selected),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Track with the blue→teal setup gradient and a white thumb with blue ring.
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({required this.value, required this.min, required this.max, required this.onChanged});
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  static const _thumb = 24.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final usable = c.maxWidth - _thumb;
        final t = ((value - min) / (max - min)).clamp(0.0, 1.0);

        void update(double dx) {
          final p = ((dx - _thumb / 2) / usable).clamp(0.0, 1.0);
          onChanged(min + p * (max - min));
        }

        return Semantics(
          slider: true,
          value: '${value.round()} km',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => update(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
            child: SizedBox(
              height: 28,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(color: AppColors.segment, borderRadius: BorderRadius.circular(3)),
                  ),
                  Container(
                    height: 6,
                    width: _thumb / 2 + usable * t,
                    decoration: BoxDecoration(gradient: AppGradients.setup, borderRadius: BorderRadius.circular(3)),
                  ),
                  Positioned(
                    left: usable * t,
                    child: Container(
                      width: _thumb,
                      height: _thumb,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.blue, width: 2),
                        boxShadow: const [BoxShadow(color: AppColors.shadowNavy12, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
