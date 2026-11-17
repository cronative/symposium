import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syyncin/app/routes.dart';
import 'package:syyncin/core/widgets/widgets.dart';
import 'package:syyncin/features/profile_setup/interests_screen.dart';
import 'package:syyncin/main.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  testWidgets('Splash advances to Welcome', (tester) async {
    await tester.pumpWidget(const SyyncInApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Interests: Continue enables after 3 interests + 1 reason', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 1100));
    await tester.pumpWidget(const MaterialApp(home: InterestsScreen()));

    PrimaryButton cta() => tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(cta().enabled, isFalse);

    for (final i in ['Technology', 'Business', 'Design']) {
      await tester.tap(find.text(i));
    }
    await tester.tap(find.text('Grow my network'));
    await tester.pump();
    expect(find.text('3 selected · Min. 3'), findsOneWidget);
    expect(cta().enabled, isTrue);
  });

  testWidgets('BasicProfileScreen: date picker opens without assertion error', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 1100));
    await tester.pumpWidget(const SyyncInApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Move to BasicProfileScreen
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed(Routes.basicProfile);
    await tester.pumpAndSettle();

    // Tap on Date of birth picker
    await tester.tap(find.text('Date of birth'));
    await tester.pumpAndSettle();

    // Check that DatePickerDialog is displayed without errors
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
