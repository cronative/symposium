enum AuthMode { signup, signin }

enum ContactType { phone, email }

class OnboardingModel {
  AuthMode authMode;
  ContactType contactType;
  String countryCode;
  String phoneNumber;
  String email;
  String otpCode;
  bool isOtpVerified;

  // Step 4: Basic Profile
  String avatarUrl;
  String fullName;
  DateTime? birthDate;
  String age;
  String city;
  String bio;

  int? get calculatedAge {
    if (birthDate == null) {
      if (age.isNotEmpty) return int.tryParse(age);
      return null;
    }
    final now = DateTime.now();
    int calculated = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      calculated--;
    }
    return calculated;
  }

  // Step 5: Professional Profile
  String company;
  String role;
  String industry;
  String linkedInUrl;

  // Step 6: Interests & Intent
  List<String> currentIntents;
  List<String> interests;

  // Step 7: Privacy & Discovery
  bool enableKynDiscovery;
  int discoveryRadiusKm;
  bool isProfilePrivate;

  OnboardingModel({
    this.authMode = AuthMode.signup,
    this.contactType = ContactType.phone,
    this.countryCode = '+91',
    this.phoneNumber = '',
    this.email = '',
    this.otpCode = '',
    this.isOtpVerified = false,
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
    this.fullName = '',
    this.birthDate,
    this.age = '29',
    this.city = 'Mumbai',
    this.bio = '',
    this.company = '',
    this.role = '',
    this.industry = 'Technology & AI',
    this.linkedInUrl = '',
    List<String>? currentIntents,
    List<String>? interests,
    this.enableKynDiscovery = true,
    this.discoveryRadiusKm = 5,
    this.isProfilePrivate = false,
  })  : currentIntents = currentIntents ?? ['neighbors', 'coffee'],
        interests = interests ?? [
          'Technology & AI',
          'Product & Design',
          'Books & Philosophy'
        ];
}
