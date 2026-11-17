import 'package:flutter/material.dart';

import '../../app/routes.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/widgets.dart';
import '../../data/profile_sync.dart';
import 'widgets/final_step_header.dart';
import 'widgets/step_save.dart';

/// Final step — Take a selfie (mandatory, no skip).
/// Opens the front camera (web: camera or file picker), uploads to
/// POST /verification/selfie, then shows the Verified screen. Plug a liveness /
/// face-match SDK into [_takeSelfie] later.
class SelfieScreen extends StatefulWidget {
  const SelfieScreen({super.key});

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  bool _processing = false;

  Future<void> _takeSelfie() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() => _processing = true);
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final ok = await saveStep(context, () => ProfileSync.uploadSelfie(bytes, file.name, file.mimeType ?? 'image/jpeg'));
    if (!mounted) return;
    setState(() => _processing = false);
    if (ok) Navigator.of(context).pushNamedAndRemoveUntil(Routes.verified, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpace.screenH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FinalStepHeader(),
                    const SizedBox(height: 30),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: SectionHeading(
                        eyebrow: 'Identity verification',
                        title: 'Help build a community you can trust.',
                        subtitle: 'Take a clear selfie to verify your identity and help keep SyyncIn authentic.',
                        titleStyle: TextStyle(fontFamily: 'Inter', fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const _CameraPreview(),
                    const SizedBox(height: 22),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Text('For the best result', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    ),
                    const SizedBox(height: 13),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Tip(AppIcons.sun, 'Good\nlighting'),
                        _Tip(AppIcons.smile, 'Look at\nthe camera'),
                        _Tip(AppIcons.noGlasses, 'No sunglasses\nor hats'),
                        _Tip(AppIcons.scanFace, 'Face within\nthe frame'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x2, AppSpace.screen, AppSpace.x6),
              child: PrimaryButton(
                label: 'Take selfie',
                height: 52,
                radius: 5,
                loading: _processing,
                leading: const AppIcon(AppIcons.camera, size: 20, color: AppColors.white),
                onPressed: _takeSelfie,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(color: AppColors.cameraBg, borderRadius: BorderRadius.circular(17)),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 27,
            child: Container(
              width: 239,
              height: 271,
              decoration: BoxDecoration(color: AppColors.cameraPortrait, borderRadius: BorderRadius.circular(115)),
            ),
          ),
          Positioned(
            top: 21,
            child: Container(
              width: 227,
              height: 280,
              decoration: BoxDecoration(color: AppColors.cameraGuide, borderRadius: BorderRadius.circular(110)),
            ),
          ),
          Positioned(
            top: 42,
            child: Container(
              width: 186,
              height: 241,
              decoration: BoxDecoration(color: AppColors.cameraFace, borderRadius: BorderRadius.circular(95)),
              alignment: Alignment.center,
              child: const Text(
                'CAMERA PREVIEW',
                style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.sub),
              ),
            ),
          ),
          Positioned(
            top: 281,
            child: Container(
              width: 273,
              height: 31,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.cameraOverlay, borderRadius: BorderRadius.circular(15)),
              child: const Text(
                'Position your face within the frame',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.icon, this.label);
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 57,
            height: 57,
            decoration: BoxDecoration(
              color: AppColors.tipFill,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.tipStroke),
            ),
            alignment: Alignment.center,
            child: AppIcon(icon, size: 24, color: AppColors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, height: 13 / 11, color: AppColors.sub),
          ),
        ],
      ),
    );
  }
}
