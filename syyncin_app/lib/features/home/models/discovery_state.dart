import 'package:flutter/foundation.dart';

/// `match` = SyyncScore (best match first) — the default.
enum SortBy { match, nearest, name, newest }

/// Values chosen on the Filters screen → query params for GET /discover.
@immutable
class DiscoveryFilters {
  const DiscoveryFilters({
    this.industryId,
    this.maxDistanceKm = 25,
    this.interestIds = const {},
    this.experienceLevelId,
    this.cityId,
    this.sortBy = SortBy.match,
  });

  final int? industryId; // null = all professions
  final double maxDistanceKm;
  final Set<int> interestIds;
  final int? experienceLevelId; // null = any
  final int? cityId; // null = my city (API default)
  final SortBy sortBy;

  static const defaults = DiscoveryFilters();

  /// Number of non-default filters (badge on the filter button).
  int get activeCount =>
      (industryId != null ? 1 : 0) +
      (maxDistanceKm != 25 ? 1 : 0) +
      (interestIds.isNotEmpty ? 1 : 0) +
      (experienceLevelId != null ? 1 : 0) +
      (cityId != null ? 1 : 0) +
      (sortBy != SortBy.match ? 1 : 0);

  DiscoveryFilters copyWith({
    int? industryId,
    bool clearIndustry = false,
    double? maxDistanceKm,
    Set<int>? interestIds,
    int? experienceLevelId,
    bool clearExperience = false,
    int? cityId,
    SortBy? sortBy,
  }) =>
      DiscoveryFilters(
        industryId: clearIndustry ? null : (industryId ?? this.industryId),
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
        interestIds: interestIds ?? this.interestIds,
        experienceLevelId: clearExperience ? null : (experienceLevelId ?? this.experienceLevelId),
        cityId: cityId ?? this.cityId,
        sortBy: sortBy ?? this.sortBy,
      );

  Map<String, dynamic> toQuery() => {
        'industryId': industryId,
        'maxDistanceKm': maxDistanceKm.round(),
        'interestIds': interestIds.isEmpty ? null : interestIds.join(','),
        'experienceLevelId': experienceLevelId,
        'cityId': cityId,
        'sort': sortBy.name,
      };
}

enum InboxSegment { all, requests, connections, messages }

/// Cross-screen navigation state (bottom tab + inbox segment), e.g. so a
/// notification tap or the "View" action can jump straight to Inbox → Requests.
abstract final class AppNav {
  static final homeTab = ValueNotifier<int>(0);
  static final inboxSegment = ValueNotifier<InboxSegment>(InboxSegment.all);
  static final inboxShowSent = ValueNotifier<bool>(false);

  static void openInbox(InboxSegment segment, {bool sent = false}) {
    inboxSegment.value = segment;
    inboxShowSent.value = sent;
    homeTab.value = 3;
  }
}
