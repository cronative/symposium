// One-time Android setup for SyyncIn. Run from the project root, right after
// the Android folder is generated:
//
//   flutter create --platforms=android --org com.syyncin .
//   dart run tool/setup_android.dart
//
// Safe to run again — every change is skipped if it's already there.
import 'dart:io';

void main() {
  final android = Directory('android');
  if (!android.existsSync()) {
    stderr.writeln('No android/ folder. Run first:  flutter create --platforms=android --org com.syyncin .');
    exit(1);
  }
  _manifest();
  _gradle();
  _icons();
  stdout.writeln('\nDone. Start an emulator, then:  flutter run -d android');
}

/// Permissions, app name, and plain-http access to the local API (http://10.0.2.2:4000).
void _manifest() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  var s = f.readAsStringSync();
  const perms = [
    'android.permission.INTERNET', // API + live updates
    'android.permission.POST_NOTIFICATIONS', // Android 13+ notification prompt
    'android.permission.VIBRATE',
  ];
  // Not adding CAMERA on purpose: image_picker uses the system camera app, and
  // declaring CAMERA would force a runtime permission prompt it doesn't handle.
  final missing = perms.where((p) => !s.contains(p)).map((p) => '    <uses-permission android:name="$p" />').join('\n');
  if (missing.isNotEmpty) s = s.replaceFirstMapped(RegExp(r'(\s*)<application'), (m) => '\n$missing${m[1]}<application');
  s = s.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="SyyncIn"');
  if (!s.contains('usesCleartextTraffic')) {
    // Dev only: the local API is plain http. Remove once the API is on https.
    s = s.replaceFirst('<application', '<application\n        android:usesCleartextTraffic="true"');
  }
  f.writeAsStringSync(s);
  stdout.writeln('✓ AndroidManifest.xml — permissions, app name "SyyncIn", local http allowed');
}

/// flutter_local_notifications needs Java 8+ API desugaring.
void _gradle() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  final f = kts.existsSync() ? kts : groovy;
  final isKts = f == kts;
  var s = f.readAsStringSync();
  if (s.contains('desugar_jdk_libs')) {
    stdout.writeln('✓ ${f.path} — desugaring already set');
    return;
  }
  final enable = isKts ? 'isCoreLibraryDesugaringEnabled = true' : 'coreLibraryDesugaringEnabled true';
  if (s.contains('compileOptions {')) {
    s = s.replaceFirst('compileOptions {', 'compileOptions {\n        $enable');
  } else {
    s = s.replaceFirst(RegExp(r'android\s*\{'), 'android {\n    compileOptions {\n        $enable\n    }');
  }
  final dep = isKts
      ? 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
      : "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'";
  s = '${s.trimRight()}\n\ndependencies {\n    $dep\n}\n';
  f.writeAsStringSync(s);
  stdout.writeln('✓ ${f.path} — core library desugaring (needed by flutter_local_notifications)');
}

/// SyyncIn launcher icons (also used for notifications: @mipmap/ic_launcher).
void _icons() {
  final src = Directory('tool/android_icons');
  if (!src.existsSync()) return;
  var n = 0;
  for (final dir in src.listSync().whereType<Directory>()) {
    final name = dir.uri.pathSegments.where((p) => p.isNotEmpty).last;
    final target = Directory('android/app/src/main/res/$name')..createSync(recursive: true);
    File('${dir.path}/ic_launcher.png').copySync('${target.path}/ic_launcher.png');
    n++;
  }
  stdout.writeln('✓ App icon — SyyncIn logo in $n sizes');
}
