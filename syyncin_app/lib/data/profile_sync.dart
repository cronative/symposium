import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../app/routes.dart';
import '../core/network/api_client.dart';
import '../core/session/session.dart';
import '../features/profile_setup/widgets/pickers.dart';
import 'meta.dart';

/// Keeps [SetupDraft] (what the setup / profile screens edit) in sync with the API.
///
/// - [load] fills the draft from GET /me (resume setup, My Profile, Edit Profile).
/// - `save*` send one onboarding step; each returns the server profile and updates the draft.
/// - [saveAll] is Edit Profile's PUT /me/profile.
abstract final class ProfileSync {
  /// Bumped whenever the profile changes (name, photo…) so headers can rebuild.
  static final changes = ValueNotifier<int>(0);

  static final _api = ApiClient.instance;
  static SetupDraft get _d => SetupDraft.instance;

  static const _genders = {'woman': 'Woman', 'man': 'Man', 'other': 'Other', 'prefer_not_to_say': 'Prefer not to say'};
  static const _modes = ['in_person', 'online', 'both'];
  static const _radii = [5, 10, 25, 50];

  /// Route for an onboarding step (1–6) or Home (7).
  static String routeForStep(int step) => switch (step) {
        <= 1 => Routes.basicProfile,
        2 => Routes.professional,
        3 => Routes.interests,
        4 => Routes.mindset,
        5 => Routes.community,
        6 => Routes.selfie,
        _ => Routes.home,
      };

  /// GET /me → draft + session step. Returns the step.
  static Future<int> load() async {
    await Meta.instance.load();
    final r = await _api.get('/me');
    _apply(r.data);
    return Session.instance.onboardingStep;
  }

  // ── Onboarding steps ───────────────────────────────────────────────
  static Future<void> saveBasic() => _put('/onboarding/basic', _basic());
  static Future<void> saveWork() async => _put('/onboarding/work', await _work());
  static Future<void> saveInterests() => _put('/onboarding/interests', _interests());
  static Future<void> saveMindset() => _put('/onboarding/mindset', _mindset());
  static Future<void> saveCommunity() async => _put('/onboarding/community', await _community());

  /// Step 6 — multipart selfie. Returns the API message (pending / verified).
  static Future<String> uploadSelfie(Uint8List bytes, String filename, String mime) async {
    final r = await _api.upload('/verification/selfie', field: 'selfie', bytes: bytes, filename: filename, mime: mime);
    _d.verificationStatus = (r.data['status'] as String?) ?? 'pending';
    await Session.instance.setStep(7);
    return r.message;
  }

  static Future<String> uploadPhoto(Uint8List bytes, String filename, String mime) async {
    final r = await _api.upload('/me/photo', field: 'photo', bytes: bytes, filename: filename, mime: mime);
    _d.photoUrl = r.data['photoUrl'] as String?;
    changes.value++;
    return r.message;
  }

  /// My Profile › Preferences quick toggles (PATCH /me/settings).
  static Future<String> saveSettings({bool? openToConnect, bool? nearbyDiscovery}) async {
    final r = await _api.patch('/me/settings', body: {
      if (openToConnect != null) 'openToConnect': openToConnect,
      if (nearbyDiscovery != null) 'nearbyDiscovery': nearbyDiscovery,
    });
    _d.openToConnect = r.data['openToConnect'] != false;
    _d.nearbyDiscovery = r.data['nearbyDiscovery'] != false;
    return r.message;
  }

  /// Edit Profile — every section in one all-or-nothing call.
  static Future<String> saveAll() async {
    final r = await _api.put('/me/profile', body: {
      'basic': _basic(),
      'work': await _work(),
      'interests': _interests(),
      'mindset': _mindset(),
      'community': await _community(),
    });
    _apply(r.data);
    return r.message;
  }

  static Future<void> _put(String path, Map<String, dynamic> body) async {
    final r = await _api.put(path, body: body);
    _apply(r.data);
  }

  // ── Draft → API bodies ─────────────────────────────────────────────
  static Map<String, dynamic> _basic() {
    final dob = _d.dateOfBirth;
    String? g;
    for (final e in _genders.entries) {
      if (e.value == _d.gender) g = e.key;
    }
    return {
      'fullName': _d.fullName.trim(),
      'dob': dob == null ? null : '${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
      if (_d.linkedIn.trim().isNotEmpty) 'linkedinUrl': _d.linkedIn.trim(),
      'gender': g,
      if (_d.about.trim().isNotEmpty) 'about': _d.about.trim(),
    };
  }

  static Future<Map<String, dynamic>> _work() async {
    final m = Meta.instance;
    final names = _d.skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final skillIds = <int>[];
    final unknown = <String>[];
    for (final n in names) {
      final id = Meta.idOf(m.skills, n);
      id == null ? unknown.add(n) : skillIds.add(id);
    }
    if (unknown.isNotEmpty) {
      throw ApiException(
        code: 'UNKNOWN_SKILL',
        message: 'Pick skills from the list: ${unknown.join(', ')} ${unknown.length == 1 ? 'is' : 'are'} not available yet.',
      );
    }
    return {
      'jobTitle': _d.jobTitle.trim(),
      'industryId': _need(Meta.idOf(m.industries, _d.industry), 'Please choose your industry.'),
      if (_d.company.trim().isNotEmpty) 'company': _d.company.trim(),
      'experienceLevelId': _need(Meta.idOf(m.experienceLevels, _d.experience), 'Please choose your years of experience.'),
      'skillIds': skillIds,
    };
  }

  static Map<String, dynamic> _interests() {
    final m = Meta.instance;
    return {
      'interestIds': _d.interests.map((n) => Meta.idOf(m.interests, n)).whereType<int>().toList(),
      'reasonIds': _d.reasons.map((n) => Meta.idOf(m.reasons, n)).whereType<int>().toList(),
    };
  }

  static Map<String, dynamic> _mindset() {
    final qs = Meta.instance.questions;
    return {
      'answers': [
        for (final e in _d.mindset.entries)
          if (e.key < qs.length && Meta.idOf(qs[e.key].options, e.value) != null)
            {'questionId': qs[e.key].id, 'optionId': Meta.idOf(qs[e.key].options, e.value)},
      ],
    };
  }

  static Future<Map<String, dynamic>> _community() async {
    final m = Meta.instance;
    final cityId = Meta.idOf(m.cities, _d.city);
    if (cityId == null) {
      final supported = m.cities.map((c) => c.name).take(6).join(', ');
      throw ApiException(
        code: 'CITY_NOT_SUPPORTED',
        message: 'SyyncIn isn’t live in “${_d.city.trim()}” yet. Try: $supported${m.cities.length > 6 ? '…' : ''}',
      );
    }
    int? localityId;
    if (_d.locality.trim().isNotEmpty) {
      localityId = Meta.idOf(await m.localities(cityId), _d.locality); // unknown locality → saved without one
    }
    return {
      'cityId': cityId,
      'localityId': localityId,
      'connectMode': _modes[_d.connectMode.clamp(0, 2)],
      'radiusKm': _radii[_d.distance.clamp(0, 3)],
      'availability': (_d.availability.isEmpty ? {'Flexible'} : _d.availability).map((a) => a.toLowerCase()).toList(),
      'nearbyDiscovery': _d.nearbyDiscovery,
      'openToConnect': _d.openToConnect,
    };
  }

  static int _need(int? id, String message) => id ?? (throw ApiException(code: 'VALIDATION_ERROR', message: message));

  // ── API profile → draft ────────────────────────────────────────────
  static void _apply(Map<String, dynamic> p) {
    final d = _d;
    String? name(Object? v, [String k = 'name']) => v is Map ? v[k] as String? : null;
    List<String> names(Object? v, [String k = 'name']) => ((v as List?) ?? const []).map((e) => (e as Map)[k] as String).toList();

    d.fullName = (p['fullName'] as String?) ?? '';
    d.dateOfBirth = p['dob'] is String ? DateTime.tryParse(p['dob'] as String) : null;
    d.linkedIn = (p['linkedinUrl'] as String?) ?? '';
    d.gender = _genders[p['gender']];
    d.about = (p['about'] as String?) ?? '';
    d.photoUrl = p['photoUrl'] as String?;
    d.verificationStatus = (p['verificationStatus'] as String?) ?? 'none';

    final w = (p['work'] as Map?) ?? const {};
    d.jobTitle = (w['jobTitle'] as String?) ?? '';
    d.industry = name(w['industry']);
    d.company = (w['company'] as String?) ?? '';
    d.experience = name(w['experienceLevel'], 'label');
    d.skills = names(w['skills']).join(', ');

    d.interests
      ..clear()
      ..addAll(names(p['interests']));
    d.reasons
      ..clear()
      ..addAll(names(p['reasons'], 'title'));

    final qs = Meta.instance.questions;
    d.mindset.clear();
    for (final a in (p['mindset'] as List?) ?? const []) {
      final idx = qs.indexWhere((q) => q.id == (a as Map)['questionId']);
      if (idx >= 0) d.mindset[idx] = a['answer'] as String;
    }

    final c = (p['community'] as Map?) ?? const {};
    d.city = name(c['city']) ?? '';
    d.locality = name(c['locality']) ?? '';
    final mode = _modes.indexOf((c['connectMode'] as String?) ?? 'both');
    d.connectMode = mode < 0 ? 2 : mode;
    final radius = _radii.indexOf((c['radiusKm'] as int?) ?? 25);
    d.distance = radius < 0 ? 2 : radius;
    final avail = ((c['availability'] as List?) ?? const []).cast<String>();
    d.availability
      ..clear()
      ..addAll(avail.isEmpty ? ['Flexible'] : avail.map((a) => a[0].toUpperCase() + a.substring(1)));
    d.nearbyDiscovery = c['nearbyDiscovery'] != false;
    d.openToConnect = c['openToConnect'] != false;

    final step = (p['onboarding'] as Map?)?['step'] as int?;
    if (step != null) Session.instance.setStep(step);
    changes.value++;
  }
}
