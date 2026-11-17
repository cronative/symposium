import '../core/network/api_client.dart';

/// Master data from GET /meta/* (managed in the admin panel), cached for the session.
/// Built-in lists are used until the API answers (or if it can't be reached).
class MetaItem {
  const MetaItem(this.id, this.name, {this.subtitle, this.icon});
  final int id;
  final String name;
  final String? subtitle;
  final String? icon;
}

class MetaQuestion {
  const MetaQuestion(this.id, this.text, this.options);
  final int id;
  final String text;
  final List<MetaItem> options;
}

class Meta {
  Meta._();
  static final instance = Meta._();

  bool loaded = false;
  List<MetaItem> industries = _seed(_industries);
  List<MetaItem> experienceLevels = _seed(_experience);
  List<MetaItem> interests = _seed(_interests);
  List<MetaItem> reasons = [
    for (var i = 0; i < _reasons.length; i++) MetaItem(i + 1, _reasons[i].$1, subtitle: _reasons[i].$2, icon: _reasons[i].$3),
  ];
  List<MetaQuestion> questions = [
    for (var i = 0; i < _questions.length; i++)
      MetaQuestion(i + 1, _questions[i].$1, [for (var j = 0; j < 4; j++) MetaItem(i * 4 + j + 1, _questions[i].$2[j])]),
  ];
  List<MetaItem> skills = const [];
  List<MetaItem> cities = const [];

  List<String> get industryNames => industries.map((e) => e.name).toList();
  List<String> get experienceNames => experienceLevels.map((e) => e.name).toList();
  List<String> get interestNames => interests.map((e) => e.name).toList();

  /// Load everything once (cheap, public endpoints). Safe to call repeatedly.
  Future<void> load({bool force = false}) async {
    if (loaded && !force) return;
    final api = ApiClient.instance;
    try {
      final r = await Future.wait([
        api.get('/meta/industries'),
        api.get('/meta/experience-levels'),
        api.get('/meta/interests'),
        api.get('/meta/reasons'),
        api.get('/meta/mindset-questions'),
        api.get('/meta/skills'),
        api.get('/meta/cities'),
      ]);
      industries = r[0].items.map((e) => MetaItem(e['id'] as int, e['name'] as String)).toList();
      experienceLevels = r[1].items.map((e) => MetaItem(e['id'] as int, e['label'] as String)).toList();
      interests = r[2].items.map((e) => MetaItem(e['id'] as int, e['name'] as String)).toList();
      reasons = r[3].items
          .map((e) => MetaItem(e['id'] as int, e['title'] as String, subtitle: e['subtitle'] as String?, icon: e['icon'] as String?))
          .toList();
      questions = r[4].items
          .map((q) => MetaQuestion(
                q['id'] as int,
                q['question'] as String,
                ((q['options'] as List?) ?? const []).map((o) => MetaItem((o as Map)['id'] as int, o['label'] as String)).toList(),
              ))
          .toList();
      skills = r[5].items.map((e) => MetaItem(e['id'] as int, e['name'] as String)).toList();
      cities = r[6].items.map((e) => MetaItem(e['id'] as int, e['name'] as String, subtitle: e['state'] as String?)).toList();
      loaded = true;
    } catch (_) {
      // keep built-in lists; screens still work and saving will report the API error
    }
  }

  /// Localities of a city (for matching what the user typed).
  Future<List<MetaItem>> localities(int cityId) async {
    final r = await ApiClient.instance.get('/meta/localities', query: {'cityId': cityId});
    return r.items.map((e) => MetaItem(e['id'] as int, e['name'] as String)).toList();
  }

  static int? idOf(List<MetaItem> list, String? name) {
    if (name == null) return null;
    final n = name.trim().toLowerCase();
    for (final e in list) {
      if (e.name.toLowerCase() == n) return e.id;
    }
    return null;
  }

  static String? nameOf(List<MetaItem> list, int? id) {
    for (final e in list) {
      if (e.id == id) return e.name;
    }
    return null;
  }

  static List<MetaItem> _seed(List<String> names) => [for (var i = 0; i < names.length; i++) MetaItem(i + 1, names[i])];

  static const _industries = [
    'Information Technology', 'Design & Creative', 'Finance & Banking', 'Marketing & Advertising', 'Healthcare', 'Education',
    'Manufacturing', 'Real Estate', 'Consulting', 'Retail & E-commerce', 'Media & Entertainment', 'Other',
  ];
  static const _experience = ['Less than 1 year', '1–2 years', '3–5 years', '6–10 years', '10+ years'];
  static const _interests = [
    'Technology', 'Business', 'Startups', 'Design', 'Marketing', 'AI', 'Product', 'Finance', 'Career growth', 'Freelancing',
    'Networking', 'Content', 'Social media', 'Travel', 'Wellness', 'Food & coffee', 'Books', 'Sports', 'Music', 'Art', 'Community',
  ];
  static const _reasons = [
    ('Grow my network', 'Meet professionals beyond my circle', 'users'),
    ('Exchange ideas', 'Have meaningful conversations', 'bulb'),
    ('Find collaborators', 'Build and work on something together', 'handshake'),
    ('Learn from others', 'Share knowledge and experiences', 'graduation'),
    ('Explore opportunities', 'Discover career and business possibilities', 'trend_up'),
    ('Meet in person', 'Connect with professionals nearby', 'coffee'),
  ];
  static const _questions = [
    ('What motivates you most?', ['Growth', 'Building', 'Impact', 'Success']),
    ('How do you approach new ideas?', ['Creative', 'Practical', 'Analytical', 'Balanced']),
    ('How do you like to connect?', ['1-to-1', 'Share ideas', 'Collaborate', 'Meet in person']),
    ('What matters most to you?', ['Trust', 'Ambition', 'Creativity', 'Knowledge']),
    ('Who would you like to meet?', ['Shared interests', 'Different skills', 'Fresh perspectives', 'Similar goals']),
  ];
}
