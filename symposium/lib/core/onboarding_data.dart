import 'package:flutter/foundation.dart';

/// Temporary local onboarding state. Connect to your API/repository later.
class OnboardingData extends ChangeNotifier {
  String contact = '';
  String name = '';
  DateTime? dob;
  String gender = '';
  String profession = '';
  String industry = '';
  String company = '';
  String experience = '';
  String skills = '';
  final Set<String> interests = {};
  String homeCity = '';
  String locality = '';
  String connectionGoal = '';
  String meetingPreference = '';
  String currentCity = '';
  double? latitude;
  double? longitude;
  bool locationGranted = false;
  void changed() => notifyListeners();
}
