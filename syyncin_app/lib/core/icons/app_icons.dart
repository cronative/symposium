import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stroke icons (24×24 grid) used across the Figma screens.
/// `CUR` is replaced by the requested colour at render time.
abstract final class AppIcons {
  static const back = '<path d="M19 12H5M11 18l-6-6 6-6" stroke="CUR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>';
  static const chevronLeft = '<path d="M15 18l-6-6 6-6" stroke="CUR" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>';
  static const chevronDown = '<path d="M6 9l6 6 6-6" stroke="CUR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>';
  static const arrowRight = '<path d="M5 12h14M13 6l6 6-6 6" stroke="CUR" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>';
  static const check = '<path d="M5 12.5l4.5 4.5L19 7.5" stroke="CUR" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>';
  static const checkCircle = '<circle cx="12" cy="12" r="9.5" stroke="CUR" stroke-width="1.8"/><path d="M8 12.5l2.7 2.7L16 9.8" stroke="CUR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>';
  static const calendar = '<rect x="3.5" y="5" width="17" height="15.5" rx="2" stroke="CUR" stroke-width="1.8"/><path d="M3.5 10h17M8 3v4M16 3v4" stroke="CUR" stroke-width="1.8" stroke-linecap="round"/>';
  static const camera = '<path d="M14.5 4h-5L7.5 6.5H5A2 2 0 0 0 3 8.5v9A2 2 0 0 0 5 19.5h14a2 2 0 0 0 2-2v-9a2 2 0 0 0-2-2h-2.5L14.5 4z" stroke="CUR" stroke-width="1.8" stroke-linejoin="round"/><circle cx="12" cy="13" r="3.2" stroke="CUR" stroke-width="1.8"/>';
  static const users = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></g>';
  static const bulb = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18h6M10 22h4"/><path d="M12 2a7 7 0 0 0-4 12.7c.6.5 1 1.2 1 2V18h6v-1.3c0-.8.4-1.5 1-2A7 7 0 0 0 12 2z"/></g>';
  static const handshake = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M11 17l2 2a1 1 0 0 0 3-3"/><path d="M14 14l2.5 2.5a1 1 0 0 0 3-3l-3.88-3.88a3 3 0 0 0-4.24 0l-.88.88a1 1 0 0 1-3-3l2.81-2.81a5.79 5.79 0 0 1 7.06-.87l.47.28a2 2 0 0 0 1.42.25L21 4"/><path d="M21 3l1 11h-2M3 3L2 14l6.5 6.5a1 1 0 0 0 3-3M3 4h8"/></g>';
  static const graduation = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M22 10L12 5 2 10l10 5 10-5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></g>';
  static const trendUp = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M22 7l-8.5 8.5-5-5L2 17"/><path d="M16 7h6v6"/></g>';
  static const coffee = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M17 8h1a4 4 0 1 1 0 8h-1"/><path d="M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V8z"/><path d="M6 2v2M10 2v2M14 2v2"/></g>';
  static const sun = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></g>';
  static const smile = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="9.5"/><path d="M8 14s1.5 2 4 2 4-2 4-2M9 9h.01M15 9h.01" stroke-width="2.2"/></g>';
  static const noGlasses = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round"><circle cx="6.5" cy="14" r="3.5"/><circle cx="17.5" cy="14" r="3.5"/><path d="M10 14h4M3 3l18 18"/></g>';
  static const scanFace = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2"/><path d="M8 14s1.5 2 4 2 4-2 4-2M9 9h.01M15 9h.01"/></g>';
  static const shieldCheck = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></g>';
  static const userCheck = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M16 11l2 2 4-4"/></g>';
  static const user = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1"/></g>';

  // KYN Home · Filters · Professional Profile
  static const bell = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></g>';
  static const pin = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/></g>';
  static const sliders = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round"><path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/></g>';
  static const bookmark = '<path d="M19 21l-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" stroke="CUR" stroke-width="1.8" stroke-linejoin="round"/>';
  static const bookmarkFilled = '<path d="M19 21l-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" fill="CUR" stroke="CUR" stroke-width="1.8" stroke-linejoin="round"/>';
  static const compass = '<g stroke="CUR" stroke-width="1.8" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M16.2 7.8l-2.1 6.3-6.3 2.1 2.1-6.3z"/></g>';
  static const search = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></g>';
  static const meetups = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01M16 18h.01"/></g>';
  static const send = '<path d="M21 3 10.5 13.5M21 3l-6.5 18-4-7.5L3 9.5z" stroke="CUR" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>';
  static const chat = '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22z" stroke="CUR" stroke-width="1.8" stroke-linejoin="round"/>';
  static const userPlus = '<g stroke="CUR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6M22 11h-6"/></g>';
  static const close = '<path d="M18 6L6 18M6 6l12 12" stroke="CUR" stroke-width="2" stroke-linecap="round"/>';
  static const target = '<g stroke="CUR" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.5"/></g>';
  static const building = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 21V5a1 1 0 0 1 1-1h8a1 1 0 0 1 1 1v16M14 10h5a1 1 0 0 1 1 1v10M2 21h20"/><path d="M8 8h2M8 12h2M8 16h2"/></g>';
  static const briefcase = '<g stroke="CUR" stroke-width="1.8"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M3 13h18"/></g>';
  static const heart = '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z" stroke="CUR" stroke-width="1.8" stroke-linejoin="round"/>';
  static const pencil = '<g stroke="CUR" stroke-width="1.8" stroke-linejoin="round"><path d="M4 20h4L19 9l-4-4L4 16v4z"/><path d="M14 6l4 4"/></g>';
  static const shield = '<path d="M12 3l7 3v5c0 4.5-3 8.3-7 10-4-1.7-7-5.5-7-10V6l7-3z" stroke="CUR" stroke-width="1.8" stroke-linejoin="round"/>';
  static const info = '<g stroke="CUR" stroke-linecap="round"><circle cx="12" cy="12" r="9" stroke-width="1.8"/><path d="M12 11v5M12 8h.01" stroke-width="2"/></g>';
  static const crown = '<path d="M3 8l4.5 4L12 5l4.5 7L21 8l-2 11H5L3 8z" stroke="CUR" stroke-width="1.8" stroke-linejoin="round"/>';
  static const settings = '<g stroke="CUR" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="3"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/></g>';
  static const chevronRight = '<path d="M9 6l6 6-6 6" stroke="CUR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>';
  static const lock = '<g stroke="CUR" stroke-width="1.8"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></g>';
  static const dots = '<g fill="CUR"><circle cx="12" cy="5" r="1.7"/><circle cx="12" cy="12" r="1.7"/><circle cx="12" cy="19" r="1.7"/></g>';

  // Brand logos exported from Figma (multi-colour, never tinted).
  static const google = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M19.9322 10.2276C19.9322 9.51845 19.8675 8.83659 19.7473 8.18201H10.1694V12.0504H15.6425C15.4068 13.3005 14.6903 14.3596 13.6132 15.0688V17.578H16.8998C18.8228 15.837 19.9322 13.2732 19.9322 10.2276Z" fill="#4285F4"/><path fill-rule="evenodd" clip-rule="evenodd" d="M10.1701 20C12.9159 20 15.2179 19.1046 16.9005 17.5773L13.6139 15.0682C12.7032 15.6682 11.5384 16.0228 10.1701 16.0228C7.52142 16.0228 5.27951 14.2637 4.47981 11.9H1.08228V14.4909C2.75562 17.7591 6.19476 20 10.1701 20Z" fill="#34A853"/><path fill-rule="evenodd" clip-rule="evenodd" d="M4.47877 11.8996C4.2754 11.2997 4.15984 10.659 4.15984 10C4.15984 9.34105 4.2754 8.70027 4.47877 8.10039V5.51001H1.08156C0.392874 6.85974 0 8.3867 0 10C0 11.6133 0.392874 13.1403 1.08156 14.49L4.47877 11.8996Z" fill="#FBBC05"/><path fill-rule="evenodd" clip-rule="evenodd" d="M10.17 3.97727C11.663 3.97727 13.0035 4.48182 14.0575 5.47273L16.9742 2.60455C15.2131 0.990909 12.9111 0 10.17 0C6.19469 0 2.7556 2.24091 1.08228 5.50909L4.47977 8.1C5.27945 5.73636 7.52133 3.97727 10.17 3.97727Z" fill="#EA4335"/></svg>';
  static const linkedin = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M17.0392 17.0433H14.0775V12.4025C14.0775 11.2958 14.055 9.87167 12.5342 9.87167C10.99 9.87167 10.7542 11.0758 10.7542 12.3208V17.0433H7.7925V7.5H10.6375V8.80083H10.6758C11.0733 8.05083 12.04 7.25917 13.4842 7.25917C16.485 7.25917 17.04 9.23417 17.04 11.805L17.0392 17.0433ZM4.4475 6.19417C3.49417 6.19417 2.72833 5.4225 2.72833 4.47333C2.72833 3.525 3.495 2.75417 4.4475 2.75417C5.3975 2.75417 6.1675 3.525 6.1675 4.47333C6.1675 5.4225 5.39667 6.19417 4.4475 6.19417ZM5.9325 17.0433H2.9625V7.5H5.9325V17.0433ZM18.5208 0H1.47583C0.66 0 0 0.645 0 1.44083V18.5592C0 19.3558 0.66 20 1.47583 20H18.5183C19.3333 20 20 19.3558 20 18.5592V1.44083C20 0.645 19.3333 0 18.5183 0H18.5208Z" fill="#0A66C2"/></svg>';
  static const apple = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M10.1265 5.74667C9.33652 5.74667 8.11402 4.84833 6.82652 4.88C5.12652 4.9025 3.56818 5.86583 2.69235 7.39167C0.928181 10.4542 2.23735 14.9775 3.95818 17.4667C4.80235 18.6783 5.79818 20.0417 7.11818 19.9992C8.38485 19.945 8.85985 19.1767 10.3973 19.1767C11.9232 19.1767 12.3557 19.9992 13.6973 19.9667C15.0615 19.945 15.9273 18.7333 16.7607 17.51C17.724 16.1033 18.124 14.7392 18.1457 14.6642C18.1132 14.6533 15.494 13.6467 15.4623 10.6167C15.4407 8.08333 17.529 6.87167 17.6265 6.8175C16.4357 5.07583 14.6073 4.88083 13.9682 4.8375C12.3015 4.7075 10.9057 5.74667 10.1265 5.74667ZM12.9415 3.19167C13.644 2.34833 14.1082 1.16917 13.979 0C12.9732 0.0433333 11.7607 0.670833 11.0357 1.515C10.3857 2.26167 9.82402 3.46333 9.97485 4.61C11.0898 4.69667 12.2373 4.03667 12.9407 3.1925" fill="black"/></svg>';
}

String _hex(Color c) {
  // ignore: deprecated_member_use
  final v = c.value & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

/// Renders one of [AppIcons] at [size] in [color].
class AppIcon extends StatelessWidget {
  const AppIcon(this.body, {super.key, this.size = 24, required this.color});

  final String body;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final svg = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">'
        '${body.replaceAll('CUR', _hex(color))}</svg>';
    return SvgPicture.string(svg, width: size, height: size);
  }
}

/// Full-colour brand logo (Google / LinkedIn / Apple).
class BrandSvg extends StatelessWidget {
  const BrandSvg(this.svg, {super.key, this.size = 20});
  final String svg;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.string(svg, width: size, height: size);
}
