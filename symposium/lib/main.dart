import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/onboarding_data.dart';
import 'screens/auth.dart';
import 'screens/intro.dart';
import 'screens/onboarding.dart';
import 'screens/location.dart';

void main() {WidgetsFlutterBinding.ensureInitialized();runApp(const SymposiumApp());}

class SymposiumApp extends StatefulWidget {
  const SymposiumApp({super.key});
  @override State<SymposiumApp> createState()=>_SymposiumAppState();
}
class _SymposiumAppState extends State<SymposiumApp> {
  final data=OnboardingData();
  @override void dispose(){data.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>MaterialApp(
    title:'Symposium',debugShowCheckedModeBanner:false,theme:buildAppTheme(),initialRoute:Routes.welcome,
    routes:{
      Routes.welcome:(_)=>const WelcomeScreen(),
      Routes.login:(_)=>LoginScreen(data:data),
      Routes.otp:(_)=>OtpScreen(data:data),
      Routes.intro:(_)=>const KynIntroScreen(),
      Routes.basic:(_)=>BasicProfileScreen(data:data),
      Routes.professional:(_)=>ProfessionalProfileScreen(data:data),
      Routes.interests:(_)=>InterestsScreen(data:data),
      Routes.location:(_)=>ConnectionLocationScreen(data:data),
      Routes.permission:(_)=>LocationPermissionScreen(data:data),
      Routes.home:(_)=>HomePreviewScreen(data:data),
    },
  );
}
