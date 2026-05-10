// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'brand_color.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // GLASS CONTAINER
// // Wraps any widget in a backdrop-blur frosted panel.
// // BackdropFilter only creates a visible glass effect when a real image sits
// // behind it — always pair with DarkBackground inside a Stack.
// // ─────────────────────────────────────────────────────────────────────────────
// class GlassContainer extends StatelessWidget {
//   final Widget child;
//   final EdgeInsetsGeometry? padding;
//   final BorderRadius? borderRadius;
//   final Color? fillColor;
//   final Color? borderColor;
//   final double blur;
//   final VoidCallback? onTap;

//   const GlassContainer({
//     super.key,
//     required this.child,
//     this.padding,
//     this.borderRadius,
//     this.fillColor,
//     this.borderColor,
//     this.blur = 22,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final radius = borderRadius ?? BorderRadius.circular(24);

//     Widget card = ClipRRect(
//       borderRadius: radius,
//       child: BackdropFilter(
//         // This blurs the photo that sits behind the widget in the Stack.
//         // Higher sigma = more frosted. 18-24 is the sweet spot.
//         filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
//         child: Container(
//           padding: padding,
//           decoration: BoxDecoration(
//             borderRadius: radius,
//             border: Border.all(
//               color: borderColor ?? BrandColor.glassBorder,
//               width: 1,
//             ),
//             // Two-stop gradient: bright top sheen fades into the tinted fill.
//             // This is what makes it look like light is catching the glass edge.
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white.withOpacity(0.22),
//                 (fillColor ?? BrandColor.glassFill),
//               ],
//               stops: const [0.0, 0.40],
//             ),
//           ),
//           child: child,
//         ),
//       ),
//     );

//     return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // DARK BACKGROUND  ← THE KEY PIECE FOR REAL GLASSMORPHISM
// //
// // Renders a full-bleed pomegranate photo as the very bottom layer of every
// // screen's Stack. BackdropFilter in GlassContainer blurs this image — without
// // a real image behind it, the blur has nothing to show and looks like a plain
// // tinted box.
// //
// // ── FOR PRODUCTION (recommended) ──────────────────────────────────────────
// //   1. Download the photo and save to:  assets/images/pomegranate_bg.jpg
// //   2. Register the asset in pubspec.yaml:
// //        flutter:
// //          assets:
// //            - assets/images/pomegranate_bg.jpg
// //   3. Pass it in wherever you use DarkBackground:
// //        DarkBackground(
// //          imageProvider: AssetImage('assets/images/pomegranate_bg.jpg'),
// //        )
// //
// // ── FOR QUICK TESTING ─────────────────────────────────────────────────────
// //   Leave imageProvider null — it loads the photo from Pexels over the
// //   network automatically (free, no attribution required for Pexels images).
// // ─────────────────────────────────────────────────────────────────────────────
// class DarkBackground extends StatelessWidget {
//   /// Pass AssetImage('assets/images/pomegranate_bg.jpg') for production.
//   /// Leave null to load the Pexels photo over the network during development.
//   final ImageProvider? imageProvider;

//   const DarkBackground({super.key, this.imageProvider});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox.expand(
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // ── Layer 1: Full-bleed background photo ──────────────────────
//           Image(
//             image:
//                 imageProvider ??
//                const AssetImage('assets/images/pomegranate_bg.png'),
//             fit: BoxFit.cover,
//             alignment: Alignment.center,
//             // Shown while photo is loading from network
//             loadingBuilder: (_, child, progress) => progress == null
//                 ? child
//                 : Container(color: BrandColor.background),
//             // Shown if network is unavailable — gradient fallback
//             errorBuilder: (_, __, ___) => Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Color(0xFF4A0815), Color(0xFF0D0507)],
//                 ),
//               ),
//             ),
//           ),

//           // ── Layer 2: Cinematic overlay ─────────────────────────────────
//           // Darkens the photo just enough for white text to be legible while
//           // still letting the colour and texture show through glass cards.
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.black.withOpacity(0.55), // top
//                   Colors.black.withOpacity(0.30), // upper mid
//                   Colors.black.withOpacity(
//                     0.20,
//                   ), // centre — photo most visible here
//                   Colors.black.withOpacity(0.55), // lower
//                   Colors.black.withOpacity(0.82), // bottom nav
//                 ],
//                 stops: const [0.0, 0.18, 0.40, 0.68, 1.0],
//               ),
//             ),
//           ),

//           // ── Layer 3: Edge vignette ─────────────────────────────────────
//           Container(
//             decoration: BoxDecoration(
//               gradient: RadialGradient(
//                 center: Alignment.center,
//                 radius: 1.25,
//                 colors: [Colors.transparent, Colors.black.withOpacity(0.28)],
//                 stops: const [0.50, 1.0],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // DARK APP BAR
// // Fully transparent — use with extendBodyBehindAppBar: true so the photo
// // extends behind the status bar and the blur is seamless edge-to-edge.
// // ─────────────────────────────────────────────────────────────────────────────
// class DarkAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final String title;
//   final List<Widget>? actions;

//   const DarkAppBar({super.key, required this.title, this.actions});

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       centerTitle: true,
//       title: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 17,
//           fontWeight: FontWeight.w600,
//           shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
//         ),
//       ),
//       leading: Padding(
//         padding: const EdgeInsets.all(8),
//         child: GlassContainer(
//           borderRadius: BorderRadius.circular(12),
//           blur: 14,
//           onTap: () => Navigator.of(context).pop(),
//           child: const Center(
//             child: Icon(
//               Icons.arrow_back_ios_rounded,
//               color: Colors.white,
//               size: 16,
//             ),
//           ),
//         ),
//       ),
//       actions: actions,
//     );
//   }

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // SECTION LABEL
// // ─────────────────────────────────────────────────────────────────────────────
// class SectionLabel extends StatelessWidget {
//   final String label;
//   const SectionLabel({super.key, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Text(
//           label.toUpperCase(),
//           style: TextStyle(
//             fontSize: 10,
//             fontWeight: FontWeight.w700,
//             color: BrandColor.softText,
//             letterSpacing: 2.2,
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Container(
//             height: 1,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [BrandColor.glassBorder, Colors.transparent],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
