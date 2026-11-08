import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// حالة اتصال Firebase. التطبيق يستطيع عرض الواجهة حتى لو تعذر الاتصال بالخادم.
bool firebaseReady = false;
String? firebaseInitError;

// ═════════════════════════════════════════════════════════════════════════
//  طبيبك — تطبيق المستخدمين (نسخة محدّثة)
//  • تصميم جديد: خط IBM Plex Sans Arabic، كروت وأزرار وأيقونات عصرية.
//  • كل الأزرار تعمل: الحجز، الدفع، الإلغاء، إعادة الجدولة، المفضلة، العناوين...
//  • البيانات محلية في الذاكرة (AppState) ولا يوجد خادم حقيقي بعد.
//  • الاتصال/المشاركة/تحميل PDF تحتاج حزم (url_launcher / share_plus / pdf)،
//    لذلك تعمل هنا بالنسخ للحافظة أو بمحاكاة التحميل.
// ═════════════════════════════════════════════════════════════════════════

// ───────────────────────── Design tokens ─────────────────────────
const kRed = Color(0xFFD9141E);
const kInk = Color(0xFF1B2A4A);
const kGrey = Color(0xFF7B8494);
const kSub = Color(0xFF4B5873);
const kLine = Color(0xFFE9EDF2);
const kBg = Color(0xFFF6F7FB);
const kChip = Color(0xFFF1F3F7);
const kTint = Color(0xFFFDECEE);
const kGreen = Color(0xFF2EAD5C);
const kGreenDk = Color(0xFF2A8F4F);
const kGreenBg = Color(0xFFD9F3E1);
const kAmber = Color(0xFFB7791F);
const kAmberBg = Color(0xFFFFF1D6);
const kGold = Color(0xFFFFB400);
const kBlue = Color(0xFF3B6EF5);
const kBlueBg = Color(0xFFE9EFFF);
const kTeal = Color(0xFF0E9F8E);
const kTealBg = Color(0xFFDDF5F1);
const kOrange = Color(0xFFF2780C);
const kOrangeBg = Color(0xFFFFEEDB);
const kPurple = Color(0xFF7C4DDB);
const kPurpleBg = Color(0xFFEEE8FB);

const kGradient = LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFFF2434D), Color(0xFFC40F1A)]);
const kShadow = [BoxShadow(color: Color(0x141B2A4A), blurRadius: 24, offset: Offset(0, 10)), BoxShadow(color: Color(0x0A1B2A4A), blurRadius: 3, offset: Offset(0, 1))];
const kGlow = [BoxShadow(color: Color(0x40D9141E), blurRadius: 20, offset: Offset(0, 10))];

LinearGradient grad(Color c) => LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c, Color.alphaBlend(const Color(0x40000000), c)]);

const kFont = 'IBM Plex Sans Arabic';

TextStyle t(double s, {FontWeight w = FontWeight.w700, Color c = kInk, double? h}) {
  try {
    return GoogleFonts.getFont(kFont, fontSize: s, fontWeight: w, color: c, height: h);
  } catch (_) {
    return GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: h);
  }
}

TextTheme appTextTheme() {
  final base = ThemeData.light().textTheme;
  try {
    return GoogleFonts.getTextTheme(kFont, base);
  } catch (_) {
    return GoogleFonts.cairoTextTheme(base);
  }
}

// ───────────────────────── Small helpers ─────────────────────────
Future<T?> go<T>(BuildContext c, Widget w) => Navigator.push<T>(c, MaterialPageRoute<T>(builder: (_) => w));
void home(BuildContext c) => Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);

Icon chev([Color c = kRed, double s = 24]) => Icon(Icons.chevron_left_rounded, color: c, size: s, textDirection: TextDirection.ltr);
Icon chevR([Color c = kRed, double s = 24]) => Icon(Icons.chevron_right_rounded, color: c, size: s, textDirection: TextDirection.ltr);

String money(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
int toInt(String s) => int.tryParse(s.replaceAll(',', '')) ?? 0;
Widget gap([double h = 12]) => SizedBox(height: h);
Widget gapW([double w = 10]) => SizedBox(width: w);
String initial(String n) {
  final p = n.replaceFirst('د. ', '').trim();
  return p.isEmpty ? '؟' : p.substring(0, 1);
}

const kWeek = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const kMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
String dayLabel(DateTime d) => '${kWeek[d.weekday - 1]} ${d.day} ${kMonths[d.month - 1]}';

void snack(BuildContext c, String m, {bool ok = false}) {
  final sm = ScaffoldMessenger.of(c);
  sm.hideCurrentSnackBar();
  sm.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: kInk,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Row(children: [
      Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded, color: ok ? const Color(0xFF5BD68A) : Colors.white, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(m, style: t(13, w: FontWeight.w600, c: Colors.white))),
    ]),
  ));
}

Future<bool> confirm(BuildContext c, String title, String body, {String yes = 'تأكيد', String no = 'تراجع', bool danger = true}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          tileIcon(danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded, size: 60),
          gap(14),
          Text(title, textAlign: TextAlign.center, style: t(17)),
          gap(6),
          Text(body, textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: kGrey, h: 1.6)),
          gap(20),
          RedButton(yes, height: 48, onTap: () => Navigator.pop(ctx, true)),
          gap(10),
          OutBtn(no, onTap: () => Navigator.pop(ctx, false)),
        ]),
      ),
    ),
  );
  return r ?? false;
}

Future<T?> sheet<T>(BuildContext c, Widget child) => showModalBottomSheet<T>(
      context: c,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 42, height: 4, decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(2))),
            gap(16),
            child,
          ]),
        ),
      ),
    );

/// يعرض رقم/بريد مع زر نسخ (بديل الاتصال المباشر بدون حزم إضافية).
void contactSheet(BuildContext c, String title, String value, {IconData icon = Icons.phone_rounded}) {
  sheet(
    c,
    Column(children: [
      tileIcon(icon, size: 62),
      gap(12),
      Text(title, style: t(16)),
      gap(6),
      Directionality(textDirection: TextDirection.ltr, child: Text(value, style: t(21, c: kRed))),
      gap(18),
      RedButton('نسخ', icon: Icons.content_copy_rounded, onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        Navigator.pop(c);
        snack(c, 'تم النسخ إلى الحافظة', ok: true);
      }),
    ]),
  );
}

// ───────────────────────── Tap (tactile press) ─────────────────────────
class Tap extends StatefulWidget {
  const Tap({super.key, required this.child, this.onTap, this.scale = .96});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool down = false;
  void press(bool v) {
    if (down != v) setState(() => down = v);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: on ? (_) => press(true) : null,
      onTapUp: on ? (_) => press(false) : null,
      onTapCancel: on ? () => press(false) : null,
      onTap: on
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(scale: down ? widget.scale : 1, duration: const Duration(milliseconds: 100), child: widget.child),
    );
  }
}

// ───────────────────────── Buttons ─────────────────────────
class RedButton extends StatelessWidget {
  const RedButton(this.text, {super.key, required this.onTap, this.icon, this.arrow = false, this.height = 54, this.loading = false, this.enabled = true});
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final bool arrow, loading, enabled;
  final double height;
  @override
  Widget build(BuildContext context) {
    final on = enabled && !loading;
    return Semantics(
      button: true,
      enabled: on,
      label: text,
      child: Tap(
        onTap: on ? onTap : null,
        child: Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: on ? kGradient : null,
            color: on ? null : const Color(0xFFD5DAE2),
            borderRadius: BorderRadius.circular(18),
            boxShadow: on ? kGlow : null,
          ),
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                  Text(text, style: t(16, c: Colors.white)),
                  if (arrow) ...[const SizedBox(width: 8), const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)],
                ]),
        ),
      ),
    );
  }
}

/// زر أخضر للحجز المتاح عبر التطبيق (مركز مسجّل عندنا).
class GreenButton extends StatelessWidget {
  const GreenButton(this.text, {super.key, required this.onTap, this.height = 46, this.icon});
  final String text;
  final VoidCallback onTap;
  final double height;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: text,
        child: Tap(
          onTap: onTap,
          child: Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(gradient: grad(kGreen), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: kGreen.withAlpha(70), blurRadius: 14, offset: const Offset(0, 6))]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: 19), const SizedBox(width: 7)],
              Text(text, style: t(15, c: Colors.white)),
            ]),
          ),
        ),
      );
}

class OutBtn extends StatelessWidget {
  const OutBtn(this.text, {super.key, required this.onTap, this.height = 48, this.icon, this.danger = false});
  final String text;
  final VoidCallback onTap;
  final double height;
  final IconData? icon;
  final bool danger;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: text,
        child: Tap(
          onTap: onTap,
          child: Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: danger ? kTint : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kRed.withAlpha(danger ? 0 : 200), width: 1.4)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, color: kRed, size: 19), const SizedBox(width: 7)],
              Text(text, style: t(14.5, c: kRed)),
            ]),
          ),
        ),
      );
}

Widget ring(double s, Color c) => Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: c));

/// Translucent round button used on gradient headers.
Widget glass(Widget icon, VoidCallback onTap, {Color bg = const Color(0x2EFFFFFF)}) => Tap(
      onTap: onTap,
      child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: icon),
    );

// ───────────────────────── Icons / tiles / pills ─────────────────────────
Widget tileIcon(IconData i, {double size = 44, Color color = kRed, Color bg = kTint}) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .32)),
      child: Icon(i, color: color, size: size * .5),
    );

/// Gradient tile with a soft highlight (hero icons).
Widget gTile(IconData i, {double size = 56, Color color = kRed}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: grad(color), borderRadius: BorderRadius.circular(size * .32), boxShadow: [BoxShadow(color: color.withAlpha(70), blurRadius: 14, offset: const Offset(0, 7))]),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(top: -size * .22, right: -size * .22, child: ring(size * .7, const Color(0x24FFFFFF))),
        Icon(i, color: Colors.white, size: size * .5),
      ]),
    );

Widget pill(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: t(11.5, c: fg)),
    );
Widget pillOk(String s) => pill(s, kGreenBg, kGreenDk);
Widget pillWarn(String s) => pill(s, kAmberBg, kAmber);

Widget statusPill(String s) {
  switch (s) {
    case 'مؤكد':
    case 'مكتمل':
      return pillOk(s);
    case 'قيد التأكيد':
    case 'قيد التنفيذ':
      return pillWarn(s);
    case 'ملغي':
      return pill(s, kTint, kRed);
    default:
      return pill(s, kChip, kInk);
  }
}

BoxDecoration cardBox([double r = 22, Color color = Colors.white]) => BoxDecoration(color: color, borderRadius: BorderRadius.circular(r), boxShadow: kShadow, border: Border.all(color: const Color(0xFFF1F3F7)));

Widget sec(String s) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 10), child: Text(s, style: t(15.5)));
Widget secRow(String s, {String? more, VoidCallback? onMore}) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(children: [
        Expanded(child: Text(s, style: t(15.5))),
        if (more != null) Tap(onTap: onMore, child: Text(more, style: t(12.5, c: kRed))),
      ]),
    );

Widget panel(List<Widget> ch) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardBox(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: ch),
    );
Widget group(List<Widget> ch) => Container(margin: const EdgeInsets.only(bottom: 4), decoration: cardBox(20), clipBehavior: Clip.antiAlias, child: Column(children: ch));

Widget kv(String k, String v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: t(13, w: FontWeight.w500, c: kGrey)),
        const SizedBox(width: 12),
        Expanded(child: Text(v, textDirection: v.startsWith('+') ? TextDirection.ltr : null, textAlign: TextAlign.end, style: t(13.5, w: bold ? FontWeight.w800 : FontWeight.w700, c: bold ? kRed : kInk))),
      ]),
    );

Widget two(String a, String b) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(a, style: t(15)),
      const SizedBox(height: 1),
      Text(b, textDirection: b.startsWith('+') ? TextDirection.ltr : null, style: t(12, w: FontWeight.w500, c: kGrey)),
    ]);

Widget menuRow(IconData i, String s, {Widget? trailing, VoidCallback? onTap, Color color = kRed, Color text = kInk}) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          tileIcon(i, size: 38, color: color, bg: color == kRed ? kTint : color.withAlpha(30)),
          const SizedBox(width: 14),
          Expanded(child: Text(s, style: t(14, w: FontWeight.w600, c: text))),
          trailing ?? chev(kGrey, 20),
        ]),
      ),
    );

Widget cnt(String n) => Row(mainAxisSize: MainAxisSize.min, children: [pill(n, kChip, kInk), const SizedBox(width: 6), chev(kGrey, 20)]);

Widget stars(double v, {double size = 16}) => Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 5; i++) Icon(i < v.round() ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: i < v.round() ? kGold : const Color(0xFFD6DBE6)),
    ]);

// ───────────────────────── Image with graceful fallback ─────────────────────────
class Pic extends StatelessWidget {
  const Pic(this.asset, {super.key, this.size = 64, this.height, this.radius = 999, this.icon = Icons.person_rounded, this.label});
  final String asset;
  final double size, radius;
  final double? height;
  final IconData icon;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final h = height ?? size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        width: size,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: h,
          alignment: Alignment.center,
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFFFFE4E6), Color(0xFFFBC9CD)])),
          child: label != null ? Text(initial(label!), style: t(size * .4, c: kRed)) : Icon(icon, size: size * .5, color: kRed),
        ),
      ),
    );
  }
}

// ───────────────────────── Decorative hero pieces ─────────────────────────
class HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final heart = Path()
      ..moveTo(w * .5, h * .93)
      ..cubicTo(w * -.1, h * .52, w * .1, h * -.04, w * .5, h * .27)
      ..cubicTo(w * .9, h * -.04, w * 1.1, h * .52, w * .5, h * .93)
      ..close();
    canvas.drawPath(heart, Paint()..shader = kGradient.createShader(Offset.zero & s));
    final ecg = Path()
      ..moveTo(w * .1, h * .5)
      ..lineTo(w * .36, h * .5)
      ..lineTo(w * .43, h * .32)
      ..lineTo(w * .54, h * .68)
      ..lineTo(w * .61, h * .45)
      ..lineTo(w * .66, h * .5)
      ..lineTo(w * .9, h * .5);
    canvas.drawPath(
        ecg,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .04
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// Concentric rings + a centre tile: the modern replacement for the old stock photo.
class Orb extends StatelessWidget {
  const Orb(this.child, {super.key, this.size = 240, this.onDark = false, this.white = false});
  final Widget child;
  final double size;
  final bool onDark, white;
  @override
  Widget build(BuildContext context) {
    final cols = onDark ? const [Color(0x14FFFFFF), Color(0x1FFFFFFF), Color(0x2EFFFFFF)] : const [Color(0x0DD9141E), Color(0x14D9141E), Color(0x1FD9141E)];
    final plain = white || onDark;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        ring(size, cols[0]),
        ring(size * .78, cols[1]),
        ring(size * .58, cols[2]),
        Container(
          width: size * .4,
          height: size * .4,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: plain ? null : kGradient,
            color: plain ? Colors.white : null,
            borderRadius: BorderRadius.circular(size * .12),
            boxShadow: plain ? const [BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 12))] : kGlow,
          ),
          child: child,
        ),
      ]),
    );
  }
}

Widget floatChip(IconData i, String s, Color c) => Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: kShadow),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: c.withAlpha(30), shape: BoxShape.circle), child: Icon(i, color: c, size: 16)),
        const SizedBox(width: 8),
        Text(s, style: t(12.5)),
      ]),
    );

// ───────────────────────── Page scaffolds ─────────────────────────
/// Gradient header (back on the left, optional action on the right) + rounded sheet.
class RedPage extends StatelessWidget {
  const RedPage({super.key, required this.title, required this.body, this.nav, this.action, this.bottomBar, this.back = true});
  final String title;
  final Widget body;
  final Widget? nav, action, bottomBar;
  final bool back;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kRed,
        body: Container(
          decoration: const BoxDecoration(gradient: kGradient),
          child: Stack(children: [
            Positioned(top: -70, left: -50, child: ring(200, const Color(0x14FFFFFF))),
            Positioned(top: 24, right: -60, child: ring(150, const Color(0x0FFFFFFF))),
            Column(children: [
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 64,
                  child: Row(children: [
                    SizedBox(width: 68, child: Center(child: action)),
                    Expanded(child: Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(19, c: Colors.white))),
                    SizedBox(
                      width: 68,
                      child: Center(
                        child: back ? glass(const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28, textDirection: TextDirection.ltr), () => Navigator.maybePop(context)) : null,
                      ),
                    ),
                  ]),
                ),
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                  child: Column(children: [Expanded(child: body), if (bottomBar != null) bottomBar!, if (nav != null) nav!]),
                ),
              ),
            ]),
          ]),
        ),
      );
}

/// White bar with the main call-to-action(s) pinned to the bottom of a page.
Widget btnBar(BuildContext c, String text, VoidCallback onTap, {String? alt, VoidCallback? onAlt, bool enabled = true, bool loading = false, IconData? icon, Widget? lead}) => Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(c).padding.bottom + 12),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (lead != null) ...[lead, const SizedBox(height: 10)],
        RedButton(text, onTap: onTap, enabled: enabled, loading: loading, icon: icon),
        if (alt != null) ...[const SizedBox(height: 10), OutBtn(alt, onTap: onAlt ?? () {})],
      ]),
    );

class AppNav extends StatelessWidget {
  const AppNav({super.key, this.active = const {0}});
  final Set<int> active;
  static const items = [
    (Icons.home_rounded, Icons.home_outlined, 'الرئيسية'),
    (Icons.event_available_rounded, Icons.event_available_outlined, 'حجوزاتي'),
    (Icons.notifications_rounded, Icons.notifications_none_rounded, 'إشعارات'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'حسابي'),
  ];

  void open(BuildContext c, int i) {
    if (i == 0) {
      Navigator.popUntil(c, (r) => r.isFirst);
      return;
    }
    if (active.contains(i)) return;
    final Widget page = i == 1 ? const AppointmentsScreen() : (i == 2 ? const NotificationsScreen() : const ProfileScreen());
    Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => page), (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -5))]),
          child: SafeArea(
            top: false,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Row(children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: Tap(
                        onTap: () => open(c, i),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                            decoration: BoxDecoration(color: active.contains(i) ? kTint : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                            child: Stack(clipBehavior: Clip.none, children: [
                              Icon(active.contains(i) ? items[i].$1 : items[i].$2, size: 24, color: active.contains(i) ? kRed : kGrey),
                              if (i == 2 && app.unread > 0)
                                Positioned(
                                  top: -3,
                                  right: -5,
                                  child: Container(
                                    width: 15,
                                    height: 15,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: kRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                    child: Text('${app.unread}', style: t(8.5, c: Colors.white)),
                                  ),
                                ),
                            ]),
                          ),
                          const SizedBox(height: 2),
                          Text(items[i].$3, style: t(10.5, w: active.contains(i) ? FontWeight.w700 : FontWeight.w500, c: active.contains(i) ? kRed : kGrey)),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      );
}

// ───────────────────────── Inputs ─────────────────────────
class AppSearch extends StatelessWidget {
  const AppSearch(this.hint, {super.key, this.controller, this.onChanged, this.onTap, this.readOnly = false, this.autofocus = false, this.fill = const Color(0xFFF1F3F8), this.trailing});
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly, autofocus;
  final Color fill;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: kGrey, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              autofocus: autofocus,
              onTap: onTap,
              onChanged: onChanged,
              style: t(14, w: FontWeight.w500),
              decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: hint, hintStyle: t(13.5, w: FontWeight.w500, c: kGrey), contentPadding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          if (controller != null)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              builder: (_, v, __) => v.text.isEmpty
                  ? const SizedBox(width: 6)
                  : Tap(
                      onTap: () {
                        controller!.clear();
                        onChanged?.call('');
                      },
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.close_rounded, color: kGrey, size: 20)),
                    ),
            ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Horizontal scrolling filter chips (controlled by the parent).
class FilterChips extends StatelessWidget {
  const FilterChips(this.items, {super.key, required this.sel, required this.onChanged});
  final List<String> items;
  final int sel;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => Tap(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: i == sel ? kGradient : null,
                color: i == sel ? null : Colors.white,
                borderRadius: BorderRadius.circular(21),
                border: i == sel ? null : Border.all(color: kLine),
                boxShadow: i == sel ? kGlow : null,
              ),
              child: Text(items[i], style: t(13.5, w: i == sel ? FontWeight.w700 : FontWeight.w600, c: i == sel ? Colors.white : kSub)),
            ),
          ),
        ),
      );
}

class AppField extends StatelessWidget {
  const AppField(this.label, {super.key, this.controller, this.hint, this.icon, this.type, this.lines = 1, this.ltr = false, this.error, this.readOnly = false, this.onTap, this.prefixText, this.onChanged, this.maxLength, this.fmt});
  final String label;
  final TextEditingController? controller;
  final String? hint, error, prefixText;
  final IconData? icon;
  final TextInputType? type;
  final int lines;
  final bool ltr, readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final List<TextInputFormatter>? fmt;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 14, bottom: 7), child: Text(label, style: t(12.5, c: kSub))),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: error != null ? kRed : kLine, width: error != null ? 1.5 : 1)),
          child: TextField(
            controller: controller,
            keyboardType: type,
            maxLines: lines,
            maxLength: maxLength,
            inputFormatters: fmt,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: ltr ? TextAlign.left : TextAlign.start,
            style: t(14, w: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: hint,
              hintStyle: t(13, w: FontWeight.w500, c: kGrey),
              prefixIcon: icon == null ? null : Icon(icon, color: kGrey, size: 20),
              prefixText: prefixText,
              prefixStyle: t(14, w: FontWeight.w700, c: kInk),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 5, right: 4), child: Text(error!, style: t(11.5, w: FontWeight.w600, c: kRed))),
      ]);
}

class ChipWrap extends StatefulWidget {
  const ChipWrap(this.items, {super.key, this.sel = const {0}, this.multi = false, this.onChanged});
  final List<String> items;
  final Set<int> sel;
  final bool multi;
  final ValueChanged<Set<int>>? onChanged;
  @override
  State<ChipWrap> createState() => _ChipWrapState();
}

class _ChipWrapState extends State<ChipWrap> {
  late Set<int> s = {...widget.sel};
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < widget.items.length; i++)
          Tap(
            onTap: () {
              setState(() {
                if (widget.multi) {
                  if (s.contains(i)) {
                    s.remove(i);
                  } else {
                    s.add(i);
                  }
                } else {
                  s = {i};
                }
              });
              widget.onChanged?.call({...s});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: s.contains(i) ? kGradient : null,
                color: s.contains(i) ? null : Colors.white,
                border: s.contains(i) ? null : Border.all(color: kLine),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.multi && s.contains(i)) ...[const Icon(Icons.check_rounded, color: Colors.white, size: 15), const SizedBox(width: 5)],
                Text(widget.items[i], style: t(13, w: FontWeight.w600, c: s.contains(i) ? Colors.white : kSub)),
              ]),
            ),
          ),
      ]);
}

class RadioPick extends StatefulWidget {
  const RadioPick(this.items, {super.key, this.sel = 0, this.onChanged});
  final List<(String, String)> items;
  final int sel;
  final ValueChanged<int>? onChanged;
  @override
  State<RadioPick> createState() => _RadioPickState();
}

class _RadioPickState extends State<RadioPick> {
  late int s = widget.sel;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < widget.items.length; i++)
          Tap(
            scale: .985,
            onTap: () {
              setState(() => s = i);
              widget.onChanged?.call(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: s == i ? const Color(0xFFFFF5F6) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: s == i ? kRed : kLine, width: 1.5)),
              child: Row(children: [
                Icon(s == i ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: s == i ? kRed : kGrey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.items[i].$1, style: t(14)),
                    if (widget.items[i].$2.isNotEmpty) Text(widget.items[i].$2, style: t(11.5, w: FontWeight.w500, c: kGrey)),
                  ]),
                ),
              ]),
            ),
          ),
      ]);
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.icon, this.title, this.sub, {super.key, this.btn, this.onTap});
  final IconData icon;
  final String title, sub;
  final String? btn;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Orb(Icon(icon, color: Colors.white, size: 34), size: 160),
            gap(10),
            Text(title, textAlign: TextAlign.center, style: t(17)),
            gap(6),
            Text(sub, textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: kGrey, h: 1.6)),
            if (btn != null) ...[gap(20), SizedBox(width: 230, child: RedButton(btn!, height: 48, onTap: onTap ?? () {}))],
          ]),
        ),
      );
}

// ───────────────────────── Date helpers & pickers ─────────────────────────
/// Next 7 days (from tomorrow) + time slots. Callback gives (dayLabel, time).
class SchedulePicker extends StatefulWidget {
  const SchedulePicker({super.key, this.onChanged, this.showTime = true, this.work});
  final ValueChanged<(String, String)>? onChanged;
  final bool showTime;

  /// عند تحديده تُؤخذ الأيام والأوقات من جدول الطبيب في هذا المركز (أيام عمله وساعاته كما ضبطها المركز)؛
  /// وإلا تبقى الخيارات الافتراضية (للأسرّة والخدمات المنزلية).
  final Work? work;
  static const times = ['4:00 م', '4:30 م', '5:00 م', '5:30 م', '6:00 م', '7:30 م'];

  static List<DateTime> datesFor(Work? w) {
    final now = DateTime.now();
    if (w == null) return [for (var i = 1; i <= 7; i++) now.add(Duration(days: i))];
    final out = <DateTime>[];
    for (var i = 1; i <= 28 && out.length < 7; i++) {
      final d = now.add(Duration(days: i));
      if (w.days.contains(satIdx(d))) out.add(d);
    }
    return out.isEmpty ? [now.add(const Duration(days: 1))] : out;
  }

  /// مواعيد كل 30 دقيقة داخل ساعات دوام الطبيب.
  static List<String> timesFor(Work? w) {
    if (w == null) return times;
    final l = <String>[];
    for (var m = w.from; m + 30 <= w.to; m += 30) {
      l.add(fmtTime(m));
    }
    return l.isEmpty ? times : l;
  }

  static List<DateTime> get dates => datesFor(null);
  static (String, String) initial([Work? w]) {
    final d = datesFor(w), tm = timesFor(w);
    return (dayLabel(d[0]), tm[tm.length > 1 ? 1 : 0]);
  }
  @override
  State<SchedulePicker> createState() => _SchedulePickerState();
}

class _SchedulePickerState extends State<SchedulePicker> {
  late final List<DateTime> dates = SchedulePicker.datesFor(widget.work);
  late final List<String> times = SchedulePicker.timesFor(widget.work);
  late int day = 0, time = times.length > 1 ? 1 : 0;
  void pick(int d, int tm) {
    setState(() {
      day = d;
      time = tm;
    });
    widget.onChanged?.call((dayLabel(dates[d]), times[tm]));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sec('اختر اليوم'),
      SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dates.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => Tap(
            onTap: () => pick(i, time),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 66,
              decoration: BoxDecoration(
                gradient: i == day ? kGradient : null,
                color: i == day ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: i == day ? null : Border.all(color: kLine),
                boxShadow: i == day ? kGlow : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(kWeek[dates[i].weekday - 1], style: t(11, w: FontWeight.w600, c: i == day ? Colors.white : kGrey)),
                Text('${dates[i].day}', style: t(22, c: i == day ? Colors.white : kInk, h: 1.3)),
              ]),
            ),
          ),
        ),
      ),
      if (widget.showTime) ...[
        sec('اختر الوقت'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: [
            for (var i = 0; i < times.length; i++)
              Tap(
                onTap: () => pick(day, i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: i == time ? kGradient : null,
                    color: i == time ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: i == time ? null : Border.all(color: kLine),
                  ),
                  child: Text(times[i], style: t(13.5, c: i == time ? Colors.white : kInk)),
                ),
              ),
          ],
        ),
      ],
    ]);
  }
}

/// Wheel date picker (no localization package needed). Returns "dd / mm / yyyy".
Future<String?> pickDob(BuildContext c) async {
  final now = DateTime.now();
  var d = 15, m = 5, y = now.year - 30;
  final years = [for (var i = now.year; i >= now.year - 100; i--) i];
  final dc = FixedExtentScrollController(initialItem: d - 1);
  final mc = FixedExtentScrollController(initialItem: m - 1);
  final yc = FixedExtentScrollController(initialItem: years.indexOf(y));
  Widget wheel(FixedExtentScrollController ctl, List<String> items, ValueChanged<int> on, {int flex = 1}) => Expanded(
        flex: flex,
        child: CupertinoPicker(
          scrollController: ctl,
          itemExtent: 38,
          onSelectedItemChanged: on,
          children: [for (final s in items) Center(child: Text(s, style: t(16, w: FontWeight.w600)))],
        ),
      );
  final r = await sheet<String>(
    c,
    Column(children: [
      Text('تاريخ الميلاد', style: t(16)),
      gap(8),
      SizedBox(
        height: 190,
        child: Row(children: [
          wheel(dc, [for (var i = 1; i <= 31; i++) '$i'], (v) => d = v + 1),
          wheel(mc, kMonths, (v) => m = v + 1, flex: 2),
          wheel(yc, [for (final v in years) '$v'], (v) => y = years[v], flex: 2),
        ]),
      ),
      gap(10),
      Builder(
        builder: (ctx) => RedButton('تأكيد', onTap: () {
          final dd = d.toString().padLeft(2, '0'), mm = m.toString().padLeft(2, '0');
          Navigator.pop(ctx, '$dd / $mm / $y');
        }),
      ),
    ]),
  );
  return r;
}

/// Vertical timeline: (title, subtitle, state) where state 1 = done, 2 = current, 0 = pending.
Widget timeline(List<(String, String, int)> steps) => Column(children: [
      for (var i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: steps[i].$3 == 1 ? kRed : (steps[i].$3 == 2 ? Colors.white : const Color(0xFFE3E7EE)),
                  border: steps[i].$3 == 2 ? Border.all(color: kRed, width: 3) : null,
                ),
                child: steps[i].$3 == 1 ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null,
              ),
              if (i < steps.length - 1) Expanded(child: Container(width: 2, color: steps[i].$3 == 1 ? kRed : const Color(0xFFE3E7EE))),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(steps[i].$1, style: t(13.5, c: steps[i].$3 == 0 ? kGrey : kInk)),
                  if (steps[i].$2.isNotEmpty) Text(steps[i].$2, style: t(11.5, w: FontWeight.w500, c: kGrey)),
                ]),
              ),
            ),
          ]),
        ),
    ]);

// ───────────────────────── Map placeholder ─────────────────────────
class MapPainter extends CustomPainter {
  const MapPainter(this.route);
  final bool route;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFEAEFE8));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .3, s.height * .35, s.width * .35, s.height * .3), const Radius.circular(12)), Paint()..color = const Color(0xFFD5E4CF));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .76, s.height * .08, s.width * .2, s.height * .18), const Radius.circular(12)), Paint()..color = const Color(0xFFCFE3F3));
    final w = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(0, s.height * .3), Offset(s.width, s.height * .3), w..strokeWidth = 12);
    c.drawLine(Offset(0, s.height * .72), Offset(s.width, s.height * .72), w..strokeWidth = 9);
    c.drawLine(Offset(s.width * .22, 0), Offset(s.width * .22, s.height), w..strokeWidth = 12);
    c.drawLine(Offset(s.width * .72, 0), Offset(s.width * .72, s.height), w..strokeWidth = 9);
    if (route) {
      c.drawLine(
          Offset(s.width * .22, s.height * .72),
          Offset(s.width * .5, s.height * .5),
          Paint()
            ..color = kRed
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// Map placeholder on top + white sheet below (ambulance request / tracking).
class MapPage extends StatelessWidget {
  const MapPage(this.title, this.sheet, {super.key, this.route = false});
  final String title;
  final Widget sheet;
  final bool route;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: Column(children: [
          SizedBox(
            height: 290,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: MapPainter(route))),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: kGradient, shape: BoxShape.circle, boxShadow: kGlow, border: Border.all(color: Colors.white, width: 3)),
                    child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 26),
                  ),
                  Container(width: 14, height: 5, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(7))),
                ]),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(20), boxShadow: kGlow),
                      child: Text(title, style: t(15, c: Colors.white)),
                    ),
                    const Spacer(),
                    glass(chev(kRed, 26), () => Navigator.maybePop(context), bg: Colors.white),
                  ]),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), child: sheet),
            ),
          ),
        ]),
      );
}

// ───────────────────────── App entry ─────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // لا نسمح لفشل تهيئة Firebase بمنع ظهور واجهة التطبيق.
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
    firebaseInitError = null;
    debugPrint('Tabibak: Firebase initialized successfully.');
  } catch (e, stack) {
    firebaseReady = false;
    firebaseInitError = e.toString();
    debugPrint('Tabibak: Firebase initialization failed: $e');
    debugPrint('$stack');
  }

  // استعادة بيانات الحساب المحلي ثم تشغيل التطبيق في جميع الحالات.
  try {
    app.restore();
  } catch (e, stack) {
    debugPrint('Tabibak: local restore failed: $e');
    debugPrint('$stack');
  }

  runApp(const TabibakApp());
}

class TabibakApp extends StatelessWidget {
  const TabibakApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'طبيبك',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: kRed,
          scaffoldBackgroundColor: Colors.white,
          textTheme: appTextTheme(),
          textSelectionTheme: const TextSelectionThemeData(cursorColor: kRed, selectionHandleColor: kRed),
        ),
        builder: (c, child) => AnimatedBuilder(
          animation: app,
          builder: (_, __) => MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(app.fontScale)),
            child: Directionality(textDirection: TextDirection.rtl, child: child!),
          ),
        ),
        home: const SplashScreen(),
      );
}

// ───────────────────────── Static data ─────────────────────────
// هذا الكتالوج محاكاة لما سيأتي من الخادم المشترك بين التطبيقات الثلاثة:
//  • الطبيب يُعرَّف برقم المجلس (reg) — نفس المفتاح عند تطبيق الطبيب والمركز.
//  • المركز يُعرَّف بمعرّف ثابت (id): c1.. مسجّل ومعتمد في تطبيق المركز (له RegCenter في تطبيق الطبيب)، و u1.. غير مسجّل.
//  • كل «Work» = عضوية طبيب في مركز بشروطها (سعر · أيام · ساعات) كما يضبطها المركز في تطبيقه.
//  • لا يظهر هنا إلا الطبيب الموثَّق (verified) الذي لم يوقف استقبال الحجوزات.

/// الأيام بنفس ترتيب تطبيقَي الطبيب والمركز (0 = السبت). تحويل تاريخ إلى الفهرس: satIdx.
const kDaysSat = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
int satIdx(DateTime d) => (d.weekday + 1) % 7;

/// الدرجة العلمية: 0 استشاري · 1 أخصائي · 2 مسجّل — لكلٍّ لون وعلامة في بطاقة الطبيب.
const kGrades = ['استشاري', 'أخصائي', 'مسجّل'];
const kGradeFem = ['استشارية', 'أخصائية', 'مسجّلة'];
const kGradeColors = [kPurple, kBlue, kTeal];
const kGradeBgs = [kPurpleBg, kBlueBg, kTealBg];
const kGradeIcons = [Icons.workspace_premium_rounded, Icons.verified_rounded, Icons.school_rounded];

/// التخصصات (نفس قائمة تطبيقَي الطبيب والمركز، بلا «أخرى»).
const kSpecs = ['باطنية', 'أطفال', 'نساء وتوليد', 'جراحة عامة', 'قلب', 'عظام', 'جلدية', 'أنف وأذن وحنجرة', 'عيون', 'مسالك بولية', 'أعصاب', 'نفسية', 'طب أسرة', 'أسنان'];

/// التخصصات الدقيقة (Subspecialty) لكل تخصص.
const kSubs = <String, List<String>>{
  'باطنية': ['سكري وغدد صماء', 'جهاز هضمي وكبد', 'صدرية', 'كلى', 'أمراض الدم', 'روماتيزم ومفاصل', 'أمراض معدية', 'أورام'],
  'أطفال': ['حديثي الولادة', 'قلب أطفال', 'أعصاب أطفال', 'جهاز هضمي أطفال', 'حساسية وصدر أطفال', 'كلى أطفال', 'غدد أطفال', 'أمراض دم أطفال'],
  'نساء وتوليد': ['حمل عالي الخطورة', 'العقم وأطفال الأنابيب', 'جراحة المناظير النسائية', 'أورام نساء', 'سلس البول والحوض'],
  'جراحة عامة': ['جراحة المناظير', 'أوعية دموية', 'ثدي وغدد', 'جهاز هضمي وكبد', 'جراحة أطفال', 'تجميل وحروق', 'صدر وقلب', 'جراحة أعصاب'],
  'قلب': ['قسطرة تداخلية', 'كهرباء القلب', 'قصور القلب', 'أمراض الصمامات', 'إيكو وفحوصات'],
  'عظام': ['مفاصل وركبة', 'عمود فقري', 'إصابات رياضية', 'عظام أطفال', 'كسور وإصابات', 'يد وكتف', 'تبديل مفاصل'],
  'جلدية': ['تجميل جلدي وليزر', 'حساسية وأكزيما', 'أمراض الشعر', 'جلدية أطفال', 'أورام جلدية'],
  'أنف وأذن وحنجرة': ['سمعيات', 'جراحة الجيوب', 'أذن وزراعة قوقعة', 'رأس وعنق', 'أنف وتجميل'],
  'عيون': ['شبكية وجسم زجاجي', 'مياه بيضاء وزرق', 'قرنية', 'حول وكسل العين', 'عيون أطفال', 'تصحيح إبصار'],
  'مسالك بولية': ['حصوات', 'بروستاتا', 'عقم الرجال', 'مسالك أطفال', 'أورام'],
  'أعصاب': ['صرع', 'سكتات دماغية', 'أمراض الحركة', 'صداع', 'أعصاب طرفية'],
  'نفسية': ['اكتئاب وقلق', 'إدمان', 'نفسية أطفال', 'علاج نفسي'],
  'طب أسرة': ['رعاية أولية', 'أمراض مزمنة', 'طب المسنين', 'صحة المرأة'],
  'أسنان': ['تقويم', 'زراعة', 'لثة', 'أسنان أطفال', 'تجميل أسنان', 'جراحة فم', 'علاج جذور'],
};

/// الأحياء حسب المدينة (ولاية الخرطوم). قائمة أولية — راجعها وأكملها حسب معرفتك المحلية.
const kCities = ['الخرطوم', 'أم درمان', 'بحري', 'شرق النيل'];
const kAreas = <String, List<String>>{
  'الخرطوم': ['وسط الخرطوم', 'الخرطوم 2', 'الخرطوم 3', 'العمارات', 'الطائف', 'الرياض', 'المنشية', 'بري', 'الصحافة', 'جبرة', 'الأزهري', 'الكلاكلة', 'مايو', 'السجانة', 'الشجرة', 'الجريف غرب', 'الديوم الشرقية', 'الديوم الغربية', 'اللاماب', 'أركويت', 'المعمورة', 'الفردوس', 'سوبا'],
  'أم درمان': ['أم درمان القديمة', 'بيت المال', 'الموردة', 'العرضة', 'ود نوباوي', 'الثورة', 'أبو روف', 'العباسية', 'أمبدة', 'الملازمين', 'الفتيحاب', 'المهندسين', 'بانت', 'الشهداء', 'ود البخيت', 'الصالحة', 'دار السلام', 'أبو سعد'],
  'بحري': ['وسط بحري', 'الشعبية', 'الحلفايا', 'كافوري', 'المزاد', 'شمبات', 'الصافية', 'حلة كوكو', 'الختمية', 'المسبح', 'الدروشاب', 'الكدرو', 'الأملاك', 'كوبر', 'المؤسسة'],
  'شرق النيل': ['الحاج يوسف', 'الجريف شرق', 'الصفا'],
};

/// مركز/عيادة. registered = مسجّل ومعتمد في تطبيق المركز ← الحجز عبر طبيبك متاح؛ وإلا تُعرض بياناته للاتصال فقط.
class Clinic {
  const Clinic(this.name, this.place, this.days, this.hours, this.phone, this.rating, this.about, {this.id = '', this.city = 'الخرطوم', this.hood = '', this.registered = true});
  final String name, place, days, hours, phone, rating, about, id, city, hood;
  final bool registered;
}

const kClinics = [
  Clinic('مركز المسباح', 'بحري - المسبح', 'السبت - الخميس', '8:00 ص - 10:00 م', '+249 912 000 111', '4.7', 'مركز طبي متكامل يضم عيادات تخصصية ومختبراً وأشعة وصيدلية.', id: 'c1', city: 'بحري', hood: 'المسبح'),
  Clinic('مركز الشرق', 'أم درمان - الثورة', 'الأحد - الخميس', '9:00 ص - 5:00 م', '+249 912 000 222', '4.5', 'عيادات تخصصية متعددة وخدمة استقبال سريعة وانتظار قصير.', id: 'c2', city: 'أم درمان', hood: 'الثورة'),
  Clinic('مركز النيل الطبي', 'شرق النيل - الحاج يوسف', 'السبت - الأربعاء', '10:00 ص - 8:00 م', '+249 912 000 333', '4.4', 'مركز حديث بمواعيد مسائية ممتدة وفريق أطباء استشاريين.', id: 'c3', city: 'شرق النيل', hood: 'الحاج يوسف'),
  Clinic('عيادة الشفاء التخصصية', 'الخرطوم - العمارات', 'السبت - الخميس', '4:00 م - 9:00 م', '+249 912 100 101', '4.2', 'عيادات تخصصية مسائية.', id: 'u1', city: 'الخرطوم', hood: 'العمارات', registered: false),
  Clinic('مركز الرياض الطبي', 'الخرطوم - الرياض', 'السبت - الخميس', '9:00 ص - 9:00 م', '+249 912 100 202', '4.3', 'مركز طبي بعيادات متعددة.', id: 'u2', city: 'الخرطوم', hood: 'الرياض', registered: false),
  Clinic('مركز القلب التخصصي', 'بحري - الصافية', 'السبت - الخميس', '9:00 ص - 8:00 م', '+249 912 100 303', '4.5', 'تشخيص وعلاج أمراض القلب.', id: 'u3', city: 'بحري', hood: 'الصافية', registered: false),
  Clinic('مستوصف ود نوباوي', 'أم درمان - ود نوباوي', 'السبت - الخميس', '8:00 ص - 3:00 م', '+249 912 100 404', '4.0', 'مستوصف حي بعيادات عامة وتخصصية.', id: 'u4', city: 'أم درمان', hood: 'ود نوباوي', registered: false),
];

Clinic? clinicById(String id) {
  for (final c in kClinics) {
    if (c.id == id) return c;
  }
  return null;
}

/// عضوية طبيب في مركز بشروطها. from/to بالدقائق منذ منتصف الليل · days بفهرس kDaysSat (0 = السبت).
/// active = العضوية مفعّلة بين الطبيب والمركز (وليست طلباً معلّقاً أو موقوفة من المركز).
class Work {
  const Work(this.centerId, this.fee, this.days, this.from, this.to, {this.active = true});
  final String centerId;
  final int fee, from, to;
  final Set<int> days;
  final bool active;

  Clinic get clinic => clinicById(centerId)!;

  /// قاعدة الحجز: المركز معتمد في تطبيق المركز + العضوية مفعّلة. (الطبيب الموثّق وغير الموقوف شرط دخوله الكتالوج أصلاً.)
  bool get bookable => clinic.registered && active;
  String get hours => '${fmtTime(from)} - ${fmtTime(to)}';
  String get daysText {
    final d = days.toList()..sort();
    if (d.isEmpty) return '—';
    if (d.length == 1) return kDaysSat[d.first];
    return d.last - d.first == d.length - 1 ? '${kDaysSat[d.first]} - ${kDaysSat[d.last]}' : d.map((i) => kDaysSat[i]).join('، ');
  }

  /// سبب عدم إمكان الحجز (للبطاقة الرمادية).
  String get why => !clinic.registered ? 'هذا المركز غير مسجّل في طبيبك، فلا يمكن الحجز عن طريقنا' : 'الحجز غير مفعّل مع هذا المركز حالياً';
}

class Doctor {
  const Doctor(this.name, this.spec, this.rating, this.reviews, this.img, {required this.reg, this.sub = '', this.grade = 1, this.quals = '', this.exp = 10, this.female = false, this.about = '', this.works = const []});
  final String name, spec, rating, img, reg, sub, quals, about;
  final int reviews, exp, grade; // grade: 0 استشاري · 1 أخصائي · 2 مسجّل
  final bool female;
  final List<Work> works;

  String get gradeLabel => (female ? kGradeFem : kGrades)[grade];
  List<Work> get open => [for (final w in works) if (w.bookable) w];
  bool get canBook => open.isNotEmpty;
  Work? workAt(String centerId) {
    for (final w in works) {
      if (w.centerId == centerId) return w;
    }
    return null;
  }

  /// أقل سعر كشف (من المراكز المتاحة للحجز إن وُجدت، وإلا من كل الأماكن).
  int get fee {
    final l = open.isNotEmpty ? open : works;
    if (l.isEmpty) return 0;
    var m = l.first.fee;
    for (final w in l) {
      if (w.fee < m) m = w.fee;
    }
    return m;
  }

  String get price => money(fee);

  /// نص بحث: المدن والأحياء وأسماء المراكز التي يعمل بها.
  String get places => works.map((w) => '${w.clinic.city} ${w.clinic.hood} ${w.clinic.name}').join(' ');
}

const doctors = [
  Doctor('د. أحمد محمد علي', 'باطنية', '4.8', 245, 'assets/images/doctor1.jpg',
      reg: '12345', sub: 'سكري وغدد صماء', grade: 0, quals: 'ماجستير + دكتوراه باطنية - جامعة الخرطوم', exp: 10, about: 'استشاري باطنية بخبرة تزيد على عشر سنوات في علاج السكري والضغط وأمراض الجهاز الهضمي.',
      works: [Work('c1', 10000, {0, 1, 2, 3, 4, 5}, 1020, 1200), Work('c3', 12000, {1, 3}, 960, 1200, active: false), Work('u1', 12000, {0, 1, 2, 3, 4}, 1080, 1260)]),
  Doctor('د. سارة عبد الله', 'نساء وتوليد', '4.6', 180, 'assets/images/doctor2.jpg',
      reg: '23456', sub: 'حمل عالي الخطورة', grade: 1, quals: 'بكالوريوس الطب + دبلوم نساء وتوليد', exp: 7, female: true, about: 'متابعة الحمل والولادة وأمراض النساء، مع اهتمام خاص بصحة الأم والطفل.',
      works: [Work('c2', 8000, {1, 2, 3, 4, 5}, 540, 1020), Work('u2', 9000, {0, 2}, 1020, 1260)]),
  Doctor('د. حسن محمود', 'أطفال', '4.5', 120, 'assets/images/doctor3.jpg',
      reg: '34567', sub: 'حديثي الولادة', grade: 1, quals: 'ماجستير طب الأطفال', exp: 9, about: 'رعاية صحية شاملة للأطفال من الولادة حتى المراهقة، والتطعيمات ومتابعة النمو.',
      works: [Work('c1', 7500, {0, 1, 2, 3, 4}, 600, 1080, active: false), Work('u4', 6000, {0, 1, 2, 3, 4, 5}, 960, 1200)]),
  Doctor('د. منى الطيب', 'جلدية', '4.7', 134, 'assets/images/doctor4.jpg',
      reg: '45678', sub: 'تجميل جلدي وليزر', grade: 1, quals: 'ماجستير الأمراض الجلدية - جامعة النيلين', exp: 8, female: true, about: 'علاج الأمراض الجلدية والحساسية وحب الشباب والمشاكل التجميلية.',
      works: [Work('c2', 8500, {1, 3}, 600, 960), Work('c1', 9000, {1, 3}, 960, 1200, active: false)]),
  Doctor('د. عثمان صالح', 'عظام', '4.6', 102, 'assets/images/doctor5.jpg',
      reg: '56789', sub: 'مفاصل وركبة', grade: 0, quals: 'بورد جراحة العظام - المجلس السوداني للتخصصات الطبية', exp: 14, about: 'جراحة العظام والمفاصل وإصابات الملاعب، مع متابعة ما بعد العمليات.',
      works: [Work('c3', 9000, {0, 1, 2, 3, 4}, 600, 1200)]),
  Doctor('د. ياسر إبراهيم', 'قلب', '4.9', 310, 'assets/images/doctor6.jpg',
      reg: '67890', sub: 'قسطرة تداخلية', grade: 0, quals: 'دكتوراه أمراض القلب - جامعة أم درمان الإسلامية', exp: 11, about: 'تشخيص وعلاج أمراض القلب والشرايين، وتخطيط القلب والإيكو.',
      works: [Work('c1', 12000, {0, 1, 2, 3, 4}, 540, 900), Work('u3', 15000, {0, 2, 4}, 960, 1200)]),
  Doctor('د. علي محمد', 'جراحة عامة', '4.4', 98, 'assets/images/doctor1.jpg',
      reg: '90123', sub: 'جراحة المناظير', grade: 0, quals: 'زمالة الجراحة العامة', exp: 12, about: 'جراحة عامة ومناظير، مع متابعة ما قبل وبعد العمليات.',
      works: [Work('c2', 9000, {1, 2, 3, 4, 5}, 600, 1020), Work('u2', 10000, {0, 3}, 1080, 1260)]),
  Doctor('د. هدى عبد الرحمن', 'عيون', '4.5', 76, 'assets/images/doctor2.jpg',
      reg: '91234', sub: 'شبكية وجسم زجاجي', grade: 1, quals: 'ماجستير طب وجراحة العيون', exp: 6, female: true, about: 'فحص العيون وعلاج أمراض الشبكية والمياه البيضاء.',
      works: [Work('c3', 7500, {0, 1, 2, 3, 4}, 960, 1200), Work('u1', 7000, {0, 1, 2, 3, 4}, 1080, 1260)]),
  Doctor('د. محمد عبد الباقي', 'باطنية', '4.2', 38, 'assets/images/doctor3.jpg',
      reg: '92345', sub: 'جهاز هضمي وكبد', grade: 2, quals: 'بكالوريوس الطب والجراحة - مسجّل باطنية', exp: 4, about: 'متابعة أمراض الجهاز الهضمي والمعدة والقولون تحت إشراف استشاري.',
      works: [Work('c3', 5000, {0, 1, 2, 3, 4, 5}, 1080, 1200)]),
  Doctor('د. نجلاء عوض', 'أطفال', '4.8', 210, 'assets/images/doctor4.jpg',
      reg: '93456', sub: 'حساسية وصدر أطفال', grade: 0, quals: 'دكتوراه طب الأطفال', exp: 13, female: true, about: 'علاج الربو والحساسية وأمراض الصدر عند الأطفال.',
      works: [Work('c1', 11000, {0, 1, 2, 3}, 960, 1200), Work('u4', 6000, {4, 5}, 600, 900)]),
  Doctor('د. أسامة بشير', 'أعصاب', '4.7', 150, 'assets/images/doctor5.jpg',
      reg: '94567', sub: 'صرع', grade: 0, quals: 'دكتوراه أمراض الأعصاب', exp: 16, about: 'تشخيص وعلاج الصرع والصداع وأمراض الأعصاب الطرفية.',
      works: [Work('u2', 14000, {0, 1, 2, 3, 4}, 1020, 1260)]),
  Doctor('د. ريم الأمين', 'نفسية', '4.6', 64, 'assets/images/doctor6.jpg',
      reg: '95678', sub: 'اكتئاب وقلق', grade: 1, quals: 'ماجستير الطب النفسي', exp: 5, female: true, about: 'علاج الاكتئاب والقلق والمشكلات النفسية بجلسات سرّية.',
      works: [Work('c1', 9000, {2, 3}, 1020, 1260)]),
  Doctor('د. سلمى عثمان', 'نساء وتوليد', '4.3', 22, 'assets/images/doctor1.jpg',
      reg: '96789', sub: 'حمل عالي الخطورة', grade: 2, quals: 'بكالوريوس الطب والجراحة - مسجّلة نساء وتوليد', exp: 3, female: true, about: 'متابعة الحمل والفحوصات الدورية تحت إشراف استشاري.',
      works: [Work('c2', 4000, {1, 2, 3, 4, 5}, 540, 840)]),
];

Doctor docBy(String reg) => doctors.firstWhere((d) => d.reg == reg);

/// مركز يقدّم خدمات منزلية (زيارة طبيب / تمريض / معمل). المسافة `km` تقريبية من موقعك الحالي.
class HomeCenter {
  const HomeCenter(this.name, this.place, this.area, this.km, this.rating, this.hours, {this.doctor = false, this.nurse = false, this.lab = false, this.id = ''});
  final String name, place, area, rating, hours, id; // id: معرّف المركز (نفس معرّفات تطبيق الطبيب)
  final double km;
  final bool doctor, nurse, lab;
}

const kHomeCenters = [
  HomeCenter('مركز المسباح', 'الخرطوم - بحري', 'بحري', 1.8, '4.7', '8:00 ص - 6:00 م', doctor: true, nurse: true, lab: true, id: 'c1'),
  HomeCenter('مركز الشفاء للرعاية', 'الخرطوم - بحري', 'بحري', 3.5, '4.3', '8:00 ص - 10:00 م', nurse: true, id: 'c8'),
  HomeCenter('مركز النيل الطبي', 'الخرطوم - شرق النيل', 'شرق النيل', 4.2, '4.4', '10:00 ص - 8:00 م', doctor: true, nurse: true, id: 'c3'),
  HomeCenter('مركز الأمل المنزلي', 'الخرطوم - وسط', 'الخرطوم', 5.6, '4.6', 'على مدار الساعة', nurse: true, lab: true, id: 'c7'),
  HomeCenter('مركز الشرق', 'الخرطوم - أم درمان', 'أم درمان', 7.4, '4.5', '9:00 ص - 5:00 م', doctor: true, lab: true, id: 'c2'),
  HomeCenter('مركز دار السلام الطبي', 'الخرطوم - أم درمان', 'أم درمان', 9.1, '4.2', '9:00 ص - 4:00 م', lab: true, id: 'c9'),
];

class BedOffer {
  const BedOffer(this.type, this.label, this.price, this.avail);
  final String type, label;
  final int price, avail;
}

class Hospital {
  const Hospital(this.name, this.place, this.img, this.rating, this.beds, {this.id = ''});
  final String name, place, img, rating, id;
  final List<BedOffer> beds;
}

const kHospitals = [
  Hospital('مستشفى السلام', 'الخرطوم - أم درمان', 'assets/images/hospital1.jpg', '4.6', [BedOffer('ICU', 'عناية مركزة ICU', 15000, 3), BedOffer('HDU', 'عناية متوسطة HDU', 12000, 5), BedOffer('CCU', 'عناية قلب CCU', 18000, 0), BedOffer('عادية', 'سرير عادي', 6000, 12)], id: 'c4'),
  Hospital('مستشفى النيل', 'الخرطوم - بحري', 'assets/images/hospital2.jpg', '4.5', [BedOffer('ICU', 'عناية مركزة ICU', 16000, 2), BedOffer('HDU', 'عناية متوسطة HDU', 12000, 4), BedOffer('CCU', 'عناية قلب CCU', 18000, 1), BedOffer('عادية', 'سرير عادي', 5500, 8)], id: 'c5'),
  Hospital('مستشفى المدينة', 'الخرطوم - شرق النيل', 'assets/images/hospital3.jpg', '4.3', [BedOffer('ICU', 'عناية مركزة ICU', 14000, 0), BedOffer('HDU', 'عناية متوسطة HDU', 11000, 0), BedOffer('CCU', 'عناية قلب CCU', 18000, 0), BedOffer('عادية', 'سرير عادي', 6000, 3)], id: 'c6'),
];

const kTests = [
  ('صورة دم كاملة', '150'),
  ('تحليل السكر', '80'),
  ('وظائف الكلى', '250'),
  ('وظائف الكبد', '250'),
  ('دهون الدم', '220'),
  ('فيتامين D', '400'),
  ('وظائف الغدة الدرقية', '450'),
  ('فحص ملاريا', '120'),
];

const kPromos = {'TABIBAK20': 20, 'WELCOME10': 10};
const kFaqs = [
  ('كيف ألغي حجزي؟', 'من حجوزاتي اختر الموعد ثم إلغاء الحجز. الإلغاء قبل 24 ساعة بدون رسوم.'),
  ('كيف أحجز سريراً في مستشفى؟', 'اختر حجز سرير ثم المستشفى ونوع السرير وأرسل الطلب.'),
  ('متى تصل خدمة المعمل المنزلي؟', 'في الموعد الذي تحدده عند الحجز، وسيصلك إشعار قبل وصول الفني.'),
  ('كيف أسترد رسوم الدفع؟', 'تواصل مع الدعم وسنراجع طلبك خلال 24 ساعة.'),
  ('كيف أضيف فرداً من العائلة؟', 'من حسابي ثم أفراد العائلة ثم إضافة فرد جديد، وبعدها يمكنك الحجز له.'),
];

// ───────────────────────── Mutable models ─────────────────────────
/// حالات الحجز: ما يعرضه هذا التطبيق ← ما يقابله في Booking.status عند المركز.
/// ملاحظة: «ملغي» (إلغاء المريض) أضيفت إلى تطبيق المركز، و«قيد التنفيذ» تقابل «مؤكد» هناك.
const kToCenterStatus = {'قيد التأكيد': 'جديد', 'مؤكد': 'مؤكد', 'قيد التنفيذ': 'مؤكد', 'مكتمل': 'مكتمل', 'ملغي': 'ملغي'};

/// وعكسه: ما يصل من المركز ← ما يُعرض للمريض. «مرفوض» يُعرض ملغياً مع سبب الرفض.
const kFromCenterStatus = {'جديد': 'قيد التأكيد', 'مؤكد': 'مؤكد', 'مكتمل': 'مكتمل', 'مرفوض': 'ملغي', 'ملغي': 'ملغي'};

class Appt {
  Appt(this.id, this.kind, this.title, this.sub, this.day, this.time, {this.status = 'مؤكد', this.price = 0, this.place = '', this.who = '', this.method = '', this.doctor, this.centerId = '', this.complaint = '', this.sharedHealth = false, this.phone = ''});
  final int id, kind; // 0 طبيب · 1 سرير · 2 زيارة منزلية · 3 معمل منزلي
  String title, sub, day, time, status, place, who, method;
  int price;
  final Doctor? doctor;

  /// حقول الربط: معرّف المركز · هاتف صاحب الحساب · شكوى المريض (يراها الطبيب في تطبيقه) · هل شُورك ملفه الصحي مع الطبيب.
  final String centerId, phone;
  String complaint;
  final bool sharedHealth;

  bool get upcoming => status == 'مؤكد' || status == 'قيد التأكيد' || status == 'قيد التنفيذ';
  String get code => 'TB-${20400 + id}';
  IconData get icon => const [Icons.medical_services_rounded, Icons.bed_rounded, Icons.vaccines_rounded, Icons.science_rounded][kind];

  /// الحمولة التي تصل إلى المركز والطبيب عند الربط بالخادم.
  /// مفاتيحها مطابقة لحقول Patient.fromPlatform في تطبيق الطبيب (name · age · female · phone · timeMin · place · complaint ·
  /// conditions · allergies · meds · surgeries · transfusion · admission) ولحقول Booking في تطبيق المركز (type · svc · when · price · status).
  Map<String, dynamic> toPlatform() {
    final self = who.isEmpty || who == app.name;
    final isHome = kind == 2;
    return {
      'code': code,
      'type': kind == 3 ? 2 : kind, // 0 طبيب · 1 سرير · 2 خدمة منزلية (زيارة طبيب/تمريض/معمل)
      'svc': kind == 3 ? 2 : (isHome && title.contains('تمريض') ? 1 : 0),
      'centerId': centerId,
      'doctorLic': doctor?.reg ?? '',
      'name': self ? app.name : who,
      'phone': phone.isEmpty ? app.phone : phone,
      'age': app.ageFor(who),
      'female': self ? app.gender == 'أنثى' : false,
      'title': title,
      'when': '$day · $time',
      'timeMin': parseTime(time) ?? 0,
      'place': place,
      'price': price,
      'status': kToCenterStatus[status] ?? 'جديد',
      'complaint': complaint,
      if (sharedHealth) ...app.health.toPlatform(),
    };
  }
}

class Notif {
  Notif(this.icon, this.title, this.body, this.time, {this.unread = false, this.dest = 0, this.today = true});
  final IconData icon;
  final String title, body, time;
  bool unread, today;
  final int dest; // 0 لا شيء · 1 حجوزاتي · 2 طلبات منزلية · 3 نتائج التحاليل · 4 العروض
}

class Member {
  Member(this.name, this.rel, this.age);
  String name, rel;
  int age;
}

class Addr {
  Addr(this.label, this.line, this.note, this.icon);
  String label, line, note;
  IconData icon;
}

class Review {
  const Review(this.name, this.stars, this.text, this.time);
  final String name, text, time;
  final int stars;
}

class AppState extends ChangeNotifier {
  AppState() {
    if (kDemoData) _seedDemo();
  }

  void _seedDemo() {
    final n = DateTime.now();
    String d(int k) => dayLabel(n.add(Duration(days: k)));
    appts.addAll([
      Appt(1, 0, 'د. أحمد محمد علي', 'استشاري باطنية · مركز المسباح', d(2), '6:30 م', price: 10500, place: 'مركز المسباح', centerId: 'c1', who: '', method: 'تطبيق بنكك', doctor: doctors[0]),
      Appt(2, 0, 'د. سارة عبد الله', 'نساء وتوليد · مركز الشرق', d(3), '1:00 م', status: 'قيد التأكيد', price: 8500, place: 'مركز الشرق', centerId: 'c2', who: '', method: 'الدفع في المركز', doctor: doctors[1]),
      Appt(3, 3, 'تحاليل منزلية', 'صورة دم + تحليل السكر', d(1), '9:00 ص', price: 730, place: 'الخرطوم - بحري - المسبح', who: '', method: 'نقداً عند الزيارة'),
      Appt(6, 2, 'تمريض منزلي', 'حقن وريدي · الممرض أحمد عثمان', 'اليوم', '4:30 م', status: 'قيد التنفيذ', price: 3000, place: 'الخرطوم - بحري - المسبح', who: '', method: 'نقداً عند الزيارة'),
      Appt(4, 0, 'د. حسن محمود', 'أخصائي أطفال · مركز المسباح', d(-18), '5:00 م', status: 'مكتمل', price: 8000, place: 'مركز المسباح', centerId: 'c1', who: 'يوسف أحمد', method: 'تطبيق بنكك', doctor: doctors[2]),
      Appt(5, 0, 'د. علي محمد', 'استشاري جراحة عامة · مركز الشرق', d(-27), '2:30 م', status: 'مكتمل', price: 9500, place: 'مركز الشرق', centerId: 'c2', who: '', method: 'أوكاش', doctor: docBy('90123')),
    ]);
  }

  // account
  // الحساب يُنشأ عند التسجيل (رقم الهاتف أولاً) — لا قيم افتراضية.
  String name = '', phone = '', dob = '', blood = '', gender = '';
  // settings
  bool notifOn = true, remindOn = true, locOn = true;
  int fontIdx = 1, selAddr = 0;
  double get fontScale => const [.92, 1.0, 1.12][fontIdx];

  final favs = <String>{if (kDemoData) '12345'}; // مفتاحها رقم المجلس لا الاسم
  final appts = <Appt>[];
  final notifs = <Notif>[
    Notif(Icons.check_circle_rounded, 'تم تأكيد حجزك', 'موعدك مع د. أحمد محمد علي بعد يومين الساعة 6:30 م', 'منذ 5 دقائق', unread: true, dest: 1),
    Notif(Icons.vaccines_rounded, 'الممرض في الطريق إليك', 'يصل إلى منزلك خلال 15 دقيقة تقريباً', 'منذ ساعة', unread: true, dest: 2),
    Notif(Icons.science_rounded, 'نتيجة التحاليل جاهزة', 'صورة الدم الكاملة جاهزة للعرض والتحميل', 'أمس 6:20 م', dest: 3, today: false),
    Notif(Icons.notifications_active_rounded, 'تذكير بالموعد', 'لديك موعد غداً في مركز المسباح', 'أمس 9:00 ص', dest: 1, today: false),
    Notif(Icons.local_offer_rounded, 'خصم 20% على أول كشف', 'استخدم الكود TABIBAK20 حتى نهاية الشهر', 'أمس 8:00 ص', dest: 4, today: false),
  ];
  final addrs = <Addr>[
    Addr('المنزل', 'الخرطوم - بحري - المسبح', 'شارع 15، بجوار الصيدلية', Icons.home_rounded),
    Addr('العمل', 'الخرطوم - وسط', 'برج الأمانة، الطابق 4', Icons.work_rounded),
  ];
  final family = <Member>[Member('فاطمة أحمد', 'الزوجة', 33), Member('يوسف أحمد', 'الابن', 6)];
  final reviews = <String, List<Review>>{};
  int _seq = 10;

  // ── الحساب: يُنشأ مرة واحدة (برقم الهاتف) ثم يفتح التطبيق مباشرة على هذا الجهاز ──
  bool registered = false;
  int avatar = 0; // 0 = الحرف الأول من الاسم · 1..9 = صور رمزية جاهزة (kAvatars)
  Uint8List? photo;
  final health = HealthProfile();
  String homeCenter = ''; // مركز الخدمة المنزلية المختار (HomeCenter.id) ليصل مع طلب الزيارة أو المعمل

  /// العمر من تاريخ الميلاد «12 / 05 / 1990» (0 = غير معروف).
  static int ageOf(String dob) {
    final m = RegExp(r'(\d{1,2})\s*/\s*(\d{1,2})\s*/\s*(\d{4})').firstMatch(latin(dob));
    if (m == null) return 0;
    final now = DateTime.now();
    final mo = int.parse(m.group(2)!), dy = int.parse(m.group(1)!), y = int.parse(m.group(3)!);
    var a = now.year - y;
    if (now.month < mo || (now.month == mo && now.day < dy)) a--;
    return a < 0 ? 0 : a;
  }

  int get age => ageOf(dob);

  /// عمر المريض المحجوز له: صاحب الحساب أو أحد أفراد العائلة.
  int ageFor(String who) {
    for (final m in family) {
      if (m.name == who) return m.age;
    }
    return who.isEmpty || who == name ? age : 0;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'dob': dob,
        'blood': blood,
        'gender': gender,
        'avatar': avatar,
        'photo': photo == null ? '' : base64Encode(photo!),
        'health': health.toJson(),
        'favs': favs.toList(),
      };

  void loadJson(Map<String, dynamic> j) {
    name = (j['name'] ?? '') as String;
    phone = (j['phone'] ?? '') as String;
    dob = (j['dob'] ?? '') as String;
    blood = (j['blood'] ?? '') as String;
    gender = (j['gender'] ?? '') as String;
    avatar = (j['avatar'] ?? 0) as int;
    final ph = j['photo'];
    photo = ph is String && ph.isNotEmpty ? base64Decode(ph) : null;
    health.loadJson(Map<String, dynamic>.from((j['health'] ?? const <String, dynamic>{}) as Map));
    favs
      ..clear()
      ..addAll(List<String>.from((j['favs'] ?? const []) as List));
    registered = true;
  }

  /// عند فتح التطبيق: إن كان على الجهاز حساب محفوظ نحمّله ويدخل المستخدم مباشرة.
  void restore() {
    final j = DeviceStore.read();
    if (j != null) loadJson(j);
  }

  /// يحفظ الحساب على الجهاز وفي دليل الحسابات (للدخول من جهاز آخر).
  void save() {
    if (!registered) return;
    final j = toJson();
    DeviceStore.write(j);
    if (phone.isNotEmpty) userDir[phone] = j; // توافق مؤقت مع التخزين المحلي القديم
    final uid = firebaseReady ? FirebaseAuth.instance.currentUser?.uid : null;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        ...j,
        'uid': uid,
        'phone': FirebaseAuth.instance.currentUser?.phoneNumber ?? phone,
        'role': 'patient',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((e) {
        debugPrint('Firebase user save failed: $e');
      });
    }
  }

  void createAccount(String phone, String name, {String gender = '', String dob = ''}) {
    this.phone = phone;
    this.name = name;
    this.gender = gender;
    this.dob = dob;
    blood = '';
    avatar = 0;
    photo = null;
    health.reset();
    registered = true;
    ping();
  }

  void signOut() {
    save();
    if (firebaseReady) {
      FirebaseAuth.instance.signOut().catchError((e) {
        debugPrint('Firebase sign-out failed: $e');
      });
    }
    registered = false;
    DeviceStore.clear();
    name = '';
    phone = '';
    dob = '';
    blood = '';
    gender = '';
    avatar = 0;
    photo = null;
    health.reset();
    notifyListeners();
  }

  void deleteAccount() {
    userDir.remove(phone);
    registered = false; // حتى لا يعيد signOut حفظه في الدليل
    signOut();
  }

  String get first {
    final n = name.trim();
    return n.isEmpty ? 'زائر' : n.split(' ').first;
  }
  int get unread => notifs.where((n) => n.unread).length;
  List<String> get people => [name, ...family.map((m) => m.name)];
  Addr get addr => addrs.isEmpty ? Addr('بدون عنوان', 'أضف عنواناً للزيارة', '', Icons.add_location_alt_rounded) : addrs[selAddr.clamp(0, addrs.length - 1).toInt()];

  void ping() {
    save();
    notifyListeners();
  }

  int newId() => ++_seq;

  Appt add(Appt a, [Notif? n]) {
    appts.insert(0, a);
    homeCenter = '';
    if (n != null) notifs.insert(0, n);
    notifyListeners();

    // إنشاء حجز مشترك ليظهر في تطبيق المركز والطبيب.
    final user = firebaseReady ? FirebaseAuth.instance.currentUser : null;
    if (user != null) {
      final ref = FirebaseFirestore.instance.collection('bookings').doc();
      ref.set({
        ...a.toPlatform(),
        'patientUid': user.uid,
        'patientPhone': user.phoneNumber ?? phone,
        'doctorLicense': a.doctor?.reg ?? '',
        'patientName': name,
        'bookingId': ref.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((e) {
        debugPrint('Firebase booking create failed: $e');
      });
    } else {
      debugPrint('Booking not uploaded: patient is not authenticated.');
    }
    return a;
  }

  bool isFav(Doctor d) => favs.contains(d.reg);
  void toggleFav(Doctor d) {
    if (favs.contains(d.reg)) {
      favs.remove(d.reg);
    } else {
      favs.add(d.reg);
    }
    notifyListeners();
  }

  void markAllRead() {
    for (final n in notifs) {
      n.unread = false;
    }
    notifyListeners();
  }

  List<Review> reviewsOf(Doctor d) => reviews.putIfAbsent(
        d.reg,
        () => [
          const Review('محمد عبد الرحيم', 5, 'دكتور ممتاز ومتعاون، وشرح الحالة بوضوح.', 'منذ أسبوع'),
          const Review('آمنة إبراهيم', 4, 'الكشف كان سريعاً والانتظار قليل.', 'منذ أسبوعين'),
          const Review('خالد يوسف', 5, 'تشخيص دقيق وأنصح به.', 'منذ شهر'),
        ],
      );
}

/// الملف الصحي للمريض (يُجمَع عند التسجيل أو في أي وقت لاحقاً، وكل بند اختياري).
/// answered = البنود التي أجاب عنها المستخدم فعلاً («لا يوجد» إجابة أيضاً) — التخطي لا يُحسب إجابة.
class HealthProfile {
  static const steps = ['chronic', 'meds', 'allergy', 'surgery', 'blood', 'admit'];
  final answered = <String>{};
  final chronic = <String>{};
  String chronicOther = '';
  final meds = <String>[];
  final allergies = <String>{};
  String allergyOther = '';
  bool? surgery, transfusion, admission;
  final surgeries = <String>{};
  String surgeryNote = '', transfusionNote = '', admissionNote = '';

  int get done => steps.where(answered.contains).length;
  bool get complete => done == steps.length;
  bool get any => answered.isNotEmpty;

  List<String> get chronicAll => [...chronic, if (chronicOther.trim().isNotEmpty) chronicOther.trim()];
  List<String> get allergyAll => [...allergies, if (allergyOther.trim().isNotEmpty) allergyOther.trim()];
  List<String> get surgeryAll => surgery == true ? [...surgeries, if (surgeryNote.trim().isNotEmpty) surgeryNote.trim()] : <String>[];

  /// «نعم — التفاصيل» / «لا» / '' (لم يُجب).
  String yn(bool? v, String note) => v == null ? '' : (v ? (note.trim().isEmpty ? 'نعم' : 'نعم — ${note.trim()}') : 'لا');

  /// أول بند لم يُجَب عنه (فهرسه في kHSteps)، أو -1 إن اكتملت.
  int get nextStep {
    for (var i = 0; i < kHSteps.length; i++) {
      final id = kHSteps[i].id;
      if (id != 'photo' && !answered.contains(id)) return i;
    }
    return -1;
  }

  void reset() {
    answered.clear();
    chronic.clear();
    chronicOther = '';
    meds.clear();
    allergies.clear();
    allergyOther = '';
    surgery = transfusion = admission = null;
    surgeries.clear();
    surgeryNote = transfusionNote = admissionNote = '';
  }

  /// نفس أسماء حقول Patient في تطبيق الطبيب (conditions · meds · allergies · surgeries · transfusion · admission).
  Map<String, dynamic> toPlatform() => {
        'conditions': chronicAll,
        'meds': List<String>.from(meds),
        'allergies': allergyAll,
        'surgeries': surgeryAll,
        'transfusion': yn(transfusion, transfusionNote),
        'admission': yn(admission, admissionNote),
      };

  Map<String, dynamic> toJson() => {
        'answered': answered.toList(),
        'chronic': chronic.toList(),
        'chronicOther': chronicOther,
        'meds': meds,
        'allergies': allergies.toList(),
        'allergyOther': allergyOther,
        'surgery': surgery,
        'transfusion': transfusion,
        'admission': admission,
        'surgeries': surgeries.toList(),
        'surgeryNote': surgeryNote,
        'transfusionNote': transfusionNote,
        'admissionNote': admissionNote,
      };

  void loadJson(Map<String, dynamic> j) {
    reset();
    answered.addAll(List<String>.from((j['answered'] ?? const []) as List));
    chronic.addAll(List<String>.from((j['chronic'] ?? const []) as List));
    chronicOther = (j['chronicOther'] ?? '') as String;
    meds.addAll(List<String>.from((j['meds'] ?? const []) as List));
    allergies.addAll(List<String>.from((j['allergies'] ?? const []) as List));
    allergyOther = (j['allergyOther'] ?? '') as String;
    surgery = j['surgery'] as bool?;
    transfusion = j['transfusion'] as bool?;
    admission = j['admission'] as bool?;
    surgeries.addAll(List<String>.from((j['surgeries'] ?? const []) as List));
    surgeryNote = (j['surgeryNote'] ?? '') as String;
    transfusionNote = (j['transfusionNote'] ?? '') as String;
    admissionNote = (j['admissionNote'] ?? '') as String;
  }
}

final app = AppState();

// ───────────────────────── Doctor filter ─────────────────────────
class DocFilter {
  DocFilter({Set<String>? specs, Set<String>? subs, Set<int>? grades, Set<String>? hoods, this.area = 'الكل', this.minRating = 0, this.gender = 0, this.min = 0, this.max = 30000, this.onlyBookable = false})
      : specs = specs ?? <String>{},
        subs = subs ?? <String>{},
        grades = grades ?? <int>{},
        hoods = hoods ?? <String>{};
  final Set<String> specs, subs, hoods;
  final Set<int> grades; // 0 استشاري · 1 أخصائي · 2 مسجّل
  final String area; // المدينة: 'الكل' أو إحدى kCities
  final double minRating, min, max;
  final int gender; // 0 الكل · 1 طبيب · 2 طبيبة
  final bool onlyBookable; // المتاح للحجز عبر التطبيق فقط (المراكز الخضراء)
  int get count => (specs.isNotEmpty ? 1 : 0) + (subs.isNotEmpty ? 1 : 0) + (grades.isNotEmpty ? 1 : 0) + (area != 'الكل' ? 1 : 0) + (hoods.isNotEmpty ? 1 : 0) + (minRating > 0 ? 1 : 0) + (gender != 0 ? 1 : 0) + ((min > 0 || max < 30000) ? 1 : 0) + (onlyBookable ? 1 : 0);
  bool ok(Doctor d) {
    if (specs.isNotEmpty && !specs.contains(d.spec)) return false;
    if (subs.isNotEmpty && !subs.contains(d.sub)) return false;
    if (grades.isNotEmpty && !grades.contains(d.grade)) return false;
    if (hoods.isNotEmpty) {
      if (!d.works.any((w) => hoods.contains(w.clinic.hood))) return false;
    } else if (area != 'الكل' && !d.works.any((w) => w.clinic.city == area)) {
      return false;
    }
    if (onlyBookable && !d.canBook) return false;
    if (double.tryParse(d.rating) != null && double.parse(d.rating) < minRating) return false;
    if (gender == 1 && d.female) return false;
    if (gender == 2 && !d.female) return false;
    return d.fee >= min && d.fee <= max;
  }
}

// ───────────────────────── 1. Splash (modern hero, no stock photo) ─────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController ctl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    // حساب محفوظ على هذا الجهاز ← الرئيسية مباشرة بلا تسجيل دخول (مثل واتساب).
    if (app.registered) {
      Future.microtask(() {
        if (mounted) home(context);
      });
    }
  }

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  Widget bob(Widget w, double k) => AnimatedBuilder(
        animation: ctl,
        builder: (_, child) => Transform.translate(offset: Offset(0, (ctl.value - .5) * 14 * k), child: child),
        child: w,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFFFF1F2)]))),
          ),
          Positioned(top: -100, right: -80, child: ring(300, const Color(0x14D9141E))),
          Positioned(top: 140, left: -130, child: ring(250, const Color(0x0F3B6EF5))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(children: [
                const Spacer(),
                SizedBox(
                  width: 330,
                  height: 300,
                  child: Stack(alignment: Alignment.center, children: [
                    Orb(SizedBox(width: 56, height: 52, child: CustomPaint(painter: HeartPainter())), size: 270, white: true),
                    Positioned(top: 14, right: 0, child: bob(floatChip(Icons.event_available_rounded, 'حجز طبيب', kRed), 1)),
                    Positioned(top: 112, left: 0, child: bob(floatChip(Icons.emergency_rounded, 'إسعاف سريع', kOrange), -1)),
                    Positioned(bottom: 52, right: 4, child: bob(floatChip(Icons.science_rounded, 'تحاليل منزلية', kTeal), -1.2)),
                    Positioned(bottom: 6, left: 24, child: bob(floatChip(Icons.bed_rounded, 'حجز سرير', kBlue), 1.2)),
                  ]),
                ),
                gap(6),
                ShaderMask(
                  shaderCallback: (r) => kGradient.createShader(r),
                  child: Text('طبيبك', style: t(62, c: Colors.white, h: 1.25)),
                ),
                Text('صحتك .. أولويتنا', style: t(18, w: FontWeight.w600, c: kSub)),
                gap(10),
                Text('احجز طبيبك، اطلب إسعافك، وتابع صحتك من مكان واحد.', textAlign: TextAlign.center, style: t(13.5, w: FontWeight.w500, c: kGrey, h: 1.7)),
                const Spacer(),
                RedButton('ابدأ الآن', arrow: true, height: 58, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()))),
                gap(6),
                Tap(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text.rich(TextSpan(text: 'لديك حساب؟ ', style: t(13, w: FontWeight.w500, c: kGrey), children: [TextSpan(text: 'تسجيل الدخول', style: t(13, c: kRed))])),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      );
}

// ───────────────────────── 2. Onboarding ─────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  final pc = PageController();
  int i = 0;
  static const pages = [
    (Icons.event_available_rounded, 'احجز طبيبك بسهولة', 'اختر الطبيب والموعد المناسب لك، وأكّد حجزك في دقائق.'),
    (Icons.vaccines_rounded, 'خدمات طبية في منزلك', 'زيارة طبيب أو ممرض وسحب عينات المعمل دون عناء الانتقال.'),
    (Icons.emergency_rounded, 'إسعاف سريع وتتبّع مباشر', 'اطلب الإسعاف وتابع وصوله على الخريطة لحظة بلحظة.'),
  ];
  static const chips = [
    [(Icons.star_rounded, '4.8 تقييم', kGold), (Icons.schedule_rounded, 'مواعيد دقيقة', kBlue)],
    [(Icons.home_rounded, 'في منزلك', kTeal), (Icons.science_rounded, 'نتائج سريعة', kRed)],
    [(Icons.my_location_rounded, 'تتبّع مباشر', kBlue), (Icons.timer_rounded, 'خلال دقائق', kOrange)],
  ];

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  void next() {
    if (i == pages.length - 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      pc.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          Column(children: [
            Expanded(
              child: PageView.builder(
                controller: pc,
                itemCount: pages.length,
                onPageChanged: (v) => setState(() => i = v),
                itemBuilder: (_, k) => Column(children: [
                  Container(
                    height: 390,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(56))),
                    child: Stack(alignment: Alignment.center, children: [
                      Positioned(top: -70, left: -50, child: ring(210, const Color(0x14FFFFFF))),
                      Positioned(bottom: -60, right: -40, child: ring(180, const Color(0x0FFFFFFF))),
                      Orb(Icon(pages[k].$1, color: kRed, size: 46), size: 260, onDark: true),
                      Positioned(top: 100, right: 24, child: floatChip(chips[k][0].$1, chips[k][0].$2, chips[k][0].$3)),
                      Positioned(bottom: 56, left: 22, child: floatChip(chips[k][1].$1, chips[k][1].$2, chips[k][1].$3)),
                    ]),
                  ),
                  gap(30),
                  Text(pages[k].$2, style: t(22)),
                  Padding(padding: const EdgeInsets.fromLTRB(36, 10, 36, 0), child: Text(pages[k].$3, textAlign: TextAlign.center, style: t(14, w: FontWeight.w500, c: kGrey, h: 1.7))),
                ]),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var k = 0; k < pages.length; k++)
                AnimatedContainer(duration: const Duration(milliseconds: 220), margin: const EdgeInsets.all(3), width: k == i ? 26 : 8, height: 8, decoration: BoxDecoration(color: k == i ? kRed : kLine, borderRadius: BorderRadius.circular(4))),
            ]),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
              child: RedButton(i == pages.length - 1 ? 'ابدأ الآن' : 'التالي', arrow: true, onTap: next),
            ),
          ]),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: i == pages.length - 1
                ? const SizedBox.shrink()
                : Tap(
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(20)), child: Text('تخطي', style: t(13, c: Colors.white))),
                  ),
          ),
        ]),
      );
}

// ───────────────────────── 3. Login / OTP / Register ─────────────────────────
Widget authHeader({double height = 270}) => Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(56))),
      child: Stack(children: [
        Positioned(top: -60, left: -40, child: ring(200, const Color(0x14FFFFFF))),
        Positioned(bottom: -50, right: -30, child: ring(170, const Color(0x0FFFFFFF))),
        SafeArea(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 82,
                height: 82,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))]),
                child: SizedBox(width: 44, height: 40, child: CustomPaint(painter: HeartPainter())),
              ),
              gap(10),
              Text('طبيبك', style: t(32, c: Colors.white)),
              Text('صحتك .. أولويتنا', style: t(13, w: FontWeight.w500, c: const Color(0xE6FFFFFF))),
            ]),
          ),
        ),
      ]),
    );

// ───────────────────────── الهوية الموحّدة ─────────────────────────
// هذه الدوال نسخة طبق الأصل من تطبيقَي الطبيب والمركز. الهاتف هو هوية المريض في التطبيقات الثلاثة،
// فيُخزَّن دائماً +249XXXXXXXXX بلا مسافات ويُعرض عبر fmtPhone فقط.

/// يحوّل الأرقام العربية (٠-٩) والفارسية (۰-۹) إلى لاتينية.
String latin(String s) => String.fromCharCodes(s.runes.map((r) => r >= 0x660 && r <= 0x669 ? r - 0x660 + 48 : r >= 0x6F0 && r <= 0x6F9 ? r - 0x6F0 + 48 : r));

/// يوحّد رقم الهاتف السوداني إلى +249XXXXXXXXX، ويرجع null إن لم يكن صالحاً.
/// يقبل: 912345678 · 0912345678 · +249912345678 · 00249912345678 (وبالأرقام العربية).
String? normPhone(String raw) {
  var s = latin(raw).replaceAll(RegExp(r'[\s\-().]'), '');
  if (s.startsWith('00')) {
    s = '+${s.substring(2)}';
  } else if (s.startsWith('+')) {
    // جاهز
  } else if (s.startsWith('249')) {
    s = '+$s';
  } else if (s.startsWith('0')) {
    s = '+249${s.substring(1)}';
  } else {
    s = '+249$s';
  }
  return RegExp(r'^\+249[19]\d{8}$').hasMatch(s) ? s : null;
}

String fmtPhone(String p) => p.length == 13 && p.startsWith('+249') ? '${p.substring(0, 4)} ${p.substring(4, 7)} ${p.substring(7, 10)} ${p.substring(10)}' : p;

/// يقبل الأرقام اللاتينية والعربية فقط في حقول الهاتف والرمز.
final digitsFmt = FilteringTextInputFormatter.allow(RegExp('[0-9\u0660-\u0669\u06F0-\u06F9]'));

/// «5:30 م» / «٥:٣٠ م» / «17:30» → دقائق منذ منتصف الليل، أو null إن كانت الصيغة غير صالحة.
int? parseTime(String raw) {
  final m = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*([صم])?$').firstMatch(latin(raw).trim());
  if (m == null) return null;
  var h = int.parse(m.group(1)!);
  final mn = m.group(2) == null ? 0 : int.parse(m.group(2)!);
  final ap = m.group(3);
  if (mn > 59) return null;
  if (ap != null) {
    if (h < 1 || h > 12) return null;
    h = h % 12 + (ap == 'م' ? 12 : 0);
  } else if (h > 23) {
    return null;
  }
  return h * 60 + mn;
}

/// الدقائق منذ منتصف الليل → «5:30 م» (نفس صيغة تطبيقَي الطبيب والمركز).
String fmtTime(int m) {
  final h24 = m ~/ 60, mn = m % 60;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${mn.toString().padLeft(2, '0')} ${h24 >= 12 ? 'م' : 'ص'}';
}

/// بيانات العرض التجريبية (حجوزات وعناوين وعائلة...). للإنتاج: --dart-define=DEMO_DATA=false
const kDemoData = bool.fromEnvironment('DEMO_DATA', defaultValue: true);

/// يعرض رمز التحقق على الشاشة (لا SMS فعلية في هذه النسخة). للإنتاج: --dart-define=DEMO_OTP=false
const kDemoOtp = bool.fromEnvironment('DEMO_OTP', defaultValue: true);

// ───────────────────────── رمز التحقق (OTP) ─────────────────────────
class _OtpEntry {
  _OtpEntry(this.code) : at = DateTime.now();
  final String code;
  final DateTime at;
  int tries = 0;
}

/// نموذج محلي لرمز التحقق — نفس سلوك تطبيقَي الطبيب والمركز (6 أرقام · 5 دقائق · 5 محاولات).
/// في الإنتاج: الخادم يولّد الرمز ويرسله بـ SMS ولا يعيده للتطبيق أبداً، ويتحقق منه ويحدّ الإرسال لكل رقم.
class OtpService {
  final _m = <String, _OtpEntry>{};
  static const maxTries = 5;
  static const ttl = Duration(minutes: 5);

  String send(String phone) {
    final code = (100000 + math.Random.secure().nextInt(900000)).toString();
    _m[phone] = _OtpEntry(code);
    return code;
  }

  /// يرجع null عند النجاح، وإلا رسالة الخطأ.
  String? check(String phone, String code) {
    final o = _m[phone];
    if (o == null) return 'اطلب رمزاً جديداً أولاً';
    if (DateTime.now().difference(o.at) > ttl) {
      _m.remove(phone);
      return 'انتهت صلاحية الرمز، اطلب رمزاً جديداً';
    }
    o.tries++;
    if (o.code != code) {
      if (o.tries >= maxTries) {
        _m.remove(phone);
        return 'تجاوزت عدد المحاولات، اطلب رمزاً جديداً';
      }
      return 'الرمز غير صحيح (${maxTries - o.tries} محاولات متبقية)';
    }
    _m.remove(phone);
    return null;
  }
}

final otp = OtpService();

// ───────────────────────── تخزين الجهاز (تسجيل مرة واحدة كالواتساب) ─────────────────────────
abstract class StoreBackend {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
}

/// الافتراضي: في الذاكرة فقط (يضيع عند إغلاق التطبيق تماماً).
class MemoryBackend implements StoreBackend {
  final _m = <String, String>{};
  @override
  String? read(String key) => _m[key];
  @override
  void write(String key, String value) => _m[key] = value;
  @override
  void remove(String key) => _m.remove(key);
}

// لجعل الدخول مباشراً حتى بعد إغلاق التطبيق وفتحه: أضف shared_preferences إلى pubspec.yaml ثم فعّل هذا الكود
// واضبط السطر المعلّق داخل main():
//
//   class PrefsBackend implements StoreBackend {
//     PrefsBackend(this.p);
//     final SharedPreferences p;
//     @override String? read(String k) => p.getString(k);
//     @override void write(String k, String v) => p.setString(k, v);
//     @override void remove(String k) => p.remove(k);
//   }

/// الحساب المحفوظ على هذا الجهاز: إن وُجد يفتح التطبيق مباشرة على الرئيسية بلا تسجيل دخول.
class DeviceStore {
  static StoreBackend backend = MemoryBackend();
  static const _k = 'tabibak.account';

  static Map<String, dynamic>? read() {
    final s = backend.read(_k);
    if (s == null) return null;
    try {
      final m = jsonDecode(s);
      return m is Map<String, dynamic> ? m : null;
    } catch (_) {
      return null;
    }
  }

  static void write(Map<String, dynamic> j) => backend.write(_k, jsonEncode(j));
  static void clear() => backend.remove(_k);
}

/// دليل الحسابات (محاكاة الخادم): رقم الهاتف ← الحساب. يسمح بالدخول من جهاز آخر (أو بعد إعادة التثبيت)
/// برقمك + رمز التحقق فتعود بياناتك. في الإنتاج هذا جدول على الخادم، والهاتف فيه فريد.
final userDir = <String, Map<String, dynamic>>{};

/// صور رمزية جاهزة (الفهرس 0 محجوز للحرف الأول من الاسم).
const kAvatars = [
  (Icons.person_rounded, kRed),
  (Icons.face_rounded, kBlue),
  (Icons.sentiment_satisfied_alt_rounded, kTeal),
  (Icons.emoji_emotions_rounded, kOrange),
  (Icons.favorite_rounded, kRed),
  (Icons.star_rounded, kGold),
  (Icons.pets_rounded, kGreenDk),
  (Icons.wb_sunny_rounded, kAmber),
  (Icons.local_florist_rounded, kPurple),
];

/// التقاط صورة من الكاميرا/المعرض. null = غير مفعّل فتظهر الصور الرمزية فقط.
/// للتفعيل أضف image_picker ثم عيّن في main():
///   kPhotoPicker = (camera) async {
///     final f = await ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, maxWidth: 600, imageQuality: 80);
///     return f?.readAsBytes();
///   };
typedef PhotoPicker = Future<Uint8List?> Function(bool camera);
PhotoPicker? kPhotoPicker;

/// صورة المستخدم: صورته إن وُجدت، وإلا الصورة الرمزية، وإلا الحرف الأول من اسمه.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.size = 56, this.light = false});
  final double size;
  final bool light; // خلفية بيضاء فوق الترويسة الحمراء

  @override
  Widget build(BuildContext context) {
    final ph = app.photo;
    if (ph != null) return ClipOval(child: Image.memory(ph, width: size, height: size, fit: BoxFit.cover));
    if (app.avatar > 0 && app.avatar < kAvatars.length) {
      final a = kAvatars[app.avatar];
      return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: grad(a.$2)), child: Icon(a.$1, color: Colors.white, size: size * .55));
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: light ? null : kGradient, color: light ? Colors.white : null, boxShadow: light ? null : kGlow),
      child: Text(initial(app.name), style: t(size * .42, c: light ? kRed : Colors.white)),
    );
  }
}

Future<void> _takePhoto(BuildContext ctx, bool camera) async {
  final b = await kPhotoPicker!(camera);
  if (b != null) {
    app.photo = b;
    app.avatar = 0;
    app.ping();
  }
  if (ctx.mounted) Navigator.pop(ctx);
}

/// ورقة اختيار الصورة الشخصية (كاميرا/معرض إن فُعّلت، وصور رمزية دائماً).
Future<void> photoSheet(BuildContext c) async {
  await sheet<void>(
    c,
    Column(mainAxisSize: MainAxisSize.min, children: [
      Text('صورتك الشخصية', style: t(17)),
      gap(14),
      if (kPhotoPicker != null) ...[
        Row(children: [
          Expanded(child: RedButton('الكاميرا', icon: Icons.photo_camera_rounded, height: 48, onTap: () => _takePhoto(c, true))),
          gapW(10),
          Expanded(child: OutBtn('المعرض', icon: Icons.photo_library_rounded, onTap: () => _takePhoto(c, false))),
        ]),
        gap(14),
      ],
      Text('اختر صورة رمزية', style: t(12.5, w: FontWeight.w500, c: kGrey)),
      gap(10),
      Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
        for (var i = 1; i < kAvatars.length; i++)
          Tap(
            onTap: () {
              app.avatar = i;
              app.photo = null;
              app.ping();
              Navigator.pop(c);
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: grad(kAvatars[i].$2), border: app.photo == null && app.avatar == i ? Border.all(color: kInk, width: 3) : null),
              child: Icon(kAvatars[i].$1, color: Colors.white, size: 30),
            ),
          ),
      ]),
      if (app.photo != null || app.avatar != 0) ...[
        gap(14),
        OutBtn('إزالة الصورة', danger: true, onTap: () {
          app.avatar = 0;
          app.photo = null;
          app.ping();
          Navigator.pop(c);
        }),
      ],
    ]),
  );
}

/// شاشات الحجز لا تُفتح للزائر: يُعاد للخلف ويُدعى للتسجيل (المركز والطبيب يحتاجان رقمه). تُستدعى من initState.
void gate(BuildContext c) => WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (app.registered || !c.mounted) return;
      final nav = Navigator.of(c);
      nav.pop();
      final ok = await confirm(nav.context, 'سجّل رقمك أولاً', 'نحتاج رقم هاتفك ليتواصل معك المركز والطبيب بخصوص حجزك. التسجيل مرة واحدة فقط.', yes: 'تسجيل الآن', no: 'لاحقاً', danger: false);
      if (ok && nav.mounted) nav.push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    });

// ───────────────────────── تسجيل مرة واحدة (مثل واتساب): هاتف ← رمز ← اسم ← ملف صحي اختياري ─────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final ph = TextEditingController();
  String? err;

  @override
  void dispose() {
    ph.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (!firebaseReady) {
      setState(() => err =
          'خدمة التسجيل غير مهيأة حالياً. تحقق من إعدادات Firebase وملف google-services.json.');
      return;
    }
    final n = normPhone(ph.text);
    if (n == null) {
      setState(() => err = 'أدخل رقم هاتف سوداني صحيح (مثال: 912345678)');
      return;
    }
    setState(() => err = null);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: n,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } catch (e) {
            debugPrint('Automatic phone verification failed: $e');
          }
        },
        verificationFailed: (e) {
          if (mounted) setState(() => err = e.message ?? 'تعذر إرسال رمز التحقق');
        },
        codeSent: (verificationId, resendToken) {
          if (mounted) go(context, OtpScreen(n, verificationId: verificationId));
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => err = e.message ?? 'حدث خطأ في التحقق');
    } catch (e) {
      if (mounted) setState(() => err = 'تعذر الاتصال بخدمة التحقق: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
          authHeader(),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 16), children: [
              Center(child: Text('أهلاً بك في طبيبك', style: t(22))),
              gap(6),
              Center(child: Text('سجّل رقم هاتفك مرة واحدة فقط، وبعدها يفتح التطبيق مباشرة على هذا الجهاز بدون تسجيل دخول.', textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: kGrey, h: 1.7))),
              AppField('رقم الهاتف', controller: ph, hint: '9XX XXX XXX', icon: Icons.phone_outlined, type: TextInputType.phone, ltr: true, prefixText: '+249  ', fmt: [digitsFmt, LengthLimitingTextInputFormatter(14)], error: err, onChanged: (_) {
                if (err != null) setState(() => err = null);
              }),
              gap(20),
              RedButton('موافقة ومتابعة', arrow: true, onTap: send),
              gap(12),
              OutBtn('المتابعة كزائر', onTap: () => home(context)),
              gap(18),
              Tap(
                onTap: () => go(context, InfoScreen.terms()),
                child: Center(child: Text('بالمتابعة أنت توافق على الشروط والأحكام', style: t(11.5, w: FontWeight.w500, c: kGrey))),
              ),
            ]),
          ),
        ]),
      );
}

class OtpScreen extends StatefulWidget {
  const OtpScreen(this.phone, {required this.verificationId, super.key});
  final String phone; // +249XXXXXXXXX (normPhone)
  final String verificationId;
  @override
  State<OtpScreen> createState() => _OtpState();
}

class _OtpState extends State<OtpScreen> {
  static const len = 6;
  final cs = List.generate(len, (_) => TextEditingController());
  final fs = List.generate(len, (_) => FocusNode());
  int left = 45;
  Timer? timer;
  String? err;
  bool busy = false;
  String demoCode = '';
  late String currentVerificationId;

  @override
  void initState() {
    super.initState();
    currentVerificationId = widget.verificationId;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (left > 0 && mounted) setState(() => left--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in cs) {
      c.dispose();
    }
    for (final f in fs) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> verify() async {
    if (busy) return;
    if (!firebaseReady) {
      setState(() => err = 'خدمة التحقق غير متاحة بسبب إعدادات Firebase.');
      return;
    }
    final code = cs.map((c) => latin(c.text)).join();
    if (code.length != len) {
      setState(() => err = 'أدخل الرمز المكوّن من $len أرقام');
      return;
    }
    setState(() { busy = true; err = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: currentVerificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('تم التحقق لكن لم يتم إنشاء جلسة تسجيل الدخول.');
      }

      Map<String, dynamic>? saved;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        saved = userDoc.data();
      } catch (e) {
        // فشل قراءة Firestore لا يلغي نجاح التحقق برقم الهاتف.
        debugPrint('Could not load patient profile from Firestore: $e');
      }

      if (saved != null && (saved['name'] as String? ?? '').isNotEmpty) {
        try {
          app.loadJson(saved);
          app.ping();
        } catch (e) {
          debugPrint('Could not restore cloud patient profile: $e');
          app.createAccount(widget.phone, '');
        }
        if (!mounted) return;
        snack(context, 'أهلاً بعودتك ${app.first}', ok: true);
        home(context);
      } else {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => NameScreen(widget.phone)),
          (r) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { err = e.message ?? 'رمز التحقق غير صحيح'; busy = false; });
    } catch (e) {
      if (mounted) setState(() { err = 'تعذر إكمال تسجيل الدخول: $e'; busy = false; });
    }
  }

  Future<void> resend() async {
    if (left > 0) return;
    if (!firebaseReady) {
      setState(() => err = 'خدمة إعادة إرسال الرمز غير متاحة حالياً.');
      return;
    }
    setState(() { left = 45; err = null; });
    for (final c in cs) { c.clear(); }
    fs[0].requestFocus();
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (e) {
        if (mounted) setState(() => err = e.message ?? 'تعذر إعادة إرسال الرمز');
      },
      codeSent: (id, token) {
        if (mounted) setState(() => currentVerificationId = id);
        if (mounted) snack(context, 'تم إرسال رمز جديد', ok: true);
      },
      codeAutoRetrievalTimeout: (id) { currentVerificationId = id; },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => err = e.message ?? 'تعذر إعادة إرسال الرمز');
    } catch (e) {
      if (mounted) setState(() => err = 'تعذر إعادة إرسال الرمز: $e');
    }
  }

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'رمز التحقق',
        bottomBar: btnBar(context, 'تأكيد', verify),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          gap(6),
          Center(child: gTile(Icons.verified_user_rounded, size: 78)),
          gap(16),
          Center(child: Text('أدخل رمز التحقق', style: t(20))),
          gap(6),
          Center(child: Text('أرسلنا رمزاً من $len أرقام إلى', style: t(13, w: FontWeight.w500, c: kGrey))),
          Center(child: Directionality(textDirection: TextDirection.ltr, child: Text(fmtPhone(widget.phone), style: t(15, c: kInk)))),
          gap(24),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < len; i++)
                Container(
                  width: 46,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: err != null ? kRed : kLine, width: 1.5), boxShadow: kShadow),
                  child: TextField(
                    controller: cs[i],
                    focusNode: fs[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [digitsFmt],
                    style: t(22),
                    decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                    onChanged: (v) {
                      if (err != null) setState(() => err = null);
                      if (v.isNotEmpty && i < len - 1) fs[i + 1].requestFocus();
                      if (v.isEmpty && i > 0) fs[i - 1].requestFocus();
                      if (v.isNotEmpty && i == len - 1) verify();
                    },
                  ),
                ),
            ]),
          ),
          if (err != null) Padding(padding: const EdgeInsets.only(top: 10), child: Center(child: Text(err!, style: t(12, c: kRed)))),
          gap(20),
          Center(
            child: left > 0
                ? Text.rich(TextSpan(text: 'إعادة إرسال الرمز بعد ', style: t(12.5, w: FontWeight.w500, c: kGrey), children: [TextSpan(text: '00:${left.toString().padLeft(2, '0')}', style: t(12.5, c: kRed))]))
                : Tap(onTap: resend, child: Padding(padding: const EdgeInsets.all(8), child: Text('إعادة إرسال الرمز', style: t(13.5, c: kRed)))),
          ),
          if (kDemoOtp) ...[
            gap(14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kAmberBg, borderRadius: BorderRadius.circular(14)),
              child: Text('وضع تجريبي: لا تُرسَل رسالة SMS فعلية.\nرمز التحقق: $demoCode', textAlign: TextAlign.center, style: t(12.5, c: kAmber, h: 1.7)),
            ),
          ],
        ]),
      );
}

/// أول مرة فقط: الاسم (مطلوب) والجنس وتاريخ الميلاد (اختياريان) — ثم يُنشأ الحساب ويُحفظ على الجهاز.
class NameScreen extends StatefulWidget {
  const NameScreen(this.phone, {super.key});
  final String phone;
  @override
  State<NameScreen> createState() => _NameState();
}

class _NameState extends State<NameScreen> {
  final nm = TextEditingController();
  String dob = '';
  int gender = -1;
  String? err;

  @override
  void dispose() {
    nm.dispose();
    super.dispose();
  }

  void next() {
    final n = nm.text.trim();
    if (n.length < 3) {
      setState(() => err = 'اكتب اسمك (3 حروف على الأقل)');
      return;
    }
    app.createAccount(widget.phone, n, gender: gender == 0 ? 'ذكر' : (gender == 1 ? 'أنثى' : ''), dob: dob);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HealthSetupScreen(0)));
  }

  Widget genderCard(int i, String text, IconData icon) => Expanded(
        child: Tap(
          onTap: () => setState(() => gender = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 84,
            decoration: BoxDecoration(gradient: gender == i ? kGradient : null, color: gender == i ? null : Colors.white, borderRadius: BorderRadius.circular(20), border: gender == i ? null : Border.all(color: kLine, width: 1.5), boxShadow: gender == i ? kGlow : null),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 30, color: gender == i ? Colors.white : kGrey),
              gap(4),
              Text(text, style: t(16, c: gender == i ? Colors.white : kInk)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'حسابك',
        back: false,
        bottomBar: btnBar(context, 'التالي', next),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          gap(6),
          Center(child: gTile(Icons.person_rounded, size: 78)),
          gap(16),
          Center(child: Text('ما اسمك؟', style: t(24))),
          gap(6),
          Center(child: Text('اكتب اسمك كما تحب أن يناديك به الطبيب', style: t(13, w: FontWeight.w500, c: kGrey))),
          AppField('الاسم', controller: nm, hint: 'مثال: أحمد محمد علي', icon: Icons.person_outline_rounded, error: err, onChanged: (_) {
            if (err != null) setState(() => err = null);
          }),
          sec('أنت؟ (اختياري)'),
          Row(children: [genderCard(0, 'ذكر', Icons.male_rounded), gapW(12), genderCard(1, 'أنثى', Icons.female_rounded)]),
          sec('تاريخ الميلاد (اختياري)'),
          Tap(
            onTap: () async {
              final v = await pickDob(context);
              if (v != null && mounted) setState(() => dob = v);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: cardBox(16),
              child: Row(children: [
                const Icon(Icons.cake_rounded, color: kRed),
                gapW(12),
                Text(dob.isEmpty ? 'اضغط لاختيار تاريخ ميلادك' : dob, style: t(14.5, w: FontWeight.w600, c: dob.isEmpty ? kGrey : kInk)),
              ]),
            ),
          ),
        ]),
      );
}

// ───────────────────────── الملف الصحي (كل خطوة اختيارية ويمكن إكمالها في أي وقت) ─────────────────────────
class HStep {
  const HStep(this.id, this.icon, this.color, this.title, this.hint);
  final String id, title, hint;
  final IconData icon;
  final Color color;
}

const kHSteps = [
  HStep('photo', Icons.add_a_photo_rounded, kBlue, 'صورتك الشخصية', 'اختر صورة تظهر في حسابك. يمكنك التخطي.'),
  HStep('chronic', Icons.favorite_rounded, kRed, 'هل عندك مرض مزمن؟', 'اضغط على كل مرض عندك. وإن لم تكن متأكداً اضغط «تخطي».'),
  HStep('meds', Icons.medication_rounded, kTeal, 'ما الأدوية التي تستخدمها الآن؟', 'اضغط على الدواء أو اكتب اسمه.'),
  HStep('allergy', Icons.warning_amber_rounded, kOrange, 'هل عندك حساسية من شيء؟', 'من دواء أو أكل أو غبار.'),
  HStep('surgery', Icons.healing_rounded, kBlue, 'هل أجريت عملية جراحية من قبل؟', ''),
  HStep('blood', Icons.bloodtype_rounded, kRed, 'هل نُقل لك دم من قبل؟', ''),
  HStep('admit', Icons.local_hospital_rounded, kTeal, 'هل دخلت المستشفى للتنويم من قبل؟', 'أي إقامة في المستشفى ليلة أو أكثر.'),
];

const kHLabels = {'photo': 'الصورة الشخصية', 'chronic': 'الأمراض المزمنة', 'meds': 'الأدوية الحالية', 'allergy': 'الحساسية', 'surgery': 'العمليات الجراحية', 'blood': 'نقل الدم', 'admit': 'دخول المستشفى'};
const kChronic = ['السكري', 'ضغط الدم', 'أمراض القلب', 'الربو / ضيق التنفس', 'أمراض الكلى', 'أمراض الكبد', 'الغدة الدرقية', 'فقر الدم المنجلي', 'الصرع', 'السرطان', 'ارتفاع الكوليسترول', 'الروماتيزم والمفاصل', 'أمراض نفسية', 'التهاب الكبد الفيروسي'];
const kAllergies = ['البنسلين', 'الأسبرين', 'السلفا', 'بعض الأطعمة', 'الغبار والأتربة', 'اللاتكس (المطاط)'];
const kSurgeries = ['ولادة قيصرية', 'الزائدة الدودية', 'المرارة', 'الفتق', 'عظام وكسور', 'القلب', 'الكلى والمسالك', 'العيون', 'عملية أخرى'];
const kCommonMeds = ['ميتفورمين', 'أنسولين', 'أملوديبين', 'أسبرين', 'أتورفاستاتين', 'بخاخ فنتولين', 'باراسيتامول', 'أوميبرازول'];

/// خطوة واحدة من الملف الصحي: أزرار كبيرة وأسئلة بسيطة. «لا» و«لا يوجد» تحفظ وتنتقل فوراً بضغطة واحدة.
class HealthSetupScreen extends StatefulWidget {
  const HealthSetupScreen(this.step, {super.key, this.mode = 0});
  final int step;
  final int mode; // 0 أول مرة بعد التسجيل · 1 إكمال متسلسل من «ملفي الصحي» · 2 تعديل بند واحد
  @override
  State<HealthSetupScreen> createState() => _HealthSetupState();
}

class _HealthSetupState extends State<HealthSetupScreen> {
  HStep get s => kHSteps[widget.step];
  HealthProfile get h => app.health;
  Set<String> sel = {};
  List<String> meds = [];
  bool? yes;
  bool none = false;
  final other = TextEditingController();
  final note = TextEditingController();
  final medCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    switch (s.id) {
      case 'chronic':
        sel = {...h.chronic};
        other.text = h.chronicOther;
        none = h.answered.contains('chronic') && h.chronicAll.isEmpty;
        break;
      case 'meds':
        meds = [...h.meds];
        none = h.answered.contains('meds') && h.meds.isEmpty;
        break;
      case 'allergy':
        sel = {...h.allergies};
        other.text = h.allergyOther;
        none = h.answered.contains('allergy') && h.allergyAll.isEmpty;
        break;
      case 'surgery':
        yes = h.surgery;
        sel = {...h.surgeries};
        note.text = h.surgeryNote;
        break;
      case 'blood':
        yes = h.transfusion;
        note.text = h.transfusionNote;
        break;
      case 'admit':
        yes = h.admission;
        note.text = h.admissionNote;
        break;
    }
  }

  @override
  void dispose() {
    other.dispose();
    note.dispose();
    medCtl.dispose();
    super.dispose();
  }

  void commit() {
    switch (s.id) {
      case 'chronic':
        if (none || sel.isNotEmpty || other.text.trim().isNotEmpty) {
          h.chronic
            ..clear()
            ..addAll(sel);
          h.chronicOther = other.text.trim();
          h.answered.add('chronic');
        }
        break;
      case 'meds':
        if (none || meds.isNotEmpty) {
          h.meds
            ..clear()
            ..addAll(meds);
          h.answered.add('meds');
        }
        break;
      case 'allergy':
        if (none || sel.isNotEmpty || other.text.trim().isNotEmpty) {
          h.allergies
            ..clear()
            ..addAll(sel);
          h.allergyOther = other.text.trim();
          h.answered.add('allergy');
        }
        break;
      case 'surgery':
        if (yes != null) {
          h.surgery = yes;
          h.surgeries
            ..clear()
            ..addAll(yes! ? sel : <String>{});
          h.surgeryNote = yes! ? note.text.trim() : '';
          h.answered.add('surgery');
        }
        break;
      case 'blood':
        if (yes != null) {
          h.transfusion = yes;
          h.transfusionNote = yes! ? note.text.trim() : '';
          h.answered.add('blood');
        }
        break;
      case 'admit':
        if (yes != null) {
          h.admission = yes;
          h.admissionNote = yes! ? note.text.trim() : '';
          h.answered.add('admit');
        }
        break;
    }
    app.ping();
  }

  void next() {
    if (widget.mode == 2) {
      Navigator.pop(context);
      return;
    }
    final n = widget.step + 1;
    if (n >= kHSteps.length) {
      if (widget.mode == 0) {
        home(context);
      } else {
        Navigator.pop(context);
      }
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HealthSetupScreen(n, mode: widget.mode)));
  }

  void later() {
    if (widget.mode == 0) {
      home(context);
    } else {
      Navigator.pop(context);
    }
  }

  // ── عناصر كبيرة وواضحة ──
  Widget big(String text, bool on, VoidCallback tap) => Tap(
        onTap: tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(gradient: on ? kGradient : null, color: on ? null : Colors.white, borderRadius: BorderRadius.circular(18), border: on ? null : Border.all(color: kLine, width: 1.5), boxShadow: on ? kGlow : null),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (on) ...[const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20), const SizedBox(width: 6)],
            Text(text, style: t(15.5, c: on ? Colors.white : kInk)),
          ]),
        ),
      );

  Widget noneBtn(String text) => Tap(
        onTap: () {
          setState(() {
            sel.clear();
            meds.clear();
            other.clear();
            none = true;
          });
          commit();
          next();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: none ? kGreenBg : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: none ? kGreen : kLine, width: 1.5)),
          child: Row(children: [
            Icon(none ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: none ? kGreenDk : kGrey),
            gapW(10),
            Expanded(child: Text(text, style: t(16, c: none ? kGreenDk : kInk))),
          ]),
        ),
      );

  Widget chipsBody(List<String> items, String noneText, String otherLabel, String otherHint) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        noneBtn(noneText),
        gap(14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final it in items)
            big(it, sel.contains(it), () {
              setState(() {
                if (!sel.remove(it)) sel.add(it);
                none = false;
              });
            }),
        ]),
        AppField(otherLabel, controller: other, hint: otherHint, onChanged: (_) {
          if (none) setState(() => none = false);
        }),
      ]);

  void addMed() {
    final v = medCtl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      if (!meds.contains(v)) meds.add(v);
      none = false;
      medCtl.clear();
    });
  }

  Widget medsBody() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        noneBtn('لا أستخدم أي أدوية'),
        gap(14),
        Text('أدوية شائعة (اضغط لإضافتها)', style: t(12.5, w: FontWeight.w600, c: kGrey)),
        gap(8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final m in kCommonMeds)
            big(m, meds.contains(m), () {
              setState(() {
                if (!meds.remove(m)) meds.add(m);
                none = false;
              });
            }),
        ]),
        gap(4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: AppField('دواء آخر', controller: medCtl, hint: 'اكتب اسم الدواء')),
          gapW(10),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Tap(onTap: addMed, child: Container(width: 52, height: 52, decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.add_rounded, color: Colors.white, size: 28))),
          ),
        ]),
        gap(10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in meds.where((m) => !kCommonMeds.contains(m)))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(m, style: t(13.5, c: kRed)),
                gapW(6),
                Tap(onTap: () => setState(() => meds.remove(m)), child: const Icon(Icons.close_rounded, size: 18, color: kRed)),
              ]),
            ),
        ]),
      ]);

  Widget yn(String text, bool v, IconData icon) => Expanded(
        child: Tap(
          onTap: () {
            setState(() => yes = v);
            if (!v) {
              commit();
              next();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 92,
            decoration: BoxDecoration(gradient: yes == v ? kGradient : null, color: yes == v ? null : Colors.white, borderRadius: BorderRadius.circular(22), border: yes == v ? null : Border.all(color: kLine, width: 1.5), boxShadow: yes == v ? kGlow : null),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 32, color: yes == v ? Colors.white : kGrey),
              gap(4),
              Text(text, style: t(20, c: yes == v ? Colors.white : kInk)),
            ]),
          ),
        ),
      );

  Widget yesNoBody({String chipsTitle = '', List<String> chips = const [], required String noteHint}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [yn('نعم', true, Icons.check_circle_rounded), gapW(14), yn('لا', false, Icons.cancel_rounded)]),
        if (yes == true) ...[
          if (chips.isNotEmpty) ...[
            sec(chipsTitle),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final it in chips)
                big(it, sel.contains(it), () {
                  setState(() {
                    if (!sel.remove(it)) sel.add(it);
                  });
                }),
            ]),
          ],
          AppField('تفاصيل (اختياري)', controller: note, hint: noteHint, lines: 2),
        ],
      ]);

  Widget photoBody() => Column(children: [
        Center(
          child: Tap(
            onTap: () async {
              await photoSheet(context);
              if (mounted) setState(() {});
            },
            child: Stack(clipBehavior: Clip.none, children: [
              const UserAvatar(size: 150),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(width: 46, height: 46, decoration: BoxDecoration(color: kRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22)),
              ),
            ]),
          ),
        ),
        gap(14),
        Text('اضغط على الدائرة لاختيار صورتك', style: t(13, w: FontWeight.w500, c: kGrey)),
      ]);

  Widget get content => switch (s.id) {
        'photo' => photoBody(),
        'chronic' => chipsBody(kChronic, 'لا يوجد عندي مرض مزمن', 'مرض آخر', 'اكتب اسم المرض'),
        'meds' => medsBody(),
        'allergy' => chipsBody(kAllergies, 'لا توجد عندي حساسية', 'حساسية أخرى', 'اكتب ما تتحسس منه'),
        'surgery' => yesNoBody(chipsTitle: 'نوع العملية', chips: kSurgeries, noteHint: 'متى؟ (مثال: قبل 3 سنوات)'),
        'blood' => yesNoBody(noteHint: 'متى؟ ولأي سبب؟'),
        _ => yesNoBody(noteHint: 'لأي سبب؟ ومتى؟'),
      };

  Widget progress() => Row(children: [
        for (var i = 0; i < kHSteps.length; i++) Expanded(child: Container(height: 5, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: i <= widget.step ? kRed : kLine, borderRadius: BorderRadius.circular(3)))),
      ]);

  @override
  Widget build(BuildContext context) {
    final last = widget.step == kHSteps.length - 1;
    return RedPage(
      title: widget.mode == 2 ? 'تعديل' : 'ملفك الصحي',
      back: widget.mode != 0,
      action: widget.mode == 2 ? null : Tap(onTap: later, child: Text('لاحقاً', style: t(13.5, c: Colors.white))),
      bottomBar: btnBar(context, widget.mode == 2 ? 'حفظ' : (last ? 'إنهاء' : 'التالي'), () {
        commit();
        next();
      }, alt: widget.mode == 2 ? null : 'تخطي', onAlt: next),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), children: [
        if (widget.mode != 2) progress(),
        gap(16),
        Center(child: gTile(s.icon, size: 72, color: s.color)),
        gap(14),
        Center(child: Text(s.title, textAlign: TextAlign.center, style: t(22))),
        if (s.hint.isNotEmpty) ...[gap(6), Center(child: Text(s.hint, textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: kGrey, h: 1.6)))],
        gap(18),
        content,
      ]),
    );
  }
}

/// ملفي الصحي: ملخص كل البنود مع إضافة/تعديل أي بند في أي وقت.
class HealthProfileScreen extends StatelessWidget {
  const HealthProfileScreen({super.key});

  String sum(String id) {
    final h = app.health;
    if (id == 'photo') return app.photo != null ? 'صورة شخصية' : (app.avatar != 0 ? 'صورة رمزية' : 'لم تُضف بعد');
    if (!h.answered.contains(id)) return 'لم تُسجَّل بعد';
    switch (id) {
      case 'chronic':
        return h.chronicAll.isEmpty ? 'لا يوجد' : h.chronicAll.join('، ');
      case 'meds':
        return h.meds.isEmpty ? 'لا أستخدم أدوية' : h.meds.join('، ');
      case 'allergy':
        return h.allergyAll.isEmpty ? 'لا توجد' : h.allergyAll.join('، ');
      case 'surgery':
        return h.surgery == true ? (h.surgeryAll.isEmpty ? 'نعم' : h.surgeryAll.join('، ')) : 'لا';
      case 'blood':
        return h.yn(h.transfusion, h.transfusionNote);
      default:
        return h.yn(h.admission, h.admissionNote);
    }
  }

  Widget row(BuildContext c, int i) {
    final st = kHSteps[i];
    final done = st.id == 'photo' ? (app.photo != null || app.avatar != 0) : app.health.answered.contains(st.id);
    return InkWell(
      onTap: () => st.id == 'photo' ? photoSheet(c) : go(c, HealthSetupScreen(i, mode: 2)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          st.id == 'photo' ? const UserAvatar(size: 40) : tileIcon(st.icon, size: 40, color: st.color, bg: st.color.withAlpha(30)),
          gapW(12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kHLabels[st.id] ?? '', style: t(14)),
              const SizedBox(height: 2),
              Text(sum(st.id), maxLines: 2, overflow: TextOverflow.ellipsis, style: t(12, w: FontWeight.w500, c: done ? kSub : kGrey, h: 1.4)),
            ]),
          ),
          gapW(8),
          pill(done ? 'تعديل' : 'إضافة', done ? kChip : kTint, done ? kInk : kRed),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          final h = app.health;
          final nx = h.nextStep;
          return RedPage(
            title: 'ملفي الصحي',
            bottomBar: nx < 0 ? null : btnBar(c, 'أكمل ملفي الصحي', () => go(c, HealthSetupScreen(nx, mode: 1))),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              panel([
                Row(children: [
                  tileIcon(Icons.health_and_safety_rounded, size: 46),
                  gapW(12),
                  Expanded(child: two('أكملت ${h.done} من ${HealthProfile.steps.length}', h.complete ? 'ملفك مكتمل، شكراً لك' : 'كلما اكتمل ملفك ساعد طبيبك أكثر')),
                ]),
                gap(12),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: h.done / HealthProfile.steps.length, minHeight: 8, backgroundColor: kLine, color: kRed)),
              ]),
              group([
                for (var i = 0; i < kHSteps.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: kLine),
                  row(c, i),
                ],
              ]),
              gap(12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kBlueBg, borderRadius: BorderRadius.circular(16)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lock_rounded, color: kBlue, size: 20),
                  gapW(10),
                  Expanded(child: Text('هذه المعلومات سرّية، ولا يراها الطبيب إلا إذا وافقت على مشاركتها عند الحجز.', style: t(12, w: FontWeight.w500, c: kSub, h: 1.6))),
                ]),
              ),
            ]),
          );
        },
      );
}

// ───────────────────────── 4. Home ─────────────────────────
class FavBtn extends StatelessWidget {
  const FavBtn(this.d, {super.key, this.onGradient = false});
  final Doctor d;
  final bool onGradient;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          final on = app.isFav(d);
          return Tap(
            onTap: () {
              app.toggleFav(d);
              snack(c, on ? 'تمت الإزالة من المفضلة' : 'تمت الإضافة إلى المفضلة', ok: !on);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: onGradient ? Colors.white : (on ? kTint : kChip), shape: BoxShape.circle),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded, key: ValueKey(on), color: on || onGradient ? kRed : kGrey, size: 22),
              ),
            ),
          );
        },
      );
}

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});
  @override
  State<PromoCarousel> createState() => _PromoState();
}

class _PromoState extends State<PromoCarousel> {
  final pc = PageController(viewportFraction: .9);
  int i = 0;
  Timer? timer;
  static const slides = [
    ('خصم 20% على أول كشف', 'استخدم الكود TABIBAK20 عند الدفع', 'اكتشف العروض', [Color(0xFFF2434D), Color(0xFFC40F1A)], Icons.local_offer_rounded, 0),
    ('تحاليل منزلية بدون عناء', 'فني مختبر يسحب العينة من بيتك', 'اطلب تحليلاً', [Color(0xFF14B8A6), Color(0xFF0B7A6E)], Icons.science_rounded, 1),
    ('إسعاف على مدار الساعة', 'اطلب الآن وتابع وصوله مباشرة', 'اطلب إسعاف', [Color(0xFFFF9A3D), Color(0xFFE0610A)], Icons.emergency_rounded, 2),
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !pc.hasClients) return;
      pc.animateToPage((i + 1) % slides.length, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pc.dispose();
    super.dispose();
  }

  Widget open(int k) => k == 0 ? const OffersScreen() : (k == 1 ? const LabScreen() : const AmbulanceScreen());

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
          height: 142,
          child: PageView.builder(
            controller: pc,
            itemCount: slides.length,
            onPageChanged: (v) => setState(() => i = v),
            itemBuilder: (_, k) {
              final s = slides[k];
              return Tap(
                onTap: () => go(context, open(s.$6)),
                scale: .98,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: s.$4), borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: s.$4.last.withAlpha(60), blurRadius: 18, offset: const Offset(0, 8))]),
                  child: Stack(children: [
                    Positioned(left: -30, bottom: -40, child: ring(150, const Color(0x1FFFFFFF))),
                    Positioned(left: 24, top: 18, child: Icon(s.$5, color: const Color(0x38FFFFFF), size: 70)),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(s.$1, style: t(17, c: Colors.white)),
                        const SizedBox(height: 3),
                        Text(s.$2, style: t(12, w: FontWeight.w500, c: const Color(0xE6FFFFFF))),
                        const SizedBox(height: 12),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Text(s.$3, style: t(12.5, c: s.$4.last))),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var k = 0; k < slides.length; k++)
            AnimatedContainer(duration: const Duration(milliseconds: 220), margin: const EdgeInsets.all(2.5), width: k == i ? 20 : 6, height: 6, decoration: BoxDecoration(color: k == i ? kRed : const Color(0xFFD5DAE2), borderRadius: BorderRadius.circular(3))),
        ]),
      ]);
}

class MiniDoctor extends StatelessWidget {
  const MiniDoctor(this.d, {super.key});
  final Doctor d;
  @override
  Widget build(BuildContext context) => Tap(
        onTap: () => go(context, DoctorProfileScreen(d)),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          decoration: cardBox(22),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: kGradeColors[d.grade], width: 2)), child: Pic(d.img, size: 64, radius: 20, label: d.name)),
            gap(8),
            Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(13.5)),
            Text('${d.gradeLabel} · ${d.spec}', maxLines: 1, overflow: TextOverflow.ellipsis, style: t(11, w: FontWeight.w500, c: kGrey)),
            gap(8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star_rounded, color: kGold, size: 16),
              const SizedBox(width: 3),
              Text(d.rating, style: t(12, c: kSub)),
              const SizedBox(width: 8),
              Text('${d.price} ج.س', style: t(11.5, c: kRed)),
            ]),
          ]),
        ),
      );
}

class ClinicTile extends StatelessWidget {
  const ClinicTile(this.cl, {super.key});
  final Clinic cl;
  @override
  Widget build(BuildContext context) => Tap(
        onTap: () => go(context, ClinicScreen(cl)),
        scale: .98,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: cardBox(20),
          child: Row(children: [
            tileIcon(Icons.local_hospital_rounded, size: 48, color: kBlue, bg: kBlueBg),
            gapW(12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cl.name, style: t(14.5)),
                const SizedBox(height: 2),
                Row(children: [const Icon(Icons.location_on_rounded, size: 14, color: kGrey), const SizedBox(width: 3), Text(cl.place, style: t(11.5, w: FontWeight.w500, c: kGrey))]),
              ]),
            ),
            if (!cl.registered) ...[pill('غير مسجّل', kChip, kGrey), gapW(8)],
            const Icon(Icons.star_rounded, color: kGold, size: 18),
            const SizedBox(width: 3),
            Text(cl.rating, style: t(12.5, c: kSub)),
            gapW(6),
            chev(kGrey, 20),
          ]),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget service(BuildContext c, IconData icon, Color col, Color bg, String title, String sub, Widget to) => Tap(
        onTap: () => go(c, to),
        child: Container(
          padding: const EdgeInsets.all(14),
          clipBehavior: Clip.antiAlias,
          decoration: cardBox(24),
          child: Stack(children: [
            Positioned(top: -40, left: -40, child: ring(110, bg)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              gTile(icon, size: 52, color: col),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t(16)),
                const SizedBox(height: 2),
                Text(sub, maxLines: 2, style: t(11.5, w: FontWeight.w500, c: kGrey, h: 1.4)),
              ]),
            ]),
          ]),
        ),
      );

  Widget header(BuildContext c) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(36))),
        child: Stack(children: [
          Positioned(top: -70, left: -50, child: ring(210, const Color(0x14FFFFFF))),
          Positioned(bottom: -40, right: -30, child: ring(140, const Color(0x0FFFFFFF))),
          Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(c).padding.top + 12, 20, 20),
            child: Column(children: [
              Row(children: [
                Tap(
                  onTap: () => go(c, const ProfileScreen()),
                  child: const UserAvatar(size: 46, light: true),
                ),
                gapW(12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('مرحباً بك', style: t(12.5, w: FontWeight.w500, c: const Color(0xE6FFFFFF))),
                    Text(app.first, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(20, c: Colors.white)),
                  ]),
                ),
                Stack(clipBehavior: Clip.none, children: [
                  glass(const Icon(Icons.notifications_rounded, color: Colors.white, size: 24), () => go(c, const NotificationsScreen())),
                  if (app.unread > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: kGold, shape: BoxShape.circle, border: Border.all(color: kRed, width: 2)),
                        child: Text('${app.unread}', style: t(9, c: kInk)),
                      ),
                    ),
                ]),
              ]),
              gap(18),
              AppSearch('ابحث عن طبيب، مركز، أو خدمة...', readOnly: true, fill: Colors.white, onTap: () => go(c, const SearchScreen())),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) => Scaffold(
          backgroundColor: kBg,
          body: Column(children: [
            header(c),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 20), children: [
                const PromoCarousel(),
                secRow('خدماتنا'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.08,
                  children: [
                    service(c, Icons.medical_services_rounded, kRed, kTint, 'حجز طبيب', 'احجز موعدك مع أفضل الأطباء', const DoctorListScreen()),
                    service(c, Icons.bed_rounded, kBlue, kBlueBg, 'حجز سرير', 'ICU - HDU - CCU وغيرها', const BedScreen()),
                    service(c, Icons.emergency_rounded, kOrange, kOrangeBg, 'إسعاف', 'طلب إسعاف سريع', const AmbulanceScreen()),
                    service(c, Icons.home_rounded, kTeal, kTealBg, 'خدمة منزلية', 'طبيب - ممرض - معمل', const HomeCentersScreen()),
                  ],
                ),
                secRow('أطباء مميزون', more: 'عرض الكل', onMore: () => go(c, const DoctorListScreen())),
                SizedBox(
                  height: 176,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: doctors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => MiniDoctor(doctors[i]),
                  ),
                ),
                secRow('مراكز طبية قريبة'),
                for (final cl in kClinics.take(2)) ClinicTile(cl),
              ]),
            ),
            const AppNav(),
          ]),
        ),
      );
}

// ───────────────────────── 5. Global search ─────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchState();
}

class _SearchState extends State<SearchScreen> {
  final ctl = TextEditingController();
  String q = '';
  static const services = [
    (Icons.medical_services_rounded, 'حجز طبيب', 'احجز موعدك مع أفضل الأطباء', 0, kRed, kTint),
    (Icons.bed_rounded, 'حجز سرير', 'ICU - HDU - CCU', 1, kBlue, kBlueBg),
    (Icons.emergency_rounded, 'إسعاف', 'طلب إسعاف سريع', 2, kOrange, kOrangeBg),
    (Icons.home_rounded, 'خدمة منزلية', 'طبيب - ممرض - معمل', 3, kTeal, kTealBg),
    (Icons.science_rounded, 'تحاليل منزلية', 'سحب عينات من المنزل', 4, kTeal, kTealBg),
  ];
  static const popular = ['باطنية', 'أطفال', 'قلب', 'تحاليل', 'إسعاف', 'سرير'];

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  Widget screenFor(int k) => switch (k) {
        0 => const DoctorListScreen(),
        1 => const BedScreen(),
        2 => const AmbulanceScreen(),
        3 => const HomeCentersScreen(),
        _ => const LabScreen(),
      };

  void use(String s) {
    ctl.text = s;
    ctl.selection = TextSelection.collapsed(offset: s.length);
    setState(() => q = s);
  }

  @override
  Widget build(BuildContext context) {
    final ds = q.isEmpty ? <Doctor>[] : doctors.where((d) => d.name.contains(q) || d.spec.contains(q) || d.sub.contains(q) || d.places.contains(q)).toList();
    final cs = q.isEmpty ? <Clinic>[] : kClinics.where((c) => c.name.contains(q) || c.place.contains(q)).toList();
    final ss = q.isEmpty ? <int>[] : [for (var i = 0; i < services.length; i++) if (services[i].$2.contains(q) || services[i].$3.contains(q)) i];
    final none = q.isNotEmpty && ds.isEmpty && cs.isEmpty && ss.isEmpty;
    return RedPage(
      title: 'بحث',
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 6), child: AppSearch('ابحث عن طبيب، مركز، أو خدمة...', controller: ctl, autofocus: true, fill: Colors.white, onChanged: (v) => setState(() => q = v.trim()))),
        Expanded(
          child: none
              ? EmptyState(Icons.search_off_rounded, 'لا توجد نتائج', 'جرّب كلمات أخرى مثل اسم التخصص أو المنطقة.')
              : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
                  if (q.isEmpty) ...[
                    sec('عمليات بحث شائعة'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final p in popular)
                        Tap(
                          onTap: () => use(p),
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.trending_up_rounded, size: 16, color: kRed), const SizedBox(width: 6), Text(p, style: t(13, w: FontWeight.w600, c: kSub))])),
                        ),
                    ]),
                    sec('الخدمات'),
                  ],
                  if (q.isEmpty || ss.isNotEmpty) ...[
                    if (q.isNotEmpty) sec('الخدمات'),
                    for (final i in (q.isEmpty ? [for (var k = 0; k < services.length; k++) k] : ss))
                      Tap(
                        onTap: () => go(context, screenFor(services[i].$4)),
                        scale: .98,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: cardBox(18),
                          child: Row(children: [tileIcon(services[i].$1, size: 44, color: services[i].$5, bg: services[i].$6), gapW(12), Expanded(child: two(services[i].$2, services[i].$3)), chev(kGrey, 20)]),
                        ),
                      ),
                  ],
                  if (ds.isNotEmpty) ...[sec('الأطباء'), for (final d in ds) Padding(padding: const EdgeInsets.only(bottom: 12), child: DoctorCard(d))],
                  if (cs.isNotEmpty) ...[sec('المراكز'), for (final c in cs) ClinicTile(c)],
                ]),
        ),
      ]),
    );
  }
}

// ───────────────────────── 6. Doctors list / filter ─────────────────────────
/// علامة الدرجة العلمية (استشاري/أخصائي/مسجّل) بلونها المميّز.
Widget gradeBadge(Doctor d, {bool small = false}) => Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(color: kGradeBgs[d.grade], borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(kGradeIcons[d.grade], size: small ? 12 : 14, color: kGradeColors[d.grade]),
        const SizedBox(width: 4),
        Text(d.gradeLabel, style: t(small ? 10.5 : 11.5, c: kGradeColors[d.grade])),
      ]),
    );

class DoctorCard extends StatelessWidget {
  const DoctorCard(this.d, {super.key});
  final Doctor d;
  @override
  Widget build(BuildContext context) => Tap(
        onTap: () => go(context, DoctorProfileScreen(d)),
        scale: .98,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: cardBox(),
          child: Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), border: Border.all(color: kGradeColors[d.grade], width: 2.5)),
                child: Pic(d.img, size: 73, radius: 22, label: d.name),
              ),
              gapW(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.name, style: t(15.5)),
                  Text(d.sub.isEmpty ? d.spec : '${d.spec} · ${d.sub}', maxLines: 1, overflow: TextOverflow.ellipsis, style: t(12.5, w: FontWeight.w500, c: kGrey)),
                  gap(5),
                  gradeBadge(d),
                  gap(5),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: kGold, size: 18),
                    const SizedBox(width: 3),
                    Text(d.rating, style: t(12.5, c: kSub)),
                    const SizedBox(width: 4),
                    Text('(${d.reviews})', style: t(11.5, w: FontWeight.w500, c: kGrey)),
                    const SizedBox(width: 10),
                    const Icon(Icons.work_outline_rounded, size: 14, color: kGrey),
                    const SizedBox(width: 3),
                    Text('${d.exp} سنوات', style: t(11.5, w: FontWeight.w500, c: kGrey)),
                  ]),
                ]),
              ),
              FavBtn(d),
            ]),
            gap(10),
            Container(height: 1, color: const Color(0xFFF1F3F7)),
            gap(10),
            Row(children: [
              Text('سعر الكشف', style: t(11.5, w: FontWeight.w500, c: kGrey)),
              gapW(8),
              Text('${d.price} ج.س', style: t(14.5)),
              const Spacer(),
              SizedBox(
                width: 116,
                child: d.canBook
                    ? RedButton('احجز', height: 38, onTap: () => go(context, ConfirmBookingScreen(d)))
                    : Container(height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: kChip, borderRadius: BorderRadius.circular(18)), child: Text('عرض المراكز', style: t(13.5, c: kGrey))),
              ),
            ]),
          ]),
        ),
      );
}

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});
  @override
  State<DoctorListScreen> createState() => _DoctorListState();
}

class _DoctorListState extends State<DoctorListScreen> {
  final ctl = TextEditingController();
  int chip = 0;
  DocFilter f = DocFilter();
  static const chipsList = ['الكل', ...kSpecs];

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  List<Doctor> get list => doctors.where((d) {
        final q = ctl.text.trim();
        if (q.isNotEmpty && !(d.name.contains(q) || d.spec.contains(q) || d.sub.contains(q) || d.places.contains(q))) return false;
        if (chip != 0 && d.spec != chipsList[chip]) return false;
        return f.ok(d);
      }).toList();

  Future<void> openFilter() async {
    final r = await go<DocFilter>(context, FilterScreen(f));
    if (r != null && mounted) setState(() => f = r);
  }

  void reset() => setState(() {
        ctl.clear();
        chip = 0;
        f = DocFilter();
      });

  @override
  Widget build(BuildContext context) {
    final l = list;
    return RedPage(
      title: 'حجز طبيب',
      nav: const AppNav(),
      action: Stack(clipBehavior: Clip.none, children: [
        glass(const Icon(Icons.tune_rounded, color: Colors.white, size: 22), openFilter),
        if (f.count > 0)
          Positioned(top: -2, right: -2, child: Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: kGold, shape: BoxShape.circle, border: Border.all(color: kRed, width: 2)), child: Text('${f.count}', style: t(9, c: kInk)))),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 12), child: AppSearch('ابحث عن طبيب، تخصص، حي أو مركز...', controller: ctl, fill: Colors.white, onChanged: (_) => setState(() {}))),
        FilterChips(chipsList, sel: chip, onChanged: (v) => setState(() => chip = v)),
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Row(children: [Text('${l.length} نتيجة', style: t(12.5, w: FontWeight.w600, c: kGrey))])),
        Expanded(
          child: l.isEmpty
              ? EmptyState(Icons.person_search_rounded, 'لا يوجد أطباء مطابقون', 'غيّر البحث أو الفلاتر وحاول مرة أخرى.', btn: 'مسح الفلاتر', onTap: reset)
              : ListView.separated(padding: const EdgeInsets.all(16), itemCount: l.length, separatorBuilder: (_, __) => const SizedBox(height: 14), itemBuilder: (_, i) => DoctorCard(l[i])),
        ),
      ]),
    );
  }
}

class FilterScreen extends StatefulWidget {
  const FilterScreen(this.initial, {super.key});
  final DocFilter initial;
  @override
  State<FilterScreen> createState() => _FilterState();
}

class _FilterState extends State<FilterScreen> {
  static const cities = ['الكل', ...kCities];
  static const ratings = ['الكل', '3 ★ فأكثر', '4 ★ فأكثر'];
  static const ratingVals = [0.0, 3.0, 4.0];
  static const genders = ['الكل', 'طبيب', 'طبيبة'];
  late Set<String> specs = {...widget.initial.specs};
  late Set<String> subs = {...widget.initial.subs};
  late Set<int> grades = {...widget.initial.grades};
  late Set<String> hoods = {...widget.initial.hoods};
  late bool only = widget.initial.onlyBookable;
  late int area = cities.indexOf(widget.initial.area).clamp(0, cities.length - 1).toInt();
  late int rating = ratingVals.indexOf(widget.initial.minRating).clamp(0, 2).toInt();
  late int gender = widget.initial.gender;
  late RangeValues price = RangeValues(widget.initial.min, widget.initial.max);
  int rev = 0;

  void reset() => setState(() {
        specs = {};
        subs = {};
        grades = {};
        hoods = {};
        only = false;
        area = 0;
        rating = 0;
        gender = 0;
        price = const RangeValues(0, 30000);
        rev++;
      });

  /// مجموعات شرائح (لكل تخصص تخصصاته الدقيقة، ولكل مدينة أحياؤها) تعدّل المجموعة [chosen] مباشرة.
  Widget groups(String prefix, Iterable<String> names, List<String> Function(String) itemsOf, Set<String> chosen) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final g in names) ...[
          Padding(padding: const EdgeInsets.only(top: 10, bottom: 8), child: Text(g, style: t(12.5, w: FontWeight.w700, c: kGrey))),
          ChipWrap(
            itemsOf(g),
            key: ValueKey('$prefix-$g-$rev'),
            multi: true,
            sel: {for (var i = 0; i < itemsOf(g).length; i++) if (chosen.contains(itemsOf(g)[i])) i},
            onChanged: (s) {
              final items = itemsOf(g);
              chosen.removeAll(items);
              chosen.addAll([for (final i in s) items[i]]);
            },
          ),
        ],
      ]);

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'تصفية النتائج',
        bottomBar: btnBar(context, 'تطبيق', () => Navigator.pop(context, DocFilter(specs: specs, subs: subs, grades: grades, area: area == 0 ? 'الكل' : kCities[area - 1], hoods: hoods, minRating: ratingVals[rating], gender: gender, min: price.start, max: price.end, onlyBookable: only)), alt: 'إعادة ضبط', onAlt: reset),
        body: ListView(key: ValueKey(rev), padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          sec('الدرجة العلمية'),
          ChipWrap(kGrades, sel: grades, multi: true, onChanged: (s) => grades = s),
          sec('التخصص'),
          ChipWrap(
            kSpecs,
            sel: {for (var i = 0; i < kSpecs.length; i++) if (specs.contains(kSpecs[i])) i},
            multi: true,
            onChanged: (s) => setState(() {
              specs = {for (final i in s) kSpecs[i]};
              final allowed = {for (final sp in (specs.isEmpty ? kSpecs : specs.toList())) ...(kSubs[sp] ?? const <String>[])};
              subs.removeWhere((x) => !allowed.contains(x));
            }),
          ),
          sec('التخصص الدقيق'),
          groups('sub', specs.isEmpty ? kSpecs : kSpecs.where(specs.contains), (g) => kSubs[g] ?? const <String>[], subs),
          sec('المدينة'),
          ChipWrap(
            cities,
            sel: {area},
            onChanged: (s) => setState(() {
              area = s.first;
              if (area != 0) hoods.removeWhere((x) => !(kAreas[kCities[area - 1]] ?? const <String>[]).contains(x));
            }),
          ),
          sec('الحي'),
          groups('hood', area == 0 ? kCities : [kCities[area - 1]], (g) => kAreas[g] ?? const <String>[], hoods),
          sec('سعر الكشف'),
          RangeSlider(values: price, min: 0, max: 30000, divisions: 30, activeColor: kRed, onChanged: (x) => setState(() => price = x)),
          Row(children: [Text('${money(price.start.round())} ج.س', style: t(12, c: kGrey)), const Spacer(), Text('${money(price.end.round())} ج.س', style: t(12, c: kGrey))]),
          sec('التقييم'),
          ChipWrap(ratings, sel: {rating}, onChanged: (s) => rating = s.first),
          sec('الطبيب'),
          ChipWrap(genders, sel: {gender}, onChanged: (s) => gender = s.first),
          gap(14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardBox(18),
            child: Row(children: [
              tileIcon(Icons.event_available_rounded, size: 40, color: kGreenDk, bg: kGreenBg),
              gapW(12),
              Expanded(child: Text('المتاح للحجز عبر التطبيق فقط', style: t(14))),
              Switch(value: only, onChanged: (v) => setState(() => only = v)),
            ]),
          ),
        ]),
      );
}

// ───────────────────────── 7. Doctor profile ─────────────────────────
class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen(this.d, {super.key});
  final Doctor d;

  Widget stat(IconData i, String label, String value) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: cardBox(18),
          child: Column(children: [
            Icon(i, color: kRed, size: 22),
            gap(6),
            Text(value, textAlign: TextAlign.center, style: t(12.5)),
            const SizedBox(height: 2),
            Text(label, style: t(10.5, w: FontWeight.w500, c: kGrey)),
          ]),
        ),
      );

  /// بطاقة مركز يعمل به الطبيب: خضراء + «احجز» إن كان المركز مسجّلاً عندنا وعضويته مفعّلة،
  /// ورمادية (رقم المركز وسعر الكشف فقط، بلا حجز) إن لم يكن.
  Widget workCard(BuildContext c, Work w) {
    final cl = w.clinic;
    final ok = w.bookable;
    const greyLine = Color(0xFFD9DCE3);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: ok ? kGreenBg : const Color(0xFFF2F3F6), borderRadius: BorderRadius.circular(20), border: Border.all(color: ok ? kGreen : greyLine, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Tap(
          onTap: () => go(c, ClinicScreen(cl)),
          child: Row(children: [
            tileIcon(Icons.local_hospital_rounded, size: 46, color: ok ? kGreenDk : kGrey, bg: ok ? Colors.white : const Color(0xFFE6E8EE)),
            gapW(12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cl.name, style: t(14.5, c: ok ? kInk : kSub)),
                Text(cl.place, style: t(11.5, w: FontWeight.w500, c: kGrey)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${money(w.fee)} ج.س', style: t(14.5, c: ok ? kGreenDk : kSub)),
              Text('سعر الكشف', style: t(10.5, w: FontWeight.w500, c: kGrey)),
            ]),
          ]),
        ),
        gap(8),
        Text('${w.daysText} · ${w.hours}', style: t(11.5, w: FontWeight.w600, c: kSub)),
        gap(10),
        if (ok)
          GreenButton('احجز', icon: Icons.event_available_rounded, onTap: () => go(c, ConfirmBookingScreen(d, work: w)))
        else ...[
          Row(children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: kGrey),
            gapW(6),
            Expanded(child: Text(w.why, style: t(11.5, w: FontWeight.w500, c: kGrey, h: 1.5))),
          ]),
          gap(10),
          Row(children: [
            Expanded(
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: greyLine)),
                child: Directionality(textDirection: TextDirection.ltr, child: Text(cl.phone, style: t(13.5, c: kSub))),
              ),
            ),
            gapW(10),
            SizedBox(
              width: 120,
              child: Tap(
                onTap: () => contactSheet(c, cl.name, cl.phone),
                child: Container(height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: kGrey, borderRadius: BorderRadius.circular(14)), child: Text('اتصال', style: t(14, c: Colors.white))),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget legendDot(Color c, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: t(11, w: FontWeight.w600, c: kGrey)),
      ]);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            SizedBox(
              height: 250,
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  height: 170,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(40))),
                  child: Stack(children: [
                    Positioned(top: -60, left: -40, child: ring(200, const Color(0x14FFFFFF))),
                    Positioned(bottom: -50, right: -30, child: ring(160, const Color(0x0FFFFFFF))),
                  ]),
                ),
                Positioned(top: top + 8, left: 12, child: glass(const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28, textDirection: TextDirection.ltr), () => Navigator.maybePop(context))),
                Positioned(top: top + 8, right: 12, child: FavBtn(d, onGradient: true)),
                Positioned(
                  top: 98,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(36), boxShadow: kShadow, border: Border.all(color: kGradeColors[d.grade], width: 3)),
                      child: Pic(d.img, size: 116, height: 128, radius: 32, label: d.name),
                    ),
                  ),
                ),
              ]),
            ),
            Center(child: Text(d.name, style: t(22))),
            gap(6),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [pill(d.spec, kTint, kRed), if (d.sub.isNotEmpty) pill(d.sub, kChip, kInk), gradeBadge(d)])),
            gap(10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star_rounded, color: kGold, size: 22),
              const SizedBox(width: 5),
              Text(d.rating, style: t(14.5, c: kSub)),
              const SizedBox(width: 8),
              Tap(onTap: () => go(context, ReviewsScreen(d)), child: Text('(${d.reviews} تقييم)', style: t(12.5, c: kRed))),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 18, 11, 0),
              child: Row(children: [
                stat(Icons.badge_outlined, 'رقم التسجيل', d.reg),
                stat(Icons.school_outlined, 'المؤهلات', d.quals.split(' - ').first.split(' + ').first),
                stat(Icons.workspace_premium_outlined, 'الخبرة', '${d.exp} سنوات'),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                sec('نبذة'),
                Text(d.about, style: t(13, w: FontWeight.w500, c: kSub, h: 1.8)),
                sec('المراكز التي يعمل بها'),
                Row(children: [legendDot(kGreen, 'متاح للحجز عبر طبيبك'), gapW(14), legendDot(kGrey, 'غير مسجّل — للاتصال فقط')]),
                gap(10),
                for (final w in d.works) workCard(context, w),
                Tap(
                  onTap: () => go(context, ReviewsScreen(d)),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: cardBox(18),
                    child: Row(children: [tileIcon(Icons.reviews_rounded, size: 40, color: kGold, bg: kAmberBg), gapW(12), Expanded(child: Text('آراء المرضى والتقييمات', style: t(14))), chev(kGrey, 20)]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))]),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('سعر الكشف', style: t(11.5, w: FontWeight.w500, c: kGrey)), Text('${d.price} ج.س', style: t(18))]),
            gapW(18),
            Expanded(child: RedButton(d.canBook ? 'احجز موعد' : 'الحجز غير متاح عبر التطبيق', arrow: d.canBook, enabled: d.canBook, onTap: () => go(context, ConfirmBookingScreen(d)))),
          ]),
        ),
      ]),
    );
  }
}

// ───────────────────────── 8. Clinic details ─────────────────────────
class ClinicScreen extends StatelessWidget {
  const ClinicScreen(this.cl, {super.key});
  final Clinic cl;
  @override
  Widget build(BuildContext context) => RedPage(
        title: cl.name,
        bottomBar: btnBar(context, 'اتصال بالمركز', () => contactSheet(context, cl.name, cl.phone), icon: Icons.phone_rounded),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (!cl.registered)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF2F3F6), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD9DCE3))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded, color: kGrey, size: 20),
                gapW(10),
                Expanded(child: Text('هذا المركز غير مسجّل في طبيبك، فلا يمكن الحجز عن طريقنا. يمكنك الاتصال به مباشرة.', style: t(12, w: FontWeight.w600, c: kSub, h: 1.6))),
              ]),
            ),
          panel([
            Row(children: [
              gTile(Icons.local_hospital_rounded, size: 56, color: kBlue),
              gapW(12),
              Expanded(child: two(cl.name, cl.place)),
              const Icon(Icons.star_rounded, color: kGold, size: 20),
              const SizedBox(width: 3),
              Text(cl.rating, style: t(13.5, c: kSub)),
            ]),
            gap(12),
            Text(cl.about, style: t(12.5, w: FontWeight.w500, c: kSub, h: 1.7)),
            const Divider(color: kLine, height: 26),
            kv('أيام الدوام', cl.days),
            kv('ساعات العمل', cl.hours),
            kv('الهاتف', cl.phone),
          ]),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 150,
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: const MapPainter(false))),
                const Center(child: Icon(Icons.location_on_rounded, color: kRed, size: 44)),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Tap(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '${cl.name} - ${cl.place}'));
                      snack(context, 'تم نسخ العنوان', ok: true);
                    },
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: kShadow), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.content_copy_rounded, size: 15, color: kRed), const SizedBox(width: 6), Text('نسخ العنوان', style: t(12, c: kRed))])),
                  ),
                ),
              ]),
            ),
          ),
          secRow('أطباء المركز'),
          for (final d in doctors.where((x) => x.works.any((w) => w.centerId == cl.id))) Padding(padding: const EdgeInsets.only(bottom: 12), child: DoctorCard(d)),
        ]),
      );
}

// ───────────────────────── 9. Confirm booking / payment / success ─────────────────────────
/// الشكاوى الشائعة (اضغط لاختيارها) — تصل إلى الطبيب في تطبيقه ضمن «سبب الزيارة».
const kComplaints = ['صداع', 'حمى / سخانة', 'كحة', 'ألم في البطن', 'ألم في الصدر', 'ارتفاع الضغط', 'السكري', 'ألم المفاصل أو الظهر', 'إسهال أو قيء', 'دوخة', 'طفح أو حكة جلدية', 'متابعة / كشف دوري'];

class ConfirmBookingScreen extends StatefulWidget {
  const ConfirmBookingScreen(this.d, {super.key, this.work});
  final Doctor d;
  final Work? work; // المركز المختار مسبقاً (من بطاقته الخضراء في صفحة الطبيب)
  @override
  State<ConfirmBookingScreen> createState() => _ConfirmState();
}

class _ConfirmState extends State<ConfirmBookingScreen> {
  late final List<Work> opts = widget.d.open; // المراكز المسجّلة المفعّلة فقط
  late int clinic = widget.work == null || opts.indexOf(widget.work!) < 0 ? 0 : opts.indexOf(widget.work!);
  int who = 0;
  late (String, String) slot = SchedulePicker.initial(opts.isEmpty ? null : opts[clinic]);
  final Set<int> cSel = {};
  final text = TextEditingController();
  bool share = true;
  String? err;

  @override
  void initState() {
    super.initState();
    gate(context);
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Work get w => opts[clinic];

  String get complaint => [for (final i in (cSel.toList()..sort())) kComplaints[i], if (text.text.trim().isNotEmpty) text.text.trim()].join('، ');

  void next() {
    if (complaint.isEmpty) {
      setState(() => err = 'اختر ما تشتكي منه أو اكتبه');
      return;
    }
    go(context, PaymentScreen(widget.d, clinic: w.clinic, work: w, price: w.fee, slot: slot, who: app.people[who], complaint: complaint, share: share && who == 0 && app.health.any));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    if (opts.isEmpty) {
      return RedPage(title: 'تأكيد الحجز', body: EmptyState(Icons.event_busy_rounded, 'لا يتوفر حجز عبر التطبيق', 'مراكز هذا الطبيب غير مسجّلة في طبيبك. يمكنك الاتصال بالمركز مباشرة من صفحة الطبيب.'));
    }
    return RedPage(
      title: 'تأكيد الحجز',
      bottomBar: btnBar(
        context,
        'متابعة إلى الدفع',
        next,
        lead: Row(children: [
          Text('${slot.$1} · ${slot.$2}', style: t(12.5, w: FontWeight.w600, c: kSub)),
          const Spacer(),
          Text('${money(w.fee)} ج.س', style: t(16, c: kRed)),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), children: [
        panel([Row(children: [Pic(d.img, size: 64, radius: 20, label: d.name), gapW(12), Expanded(child: two(d.name, d.sub.isEmpty ? d.spec : '${d.spec} · ${d.sub}'))])]),
        sec('المركز'),
        RadioPick(
          [for (final o in opts) (o.clinic.name, '${o.clinic.place} · ${o.daysText} · ${o.hours} · ${money(o.fee)} ج.س')],
          sel: clinic,
          onChanged: (v) => setState(() {
            clinic = v;
            slot = SchedulePicker.initial(opts[v]);
          }),
        ),
        sec('بتشتكي من شنو؟'),
        Text('اختر أو اكتب، وسيطّلع الدكتور على شكواك قبل موعدك.', style: t(12.5, w: FontWeight.w500, c: kGrey)),
        gap(10),
        ChipWrap(
          kComplaints,
          multi: true,
          sel: const <int>{},
          onChanged: (s) => setState(() {
            cSel
              ..clear()
              ..addAll(s);
            err = null;
          }),
        ),
        AppField('أو اكتب شكواك', controller: text, hint: 'مثال: صداع ودوخة منذ 3 أيام', lines: 2, error: err, onChanged: (_) {
          if (err != null) setState(() => err = null);
        }),
        sec('الحجز لـ'),
        ChipWrap(app.people, onChanged: (s) => setState(() => who = s.first)),
        SchedulePicker(key: ValueKey('sch$clinic'), work: w, onChanged: (s) => setState(() => slot = s)),
        if (who == 0 && app.health.any) ...[
          gap(12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardBox(18),
            child: Row(children: [
              tileIcon(Icons.health_and_safety_rounded, size: 40),
              gapW(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('مشاركة ملفي الصحي مع الطبيب', style: t(14)),
                  Text('الأمراض المزمنة والأدوية والحساسية والعمليات', style: t(11.5, w: FontWeight.w500, c: kGrey)),
                ]),
              ),
              Switch(value: share, onChanged: (v) => setState(() => share = v)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen(this.d, {super.key, required this.clinic, required this.work, required this.price, required this.slot, required this.who, required this.complaint, this.share = false});
  final Doctor d;
  final Clinic clinic;
  final Work work;
  final int price;
  final (String, String) slot;
  final String who, complaint;
  final bool share; // مشاركة الملف الصحي مع الطبيب
  @override
  State<PaymentScreen> createState() => _PaymentState();
}

class _PaymentState extends State<PaymentScreen> {
  static const methods = [('تطبيق بنكك', 'تحويل مباشر من حسابك'), ('أوكاش', 'الدفع بالمحفظة الإلكترونية'), ('فوري', 'الدفع عبر نقاط الخدمة'), ('الدفع في المركز', 'ادفع عند الوصول')];
  static const fee = 500;
  final promo = TextEditingController();
  int method = 0, pct = 0;
  bool busy = false;

  int get disc => (widget.price * pct / 100).round();
  int get total => widget.price + fee - disc;

  @override
  void dispose() {
    promo.dispose();
    super.dispose();
  }

  void apply() {
    final p = kPromos[promo.text.trim().toUpperCase()];
    if (p == null) {
      setState(() => pct = 0);
      snack(context, 'كود الخصم غير صالح');
    } else {
      setState(() => pct = p);
      snack(context, 'تم تطبيق خصم $p%', ok: true);
    }
  }

  void pay() {
    setState(() => busy = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final w = widget;
      final a = app.add(
        Appt(app.newId(), 0, w.d.name, '${w.d.spec} · ${w.clinic.name}', w.slot.$1, w.slot.$2, status: 'قيد التأكيد', price: total, place: w.clinic.name, centerId: w.clinic.id, phone: app.phone, who: w.who, method: methods[method].$1, doctor: w.d, complaint: w.complaint, sharedHealth: w.share),
        Notif(Icons.event_available_rounded, 'تم إرسال طلب الحجز', 'بانتظار تأكيد ${w.clinic.name} لموعدك مع ${w.d.name}', 'الآن', unread: true, dest: 1),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuccessScreen(a)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return RedPage(
      title: 'الدفع',
      bottomBar: btnBar(context, 'ادفع ${money(total)} ج.س', pay, loading: busy),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), children: [
        panel([
          Row(children: [Pic(d.img, size: 54, radius: 18, label: d.name), gapW(12), Expanded(child: two(d.name, '${widget.clinic.name} · ${widget.slot.$1}'))]),
          const Divider(color: kLine, height: 24),
          kv('الشكوى', widget.complaint),
          kv('رسوم الكشف', '${money(widget.price)} ج.س'),
          kv('رسوم الخدمة', '$fee ج.س'),
          if (pct > 0) kv('خصم $pct%', '- ${money(disc)} ج.س'),
          kv('الإجمالي', '${money(total)} ج.س', bold: true),
        ]),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: AppField('كود الخصم', controller: promo, hint: 'مثال: TABIBAK20', icon: Icons.local_offer_outlined, ltr: true)),
          gapW(10),
          Padding(padding: const EdgeInsets.only(bottom: 1), child: SizedBox(width: 92, child: RedButton('تطبيق', height: 50, onTap: apply))),
        ]),
        sec('اختر طريقة الدفع'),
        RadioPick(methods, onChanged: (v) => setState(() => method = v)),
      ]),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen(this.a, {super.key});
  final Appt a;

  Widget row(IconData i, String s, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [Icon(i, color: kRed, size: 21), gapW(12), Expanded(child: Text(s, style: t(14, w: bold ? FontWeight.w800 : FontWeight.w600, c: const Color(0xFF3B4A68))))]),
      );

  @override
  Widget build(BuildContext context) {
    const bits = [
      (-74.0, -70.0, Color(0xFF2EAD5C), .8),
      (74.0, -64.0, Color(0xFF2EAD5C), -.7),
      (92.0, -4.0, Color(0xFFE8559A), -.2),
      (-92.0, -12.0, Color(0xFFF5A623), .1),
      (-74.0, 50.0, Color(0xFFE8559A), -.6),
      (76.0, 56.0, Color(0xFF2EAD5C), .8),
    ];
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(children: [
            const SizedBox(height: 36),
            SizedBox(
              width: 230,
              height: 170,
              child: Stack(alignment: Alignment.center, children: [
                for (final b in bits) Transform.translate(offset: Offset(b.$1, b.$2), child: Transform.rotate(angle: b.$4, child: Container(width: 12, height: 6, decoration: BoxDecoration(color: b.$3, borderRadius: BorderRadius.circular(1.5))))),
                Container(
                  width: 104,
                  height: 104,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3DBB6B), Color(0xFF1F9A4C)]), boxShadow: [BoxShadow(color: Color(0x332EAD5C), blurRadius: 16, offset: Offset(0, 8))]),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 70),
                ),
              ]),
            ),
            Text('تم إرسال طلب الحجز بنجاح', style: t(21)),
            gap(10),
            Text('سيتم مراجعة طلبك من قبل المركز،\nوسيتم إشعارك بمجرد التأكيد.', textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: const Color(0xFF6B7794), h: 1.7)),
            gap(22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: cardBox(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Pic(a.doctor?.img ?? '', size: 56, radius: 18, label: a.title),
                  gapW(12),
                  Expanded(child: two(a.title, a.sub.split(' · ').first)),
                  pillWarn(a.status),
                ]),
                gap(8),
                row(Icons.location_on_outlined, a.place, bold: true),
                row(Icons.calendar_month_outlined, a.day),
                row(Icons.access_time_rounded, 'الساعة ${a.time}'),
                row(Icons.person_outline_rounded, 'الحجز لـ ${a.who.isEmpty ? app.name : a.who}'),
                if (a.complaint.isNotEmpty) row(Icons.edit_note_rounded, 'الشكوى: ${a.complaint}'),
                row(Icons.payments_outlined, '${money(a.price)} ج.س · ${a.method}', bold: true),
              ]),
            ),
            const Spacer(),
            RedButton('عرض الحجز', height: 50, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AppointmentDetailsScreen(a)))),
            gap(10),
            OutBtn('العودة إلى الرئيسية', onTap: () => home(context)),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── 10. Shared: done page / address card ─────────────────────────
/// Generic green "done" page used after booking / request / cancel.
class DoneScreen extends StatelessWidget {
  const DoneScreen(this.title, this.sub, this.rows, {super.key, this.btn = 'العودة إلى الرئيسية', this.to});
  final String title, sub, btn;
  final List<(String, String)> rows;
  final Widget? to;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(children: [
              const SizedBox(height: 56),
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3DBB6B), Color(0xFF1F9A4C)]), boxShadow: [BoxShadow(color: Color(0x332EAD5C), blurRadius: 16, offset: Offset(0, 8))]),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 70),
              ),
              gap(22),
              Text(title, textAlign: TextAlign.center, style: t(21)),
              gap(10),
              Text(sub, textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: const Color(0xFF6B7794), h: 1.7)),
              gap(24),
              panel([for (final r in rows) kv(r.$1, r.$2)]),
              const Spacer(),
              if (to != null) ...[
                RedButton(btn, height: 50, onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => to!), (r) => r.isFirst)),
                gap(10),
                OutBtn('العودة إلى الرئيسية', onTap: () => home(context)),
              ] else
                RedButton(btn, height: 50, onTap: () => home(context)),
            ]),
          ),
        ),
      );
}

void done(BuildContext c, DoneScreen s) => Navigator.pushReplacement(c, MaterialPageRoute(builder: (_) => s));

class AddressCard extends StatelessWidget {
  const AddressCard({super.key, this.title = 'عنوان الزيارة'});
  final String title;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) => panel([
          Row(children: [
            tileIcon(app.addr.icon, size: 46),
            gapW(12),
            Expanded(child: two(app.addr.line, app.addr.note.isEmpty ? app.addr.label : app.addr.note)),
            Tap(onTap: () => go(c, const AddressesScreen()), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(12)), child: Text('تغيير', style: t(12, c: kRed)))),
          ]),
        ]),
      );
}

// ───────────────────────── 11. Bed booking ─────────────────────────
class BedScreen extends StatefulWidget {
  const BedScreen({super.key});
  @override
  State<BedScreen> createState() => _BedState();
}

class _BedState extends State<BedScreen> {
  int chip = 0;
  static const types = ['الكل', 'CCU', 'HDU', 'ICU', 'عادية'];
  List<Hospital> get list => kHospitals.where((h) => chip == 0 || h.beds.any((b) => b.type == types[chip])).toList();

  Widget hospital(BuildContext c, Hospital h) {
    final minP = h.beds.map((b) => b.price).reduce((a, b) => a < b ? a : b);
    final free = h.beds.fold<int>(0, (a, b) => a + b.avail);
    return Tap(
      onTap: () => go(c, HospitalScreen(h)),
      scale: .98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: cardBox(24),
        child: Row(children: [
          Pic(h.img, size: 96, height: 112, radius: 18, icon: Icons.apartment_rounded),
          gapW(12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(h.name, style: t(15.5))), const Icon(Icons.star_rounded, color: kGold, size: 17), const SizedBox(width: 2), Text(h.rating, style: t(12, c: kSub))]),
              const SizedBox(height: 2),
              Row(children: [const Icon(Icons.location_on_rounded, color: kRed, size: 15), const SizedBox(width: 3), Text(h.place, style: t(11.5, w: FontWeight.w500, c: kGrey))]),
              gap(8),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final b in h.beds) pill(b.type, b.avail > 0 ? kGreenBg : kChip, b.avail > 0 ? kGreenDk : kGrey)]),
              gap(8),
              Row(children: [Text('من ${money(minP)} ج.س / يوم', style: t(13)), const Spacer(), Text(free > 0 ? '$free سرير متاح' : 'غير متاح', style: t(11.5, c: free > 0 ? kGreenDk : kRed))]),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = list;
    return RedPage(
      title: 'حجز سرير',
      nav: const AppNav(),
      body: Column(children: [
        gap(16),
        FilterChips(types, sel: chip, onChanged: (v) => setState(() => chip = v)),
        Expanded(
          child: l.isEmpty
              ? const EmptyState(Icons.bed_rounded, 'لا توجد مستشفيات', 'لا يوجد هذا النوع من الأسرّة حالياً.')
              : ListView(padding: const EdgeInsets.all(16), children: [for (final h in l) hospital(context, h)]),
        ),
      ]),
    );
  }
}

class HospitalScreen extends StatefulWidget {
  const HospitalScreen(this.h, {super.key});
  final Hospital h;
  @override
  State<HospitalScreen> createState() => _HospitalState();
}

class _HospitalState extends State<HospitalScreen> {
  late int sel = widget.h.beds.indexWhere((b) => b.avail > 0);

  @override
  Widget build(BuildContext context) {
    final h = widget.h;
    return RedPage(
      title: h.name,
      bottomBar: btnBar(context, sel < 0 ? 'لا توجد أسرّة متاحة' : 'احجز ${h.beds[sel].type}', () => go(context, BedFormScreen(h, h.beds[sel])), enabled: sel >= 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: Image.asset(
              h.img,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF5B8DEF), Color(0xFF2F5FD0)])),
                child: Stack(alignment: Alignment.center, children: [Positioned(top: -30, left: -20, child: ring(130, const Color(0x1FFFFFFF))), const Icon(Icons.local_hospital_rounded, size: 70, color: Colors.white)]),
              ),
            ),
          ),
        ),
        gap(14),
        Row(children: [Expanded(child: two(h.name, h.place)), const Icon(Icons.star_rounded, color: kGold, size: 22), const SizedBox(width: 4), Text(h.rating, style: t(14, c: kSub))]),
        sec('اختر نوع السرير'),
        for (var i = 0; i < h.beds.length; i++)
          Opacity(
            opacity: h.beds[i].avail > 0 ? 1 : .55,
            child: Tap(
              onTap: h.beds[i].avail > 0 ? () => setState(() => sel = i) : null,
              scale: .985,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: sel == i ? const Color(0xFFFFF5F6) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: sel == i ? kRed : kLine, width: 1.5)),
                child: Row(children: [
                  tileIcon(Icons.bed_rounded, color: kBlue, bg: kBlueBg),
                  gapW(12),
                  Expanded(child: two(h.beds[i].label, '${money(h.beds[i].price)} ج.س / يوم')),
                  h.beds[i].avail > 0 ? pillOk('${h.beds[i].avail} متاح') : pill('غير متاح', kTint, kRed),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class BedFormScreen extends StatefulWidget {
  const BedFormScreen(this.h, this.offer, {super.key});
  final Hospital h;
  final BedOffer offer;
  @override
  State<BedFormScreen> createState() => _BedFormState();
}

class _BedFormState extends State<BedFormScreen> {
  late final nm = TextEditingController(text: app.name);
  late final ph = TextEditingController(text: fmtPhone(app.phone));
  int days = 3;
  (String, String) slot = SchedulePicker.initial();
  String? eName, ePhone;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    gate(context);
  }

  @override
  void dispose() {
    nm.dispose();
    ph.dispose();
    super.dispose();
  }

  void submit() {
    setState(() {
      eName = nm.text.trim().length < 3 ? 'أدخل اسم المريض' : null;
      ePhone = normPhone(ph.text) == null ? 'أدخل رقم تواصل صحيح' : null;
    });
    if (eName != null || ePhone != null) return;
    setState(() => busy = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final w = widget;
      final total = w.offer.price * days;
      app.add(
        Appt(app.newId(), 1, w.h.name, '${w.offer.type} · $days أيام', slot.$1, '$days أيام', status: 'قيد التأكيد', price: total, place: w.h.place, centerId: w.h.id, phone: normPhone(ph.text) ?? app.phone, who: nm.text.trim(), method: 'الدفع في المستشفى'),
        Notif(Icons.bed_rounded, 'تم إرسال طلب حجز السرير', 'بانتظار مراجعة ${w.h.name} لطلبك', 'الآن', unread: true, dest: 1),
      );
      done(context, DoneScreen('تم إرسال طلب حجز السرير', 'ستتم مراجعة طلبك من المستشفى وإشعارك بالتأكيد.', [('المستشفى', w.h.name), ('نوع السرير', w.offer.type), ('تاريخ الدخول', slot.$1), ('مدة الإقامة', '$days أيام'), ('الإجمالي', '${money(total)} ج.س')], btn: 'عرض حجوزاتي', to: const AppointmentsScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    return RedPage(
      title: 'بيانات الحجز',
      bottomBar: btnBar(context, 'إرسال طلب الحجز', submit, loading: busy, lead: Row(children: [Text('${money(o.price)} × $days أيام', style: t(12.5, w: FontWeight.w600, c: kSub)), const Spacer(), Text('${money(o.price * days)} ج.س', style: t(16, c: kRed))])),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), children: [
        panel([Row(children: [tileIcon(Icons.bed_rounded, size: 46, color: kBlue, bg: kBlueBg), gapW(12), Expanded(child: two('${widget.h.name} · ${o.type}', '${money(o.price)} ج.س / يوم'))])]),
        AppField('اسم المريض', controller: nm, icon: Icons.person_outline_rounded, error: eName),
        AppField('رقم التواصل', controller: ph, icon: Icons.phone_outlined, type: TextInputType.phone, ltr: true, error: ePhone),
        sec('تاريخ الدخول'),
        SchedulePicker(showTime: false, onChanged: (s) => slot = s),
        sec('مدة الإقامة'),
        panel([
          Row(children: [
            Expanded(child: Text('عدد الأيام', style: t(14))),
            glass(const Icon(Icons.remove_rounded, color: kRed, size: 22), () => setState(() => days = days > 1 ? days - 1 : 1), bg: kTint),
            SizedBox(width: 54, child: Center(child: Text('$days', style: t(20)))),
            glass(const Icon(Icons.add_rounded, color: kRed, size: 22), () => setState(() => days = days < 30 ? days + 1 : 30), bg: kTint),
          ]),
        ]),
        Text('يتم تأكيد الحجز من المستشفى بعد المراجعة', textAlign: TextAlign.center, style: t(11.5, w: FontWeight.w500, c: kGrey)),
      ]),
    );
  }
}

// ───────────────────────── 12. Home services ─────────────────────────
class HomeCentersScreen extends StatefulWidget {
  const HomeCentersScreen({super.key});
  @override
  State<HomeCentersScreen> createState() => _HomeCentersState();
}

class _HomeCentersState extends State<HomeCentersScreen> {
  static const chips = ['الكل', 'الأقرب إليك', 'الخرطوم', 'بحري', 'أم درمان', 'شرق النيل'];
  static const nearKm = 5.0;
  final ctl = TextEditingController();
  int chip = 0;

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  List<HomeCenter> get list {
    final q = ctl.text.trim();
    final l = kHomeCenters.where((h) {
      if (q.isNotEmpty && !(h.name.contains(q) || h.place.contains(q) || h.area.contains(q))) return false;
      if (chip == 1) return h.km <= nearKm;
      if (chip >= 2) return h.area == chips[chip];
      return true;
    }).toList();
    if (chip == 1) l.sort((a, b) => a.km.compareTo(b.km));
    return l;
  }

  void pick(int v) {
    if (v == 1 && !app.locOn) {
      snack(context, 'فعّل خدمة الموقع من الإعدادات لعرض المراكز الأقرب إليك');
      return;
    }
    setState(() => chip = v);
  }

  void reset() => setState(() {
        ctl.clear();
        chip = 0;
      });

  Widget centerCard(BuildContext c, HomeCenter h) => Tap(
        onTap: () {
          app.homeCenter = h.id;
          go(c, HomeServicesScreen(center: h));
        },
        scale: .98,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: cardBox(24),
          child: Row(children: [
            gTile(Icons.local_hospital_rounded, size: 62, color: kTeal),
            gapW(12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(h.name, style: t(15.5))), const Icon(Icons.star_rounded, color: kGold, size: 17), const SizedBox(width: 2), Text(h.rating, style: t(12, c: kSub))]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: kRed, size: 15),
                  const SizedBox(width: 3),
                  Expanded(child: Text(h.place, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(11.5, w: FontWeight.w500, c: kGrey))),
                  const Icon(Icons.near_me_rounded, color: kTeal, size: 14),
                  const SizedBox(width: 3),
                  Text('${h.km.toStringAsFixed(1)} كم', style: t(11.5, c: kTeal)),
                ]),
                const SizedBox(height: 2),
                Row(children: [const Icon(Icons.schedule_rounded, color: kGrey, size: 15), const SizedBox(width: 3), Text(h.hours, style: t(11.5, w: FontWeight.w500, c: kGrey))]),
                gap(8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  if (h.doctor) pill('زيارة طبيب', kTint, kRed),
                  if (h.nurse) pill('تمريض', kBlueBg, kBlue),
                  if (h.lab) pill('معمل', kTealBg, kTeal),
                ]),
              ]),
            ),
            gapW(4),
            chev(kRed, 24),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = list;
    return RedPage(
      title: 'مراكز الخدمة المنزلية',
      nav: const AppNav(),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 12), child: AppSearch('ابحث عن مركز...', controller: ctl, fill: Colors.white, onChanged: (_) => setState(() {}))),
        FilterChips(chips, sel: chip, onChanged: pick),
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Row(children: [Text('${l.length} مركز', style: t(12.5, w: FontWeight.w600, c: kGrey))])),
        Expanded(
          child: l.isEmpty
              ? EmptyState(Icons.search_off_rounded, 'لا توجد مراكز مطابقة', 'غيّر البحث أو الفلتر وحاول مرة أخرى.', btn: 'مسح البحث', onTap: reset)
              : ListView(padding: const EdgeInsets.all(16), children: [for (final h in l) centerCard(context, h)]),
        ),
      ]),
    );
  }
}

class HomeServicesScreen extends StatelessWidget {
  const HomeServicesScreen({super.key, this.center});

  /// عند تحديده تُعرض الخدمات المتوفرة في هذا المركز فقط؛ وإن كان null تظهر كل الخدمات كما كانت.
  final HomeCenter? center;

  Widget centerHeader(HomeCenter h) => Container(
        padding: const EdgeInsets.all(14),
        decoration: cardBox(24),
        child: Row(children: [
          gTile(Icons.local_hospital_rounded, size: 54, color: kTeal),
          gapW(12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(h.name, style: t(15.5))), const Icon(Icons.star_rounded, color: kGold, size: 17), const SizedBox(width: 2), Text(h.rating, style: t(12, c: kSub))]),
              const SizedBox(height: 3),
              Row(children: [const Icon(Icons.location_on_rounded, color: kRed, size: 15), const SizedBox(width: 3), Expanded(child: Text('${h.place} · ${h.km.toStringAsFixed(1)} كم', maxLines: 1, overflow: TextOverflow.ellipsis, style: t(11.5, w: FontWeight.w500, c: kGrey)))]),
              const SizedBox(height: 2),
              Row(children: [const Icon(Icons.schedule_rounded, color: kGrey, size: 15), const SizedBox(width: 3), Text(h.hours, style: t(11.5, w: FontWeight.w500, c: kGrey))]),
            ]),
          ),
        ]),
      );

  Widget service(BuildContext c, IconData icon, Color col, String title, String sub, Widget to) => Tap(
        onTap: () => go(c, to),
        scale: .98,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: cardBox(24),
          child: Row(children: [
            gTile(icon, size: 66, color: col),
            gapW(14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t(16.5)),
                const SizedBox(height: 3),
                Text(sub, style: t(12, w: FontWeight.w500, c: kGrey, h: 1.5)),
              ]),
            ),
            chev(kRed, 24),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ct = center;
    return RedPage(
        title: ct?.name ?? 'خدمة منزلية',
        nav: const AppNav(),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), children: [
          if (ct != null) ...[centerHeader(ct), sec('الخدمات المنزلية المتوفرة')],
          if (ct == null || ct.doctor) service(context, Icons.medical_services_rounded, kRed, 'زيارة طبيب للمنزل', 'استشارة وفحص في منزلك', const HomeRequestScreen(true)),
          if (ct == null || ct.nurse) service(context, Icons.vaccines_rounded, kBlue, 'تمريض منزلي', 'ممرض أو ممرضة لرعايتك في المنزل', const HomeRequestScreen(false)),
          if (ct == null || ct.lab) service(context, Icons.science_rounded, kTeal, 'خدمة معمل', 'سحب عينات وإجراء التحاليل', const LabScreen()),
          Tap(
            onTap: () => go(context, const HomeOrdersScreen()),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                const Icon(Icons.health_and_safety_rounded, size: 46, color: kRed),
                gapW(12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('رعايتك في منزلك .. بكل راحة', style: t(13.5)), Text('تابع حالة طلباتك المنزلية', style: t(11.5, w: FontWeight.w500, c: kSub))])),
                chev(kRed, 22),
              ]),
            ),
          ),
        ]),
      );
  }
}

class HomeRequestScreen extends StatefulWidget {
  const HomeRequestScreen(this.doctor, {super.key});
  final bool doctor;
  @override
  State<HomeRequestScreen> createState() => _HomeRequestState();
}

class _HomeRequestState extends State<HomeRequestScreen> {
  static const specs = ['باطنية', 'أطفال', 'نساء وتوليد', 'طب عام'];
  static const nurse = [('حقن وريدي', 3000), ('تغيير جروح', 2500), ('قياس ضغط وسكر', 1000), ('رعاية كبار السن', 2000)];
  static const hours = [1, 4, 12];
  static const doctorFee = 8000;
  Set<int> sel = {0};
  int dur = 0;
  (String, String) slot = SchedulePicker.initial();
  final notes = TextEditingController();
  bool busy = false;

  @override
  void initState() {
    super.initState();
    gate(context);
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  int get total {
    if (widget.doctor) return doctorFee;
    var s = 0;
    for (final i in sel) {
      s += i == 3 ? nurse[i].$2 * hours[dur] : nurse[i].$2;
    }
    return s;
  }

  void submit() {
    final isDoc = widget.doctor;
    if (sel.isEmpty) {
      snack(context, isDoc ? 'اختر التخصص أولاً' : 'اختر خدمة تمريضية واحدة على الأقل');
      return;
    }
    if (app.addrs.isEmpty) {
      snack(context, 'أضف عنواناً للزيارة أولاً');
      return;
    }
    setState(() => busy = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final chosen = isDoc ? specs[sel.first] : (sel.toList()..sort()).map((i) => nurse[i].$1).join(' + ');
      final title = isDoc ? 'زيارة طبيب' : 'تمريض منزلي';
      app.add(
        Appt(app.newId(), 2, title, isDoc ? 'تخصص $chosen' : chosen, slot.$1, slot.$2, status: 'قيد التأكيد', price: total, place: app.addr.line, centerId: app.homeCenter, phone: app.phone, who: app.name, method: 'نقداً عند الزيارة'),
        Notif(Icons.home_rounded, 'تم استلام طلبك', 'سنؤكد موعد $title خلال دقائق', 'الآن', unread: true, dest: 2),
      );
      done(context, DoneScreen('تم استلام طلبك', 'سنؤكد موعد الزيارة خلال دقائق.', [('الخدمة', '$title · $chosen'), ('الموعد', '${slot.$1} · ${slot.$2}'), ('العنوان', app.addr.line), ('الرسوم', '${money(total)} ج.س')], btn: 'متابعة الطلب', to: const HomeOrdersScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDoc = widget.doctor;
    return RedPage(
      title: isDoc ? 'زيارة طبيب للمنزل' : 'تمريض منزلي',
      bottomBar: btnBar(context, isDoc ? 'اطلب الزيارة' : 'اطلب ممرض', submit, loading: busy, lead: Row(children: [Text(isDoc ? 'رسوم الزيارة' : 'الإجمالي التقريبي', style: t(12.5, w: FontWeight.w600, c: kSub)), const Spacer(), Text('${money(total)} ج.س', style: t(16, c: kRed))])),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: [
        sec(isDoc ? 'التخصص' : 'نوع الخدمة'),
        ChipWrap(isDoc ? specs : [for (final n in nurse) n.$1], multi: !isDoc, onChanged: (s) => setState(() => sel = s)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (!isDoc && sel.contains(3)) ...[sec('مدة رعاية كبار السن'), ChipWrap(const ['ساعة', '4 ساعات', '12 ساعة'], onChanged: (s) => setState(() => dur = s.first))]]),
        SchedulePicker(onChanged: (s) => slot = s),
        sec('العنوان'),
        const AddressCard(),
        if (isDoc) AppField('وصف الحالة', controller: notes, hint: 'اكتب الأعراض باختصار...', lines: 3),
      ]),
    );
  }
}

// ───────────────────────── 13. Home lab (3 steps) ─────────────────────────
Widget labSteps(int a) {
  Widget s(int n, String l) => SizedBox(
        width: 60,
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(gradient: n <= a ? kGradient : null, color: n <= a ? null : const Color(0xFFEDF0F5), shape: BoxShape.circle, boxShadow: n == a ? kGlow : null),
            child: n < a ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : Text('$n', style: t(14, c: n <= a ? Colors.white : kInk)),
          ),
          const SizedBox(height: 6),
          Text(l, style: t(12, w: n == a ? FontWeight.w800 : FontWeight.w600)),
        ]),
      );
  Widget ln(bool on) => Expanded(child: Padding(padding: const EdgeInsets.only(top: 18), child: Container(height: 3, decoration: BoxDecoration(color: on ? kRed : const Color(0xFFE3E7EE), borderRadius: BorderRadius.circular(2)))));
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [s(1, 'التحاليل'), ln(a > 1), s(2, 'الموعد'), ln(a > 2), s(3, 'التأكيد')]),
  );
}

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});
  @override
  State<LabScreen> createState() => _LabState();
}

class _LabState extends State<LabScreen> {
  final Set<int> sel = {0, 1};
  final ctl = TextEditingController();
  bool all = false;

  @override
  void initState() {
    super.initState();
    gate(context);
  }

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  List<int> get idx {
    final q = ctl.text.trim();
    return [
      for (var i = 0; i < kTests.length; i++)
        if (q.isEmpty ? (all || i < 4) : kTests[i].$1.contains(q)) i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = idx;
    final searching = ctl.text.trim().isNotEmpty;
    return RedPage(
      title: 'خدمة المعمل المنزلي',
      bottomBar: btnBar(context, sel.isEmpty ? 'اختر تحليلاً واحداً على الأقل' : 'التالي · ${sel.length} تحليل', () => go(context, LabScheduleScreen([for (final i in (sel.toList()..sort())) kTests[i]])), enabled: sel.isNotEmpty),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 12), children: [
        labSteps(1),
        gap(20),
        Text('اختر التحاليل المطلوبة', style: t(15.5)),
        gap(12),
        AppSearch('ابحث عن تحليل...', controller: ctl, fill: Colors.white, onChanged: (_) => setState(() {})),
        gap(14),
        if (l.isEmpty)
          panel([Center(child: Text('لا توجد تحاليل مطابقة', style: t(13, w: FontWeight.w500, c: kGrey)))])
        else
          Container(
            decoration: cardBox(20),
            child: Column(children: [
              for (var n = 0; n < l.length; n++)
                Tap(
                  scale: .99,
                  onTap: () => setState(() {
                    if (sel.contains(l[n])) {
                      sel.remove(l[n]);
                    } else {
                      sel.add(l[n]);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(border: n == l.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F3F6)))),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: sel.contains(l[n]) ? kRed : Colors.white, borderRadius: BorderRadius.circular(8), border: sel.contains(l[n]) ? null : Border.all(color: const Color(0xFFD5DAE2), width: 1.6)),
                        child: sel.contains(l[n]) ? const Icon(Icons.check_rounded, color: Colors.white, size: 17) : null,
                      ),
                      gapW(12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(kTests[l[n]].$1, style: t(13.5)), Text('${kTests[l[n]].$2} ج.س', style: t(12, w: FontWeight.w500, c: kGrey))])),
                    ]),
                  ),
                ),
            ]),
          ),
        if (!searching) ...[
          gap(14),
          Center(
            child: Tap(
              onTap: () => setState(() => all = !all),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(all ? Icons.remove_rounded : Icons.add_rounded, color: kRed, size: 18), const SizedBox(width: 4), Text(all ? 'عرض أقل' : 'المزيد من التحاليل', style: t(12.5, c: kRed))]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class LabScheduleScreen extends StatefulWidget {
  const LabScheduleScreen(this.tests, {super.key});
  final List<(String, String)> tests;
  @override
  State<LabScheduleScreen> createState() => _LabScheduleState();
}

class _LabScheduleState extends State<LabScheduleScreen> {
  (String, String) slot = SchedulePicker.initial();
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'خدمة المعمل المنزلي',
        bottomBar: btnBar(context, 'التالي', () {
          if (app.addrs.isEmpty) {
            snack(context, 'أضف عنواناً لسحب العينات أولاً');
            return;
          }
          go(context, LabConfirmScreen(widget.tests, slot));
        }),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 12), children: [
          labSteps(2),
          SchedulePicker(onChanged: (s) => slot = s),
          sec('عنوان الزيارة'),
          const AddressCard(),
        ]),
      );
}

class LabConfirmScreen extends StatefulWidget {
  const LabConfirmScreen(this.tests, this.slot, {super.key});
  final List<(String, String)> tests;
  final (String, String) slot;
  @override
  State<LabConfirmScreen> createState() => _LabConfirmState();
}

class _LabConfirmState extends State<LabConfirmScreen> {
  bool busy = false;
  static const visit = 500;

  void confirmOrder() {
    setState(() => busy = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final w = widget;
      final sum = w.tests.fold<int>(0, (a, e) => a + toInt(e.$2));
      app.add(
        Appt(app.newId(), 3, 'تحاليل منزلية', w.tests.map((e) => e.$1).join(' + '), w.slot.$1, w.slot.$2, status: 'قيد التأكيد', price: sum + visit, place: app.addr.line, centerId: app.homeCenter, phone: app.phone, who: app.name, method: 'نقداً عند الزيارة'),
        Notif(Icons.science_rounded, 'تم استلام طلب المعمل المنزلي', 'سيصلك الفني في ${w.slot.$1}', 'الآن', unread: true, dest: 2),
      );
      done(context, DoneScreen('تم تأكيد طلب المعمل المنزلي', 'سيصلك الفني في الموعد المحدد لسحب العينات.', [('الموعد', '${w.slot.$1} · ${w.slot.$2}'), ('التحاليل', '${w.tests.length} تحليل'), ('الدفع', 'نقداً عند الزيارة'), ('الإجمالي', '${money(sum + visit)} ج.س')], btn: 'متابعة الطلب', to: const HomeOrdersScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final sum = w.tests.fold<int>(0, (a, e) => a + toInt(e.$2));
    return RedPage(
      title: 'خدمة المعمل المنزلي',
      bottomBar: btnBar(context, 'تأكيد الطلب', confirmOrder, loading: busy),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 12), children: [
        labSteps(3),
        gap(18),
        panel([Text('التحاليل المختارة', style: t(15)), gap(4), for (final e in w.tests) kv(e.$1, '${e.$2} ج.س')]),
        panel([kv('الموعد', '${w.slot.$1} · ${w.slot.$2}'), kv('العنوان', app.addr.line)]),
        panel([kv('إجمالي التحاليل', '${money(sum)} ج.س'), kv('رسوم الزيارة', '$visit ج.س'), kv('الإجمالي', '${money(sum + visit)} ج.س', bold: true)]),
        Align(alignment: AlignmentDirectional.centerStart, child: pillOk('الدفع نقداً عند الزيارة')),
      ]),
    );
  }
}

// ───────────────────────── 14. Ambulance ─────────────────────────
class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});
  @override
  State<AmbulanceScreen> createState() => _AmbulanceState();
}

class _AmbulanceState extends State<AmbulanceScreen> {
  static const types = ['إسعاف عادي', 'عناية مركزة'];
  int type = 0;
  final desc = TextEditingController();

  @override
  void dispose() {
    desc.dispose();
    super.dispose();
  }

  void request() {
    app.notifs.insert(0, Notif(Icons.emergency_rounded, 'تم تأكيد طلب الإسعاف', 'سيارة الإسعاف في الطريق إلى ${app.addr.line}', 'الآن', unread: true));
    app.ping();
    go(context, AmbulanceTrackScreen(types[type], app.addr.line));
  }

  @override
  Widget build(BuildContext context) => MapPage(
        'طلب إسعاف',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AddressCard(),
          sec('نوع الإسعاف'),
          ChipWrap(types, onChanged: (s) => type = s.first),
          AppField('وصف الحالة', controller: desc, hint: 'وصف مختصر للحالة (اختياري)...', lines: 2),
          gap(20),
          RedButton('اطلب إسعاف الآن', icon: Icons.emergency_rounded, onTap: request),
          gap(8),
          Center(child: Text('أقرب سيارة إسعاف على بعد حوالي 6 دقائق', style: t(11.5, w: FontWeight.w500, c: kGrey))),
        ]),
      );
}

class AmbulanceTrackScreen extends StatefulWidget {
  const AmbulanceTrackScreen(this.type, this.place, {super.key});
  final String type, place;
  @override
  State<AmbulanceTrackScreen> createState() => _TrackState();
}

class _TrackState extends State<AmbulanceTrackScreen> {
  static const total = 6;
  int eta = total;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (eta > 0) setState(() => eta--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> cancel() async {
    final ok = await confirm(context, 'إلغاء طلب الإسعاف؟', 'سيتم إيقاف إرسال سيارة الإسعاف إلى موقعك.', yes: 'نعم، ألغِ الطلب', no: 'متابعة الطلب');
    if (!ok || !mounted) return;
    Navigator.popUntil(context, (r) => r.isFirst);
    snack(context, 'تم إلغاء طلب الإسعاف');
  }

  @override
  Widget build(BuildContext context) {
    final arrived = eta == 0;
    return MapPage(
      'تتبّع الإسعاف',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(arrived ? 'وصلت سيارة الإسعاف' : 'وصول الإسعاف خلال', style: t(12, w: FontWeight.w500, c: kGrey)), Text(arrived ? 'في موقعك الآن' : '$eta دقائق', style: t(26, c: arrived ? kGreenDk : kRed))])),
          arrived ? pillOk('وصلت') : pillWarn('في الطريق'),
        ]),
        gap(10),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: 1 - eta / total, minHeight: 7, color: kRed, backgroundColor: kLine)),
        gap(14),
        panel([
          Row(children: [
            tileIcon(Icons.person_rounded, size: 46),
            gapW(12),
            Expanded(child: two('السائق: محمد حسن', 'إسعاف رقم 3 · تقييم 4.9')),
            glass(const Icon(Icons.phone_rounded, color: Colors.white, size: 20), () => contactSheet(context, 'السائق: محمد حسن', '+249 912 000 999'), bg: kRed),
          ]),
        ]),
        panel([kv('نقطة الاستلام', widget.place), kv('نوع الإسعاف', widget.type)]),
        if (!arrived) OutBtn('إلغاء الطلب', onTap: cancel) else RedButton('تم، شكراً', onTap: () => home(context)),
      ]),
      route: true,
    );
  }
}

// ───────────────────────── 15. Appointments ─────────────────────────
Color kindColor(int k) => const [kRed, kBlue, kOrange, kTeal][k];

class ApptCard extends StatelessWidget {
  const ApptCard(this.a, {super.key});
  final Appt a;

  @override
  Widget build(BuildContext context) {
    final c = context;
    Widget? actions;
    if (a.upcoming) {
      actions = Row(children: [
        if (a.kind != 1) ...[Expanded(child: RedButton('إعادة جدولة', height: 42, onTap: () => go(c, RescheduleScreen(a)))), gapW(10)],
        Expanded(child: OutBtn('إلغاء', height: 42, onTap: () => go(c, CancelScreen(a)))),
      ]);
    } else if (a.status == 'مكتمل' && a.doctor != null) {
      actions = Row(children: [
        Expanded(child: RedButton('قيّم الطبيب', height: 42, onTap: () => go(c, RateScreen(a.doctor!)))),
        gapW(10),
        Expanded(child: OutBtn('احجز مجدداً', height: 42, onTap: () => go(c, ConfirmBookingScreen(a.doctor!)))),
      ]);
    } else if (a.status == 'ملغي' && a.doctor != null) {
      actions = OutBtn('احجز مجدداً', height: 42, onTap: () => go(c, ConfirmBookingScreen(a.doctor!)));
    }
    return Tap(
      onTap: () => go(c, AppointmentDetailsScreen(a)),
      scale: .98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: cardBox(24),
        child: Column(children: [
          Row(children: [
            a.doctor != null ? Pic(a.doctor!.img, size: 54, radius: 18, label: a.title) : gTile(a.icon, size: 54, color: kindColor(a.kind)),
            gapW(12),
            Expanded(child: two(a.title, a.sub)),
            statusPill(a.status),
          ]),
          gap(12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.calendar_month_outlined, size: 17, color: kRed),
              const SizedBox(width: 6),
              Expanded(child: Text(a.day, style: t(12.5, w: FontWeight.w600, c: kSub))),
              Icon(a.kind == 1 ? Icons.hotel_rounded : Icons.access_time_rounded, size: 17, color: kRed),
              const SizedBox(width: 6),
              Text(a.time, style: t(12.5, w: FontWeight.w600, c: kSub)),
            ]),
          ),
          if (actions != null) ...[gap(12), actions],
        ]),
      ),
    );
  }
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<AppointmentsScreen> {
  int tab = 0;
  static const tabs = ['القادمة', 'السابقة', 'الملغاة'];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          final l = app.appts.where((a) => tab == 0 ? a.upcoming : (tab == 1 ? a.status == 'مكتمل' : a.status == 'ملغي')).toList();
          return RedPage(
            title: 'حجوزاتي',
            nav: const AppNav(active: {1}),
            body: Column(children: [
              gap(16),
              FilterChips([for (var i = 0; i < tabs.length; i++) '${tabs[i]} (${app.appts.where((a) => i == 0 ? a.upcoming : (i == 1 ? a.status == 'مكتمل' : a.status == 'ملغي')).length})'], sel: tab, onChanged: (v) => setState(() => tab = v)),
              Expanded(
                child: l.isEmpty
                    ? EmptyState(Icons.event_busy_rounded, tab == 0 ? 'لا توجد حجوزات قادمة' : (tab == 1 ? 'لا توجد حجوزات سابقة' : 'لا توجد حجوزات ملغاة'), tab == 0 ? 'احجز موعدك الأول مع أحد أطبائنا.' : 'ستظهر هنا حجوزاتك عند توفرها.', btn: tab == 0 ? 'احجز طبيباً' : null, onTap: () => go(c, const DoctorListScreen()))
                    : ListView(padding: const EdgeInsets.all(16), children: [for (final a in l) ApptCard(a)]),
              ),
            ]),
          );
        },
      );
}

class AppointmentDetailsScreen extends StatelessWidget {
  const AppointmentDetailsScreen(this.a, {super.key});
  final Appt a;

  List<(String, String, int)> steps() {
    final order = ['قيد التأكيد', 'مؤكد', 'قيد التنفيذ', 'مكتمل'];
    final cur = a.status == 'ملغي' ? -1 : order.indexOf(a.status);
    final names = [
      ('تم استلام الطلب', 'تم إرسال طلبك بنجاح'),
      ('تأكيد الموعد', 'مراجعة الطلب وتأكيد الفريق'),
      (a.kind == 3 ? 'الفني في الطريق' : 'الفريق في الطريق', 'سيصلك إشعار عند الاقتراب'),
      (a.kind == 3 ? 'تم سحب العينات' : 'تمت الزيارة', 'اكتمل الطلب'),
    ];
    return [for (var i = 0; i < 4; i++) (names[i].$1, names[i].$2, i == 0 ? 1 : (cur > i ? 1 : (cur == i ? 2 : 0)))];
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          Widget? bar;
          if (a.upcoming) {
            bar = a.kind == 1 ? btnBar(c, 'إلغاء الحجز', () => go(c, CancelScreen(a))) : btnBar(c, 'إعادة جدولة', () => go(c, RescheduleScreen(a)), alt: 'إلغاء الحجز', onAlt: () => go(c, CancelScreen(a)));
          } else if (a.doctor != null && a.status == 'مكتمل') {
            bar = btnBar(c, 'قيّم الطبيب', () => go(c, RateScreen(a.doctor!)), alt: 'احجز مجدداً', onAlt: () => go(c, ConfirmBookingScreen(a.doctor!)));
          } else if (a.doctor != null && a.status == 'ملغي') {
            bar = btnBar(c, 'احجز مجدداً', () => go(c, ConfirmBookingScreen(a.doctor!)));
          }
          return RedPage(
            title: 'تفاصيل الحجز',
            bottomBar: bar,
            body: ListView(padding: const EdgeInsets.all(16), children: [
              panel([
                Row(children: [
                  a.doctor != null ? Pic(a.doctor!.img, size: 60, radius: 20, label: a.title) : gTile(a.icon, size: 60, color: kindColor(a.kind)),
                  gapW(12),
                  Expanded(child: two(a.title, a.sub)),
                  statusPill(a.status),
                ]),
              ]),
              panel([
                Row(children: [
                  tileIcon(Icons.confirmation_number_outlined, size: 44),
                  gapW(12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('رقم الحجز', style: t(11.5, w: FontWeight.w500, c: kGrey)), Directionality(textDirection: TextDirection.ltr, child: Text(a.code, style: t(17, c: kInk)))])),
                  Tap(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: a.code));
                      snack(c, 'تم نسخ رقم الحجز', ok: true);
                    },
                    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.content_copy_rounded, color: kRed, size: 18)),
                  ),
                ]),
              ]),
              panel([
                kv('التاريخ', a.day),
                kv(a.kind == 1 ? 'مدة الإقامة' : 'الوقت', a.time),
                kv(a.kind == 2 || a.kind == 3 ? 'العنوان' : 'المكان', a.place.isEmpty ? '—' : a.place),
                kv(a.kind == 1 ? 'اسم المريض' : 'الحجز لـ', a.who.isEmpty ? app.name : a.who),
                if (a.complaint.isNotEmpty) kv('الشكوى', a.complaint),
                if (a.kind == 0 && a.complaint.isNotEmpty) kv('الملف الصحي', a.sharedHealth ? 'مُشارَك مع الطبيب' : 'غير مُشارَك'),
                if (a.method.isNotEmpty) kv('طريقة الدفع', a.method),
                kv('الرسوم', '${money(a.price)} ج.س', bold: true),
              ]),
              if ((a.kind == 2 || a.kind == 3) && a.status != 'ملغي') panel([Text('حالة الطلب', style: t(15)), gap(14), timeline(steps())]),
              if (a.status == 'ملغي') panel([Row(children: [const Icon(Icons.info_outline_rounded, color: kRed, size: 20), gapW(8), Expanded(child: Text('تم إلغاء هذا الحجز. يمكنك حجز موعد جديد في أي وقت.', style: t(12.5, w: FontWeight.w500, c: kSub, h: 1.6)))])]),
              OutBtn('تواصل مع الدعم', icon: Icons.support_agent_rounded, onTap: () => go(c, const SupportChatScreen())),
            ]),
          );
        },
      );
}

class CancelScreen extends StatefulWidget {
  const CancelScreen(this.a, {super.key});
  final Appt a;
  @override
  State<CancelScreen> createState() => _CancelState();
}

class _CancelState extends State<CancelScreen> {
  static const reasons = [('تغيّرت ظروفي', ''), ('وجدت موعداً أنسب', ''), ('الطبيب أو الخدمة غير مناسبة', ''), ('سبب آخر', '')];
  int r = 0;

  Future<void> submit() async {
    final ok = await confirm(context, 'تأكيد إلغاء الحجز؟', 'لن تتمكن من التراجع عن الإلغاء بعد التأكيد.', yes: 'نعم، ألغِ الحجز', no: 'تراجع');
    if (!ok || !mounted) return;
    final a = widget.a;
    a.status = 'ملغي';
    app.notifs.insert(0, Notif(Icons.cancel_rounded, 'تم إلغاء حجزك', '${a.title} · ${a.day}', 'الآن', unread: true, dest: 1));
    app.ping();
    done(context, DoneScreen('تم إلغاء الحجز', 'تم إلغاء حجزك بنجاح، ويمكنك الحجز مجدداً في أي وقت.', [('الحجز', a.title), ('الموعد', '${a.day} · ${a.time}'), ('السبب', reasons[r].$1)], btn: 'عرض حجوزاتي', to: const AppointmentsScreen()));
  }

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'إلغاء الحجز',
        bottomBar: btnBar(context, 'تأكيد الإلغاء', submit),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          panel([Row(children: [gTile(widget.a.icon, size: 48, color: kindColor(widget.a.kind)), gapW(12), Expanded(child: two(widget.a.title, '${widget.a.day} · ${widget.a.time}'))])]),
          sec('سبب الإلغاء'),
          RadioPick(reasons, onChanged: (v) => r = v),
          gap(4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kAmberBg, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [const Icon(Icons.info_outline_rounded, color: kAmber, size: 20), gapW(8), Expanded(child: Text('الإلغاء قبل 24 ساعة من الموعد بدون رسوم.', style: t(12, w: FontWeight.w600, c: kAmber)))]),
          ),
        ]),
      );
}

class RescheduleScreen extends StatefulWidget {
  const RescheduleScreen(this.a, {super.key});
  final Appt a;
  @override
  State<RescheduleScreen> createState() => _RescheduleState();
}

class _RescheduleState extends State<RescheduleScreen> {
  late final Work? work = widget.a.doctor?.workAt(widget.a.centerId); // أيام الطبيب وساعاته في هذا المركز
  late (String, String) slot = SchedulePicker.initial(work);

  void submit() {
    final a = widget.a;
    a.day = slot.$1;
    a.time = slot.$2;
    a.status = 'قيد التأكيد';
    app.notifs.insert(0, Notif(Icons.event_repeat_rounded, 'تم تعديل موعدك', '${a.title} · ${slot.$1} ${slot.$2}', 'الآن', unread: true, dest: 1));
    app.ping();
    done(context, DoneScreen('تم تعديل الموعد', 'سيتم إشعارك بمجرد تأكيد الموعد الجديد.', [('الحجز', a.title), ('الموعد الجديد', '${slot.$1} · ${slot.$2}')], btn: 'عرض حجوزاتي', to: const AppointmentsScreen()));
  }

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'إعادة جدولة',
        bottomBar: btnBar(context, 'تأكيد الموعد الجديد', submit),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), children: [
          panel([Row(children: [gTile(widget.a.icon, size: 48, color: kindColor(widget.a.kind)), gapW(12), Expanded(child: two(widget.a.title, 'الموعد الحالي: ${widget.a.day} · ${widget.a.time}'))])]),
          SchedulePicker(work: work, onChanged: (s) => slot = s),
        ]),
      );
}

// ───────────────────────── 16. Notifications ─────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void open(BuildContext c, Notif n) {
    n.unread = false;
    app.ping();
    switch (n.dest) {
      case 1:
        go(c, const AppointmentsScreen());
      case 2:
        go(c, const HomeOrdersScreen());
      case 3:
        go(c, const LabResultsScreen());
      case 4:
        go(c, const OffersScreen());
      default:
        break;
    }
  }

  Widget tile(BuildContext c, Notif n) => Dismissible(
        key: ObjectKey(n),
        direction: DismissDirection.horizontal,
        background: Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(20)), alignment: Alignment.center, child: const Icon(Icons.delete_outline_rounded, color: kRed)),
        onDismissed: (_) {
          app.notifs.remove(n);
          app.ping();
        },
        child: Tap(
          onTap: () => open(c, n),
          scale: .98,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: n.unread ? const Color(0xFFFFF7F8) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: kShadow, border: Border.all(color: n.unread ? const Color(0xFFFAD3D6) : const Color(0xFFF1F3F7))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              tileIcon(n.icon, size: 44),
              gapW(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(n.title, style: t(14))), if (n.unread) Container(width: 9, height: 9, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle))]),
                  const SizedBox(height: 2),
                  Text(n.body, style: t(12, w: FontWeight.w500, c: kSub, h: 1.5)),
                  const SizedBox(height: 4),
                  Text(n.time, style: t(11, w: FontWeight.w500, c: kGrey)),
                ]),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          final today = app.notifs.where((n) => n.today).toList();
          final older = app.notifs.where((n) => !n.today).toList();
          return RedPage(
            title: 'الإشعارات',
            nav: const AppNav(active: {2}),
            action: app.unread > 0 ? glass(const Icon(Icons.done_all_rounded, color: Colors.white, size: 22), () {
                  app.markAllRead();
                  snack(c, 'تم تحديد الكل كمقروء', ok: true);
                }) : null,
            body: app.notifs.isEmpty
                ? const EmptyState(Icons.notifications_off_rounded, 'لا توجد إشعارات', 'ستظهر هنا تحديثات حجوزاتك وعروضك.')
                : ListView(padding: const EdgeInsets.all(16), children: [
                    if (today.isNotEmpty) ...[Text('اليوم', style: t(14, c: kGrey)), gap(10), for (final n in today) tile(c, n)],
                    if (older.isNotEmpty) ...[gap(6), Text('أمس', style: t(14, c: kGrey)), gap(10), for (final n in older) tile(c, n)],
                  ]),
          );
        },
      );
}

// ───────────────────────── 17. Home orders ─────────────────────────
class HomeOrdersScreen extends StatefulWidget {
  const HomeOrdersScreen({super.key});
  @override
  State<HomeOrdersScreen> createState() => _HomeOrdersState();
}

class _HomeOrdersState extends State<HomeOrdersScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          final l = app.appts.where((a) => (a.kind == 2 || a.kind == 3) && (tab == 0 ? a.upcoming : !a.upcoming)).toList();
          return RedPage(
            title: 'طلباتي المنزلية',
            body: Column(children: [
              gap(16),
              FilterChips(const ['نشطة', 'السابقة'], sel: tab, onChanged: (v) => setState(() => tab = v)),
              Expanded(
                child: l.isEmpty
                    ? EmptyState(Icons.home_work_rounded, 'لا توجد طلبات', 'اطلب زيارة طبيب أو ممرض أو سحب عينات من منزلك.', btn: 'اطلب خدمة منزلية', onTap: () => go(c, const HomeCentersScreen()))
                    : ListView(padding: const EdgeInsets.all(16), children: [for (final a in l) ApptCard(a)]),
              ),
            ]),
          );
        },
      );
}

// ───────────────────────── 18. Reviews / Rate ─────────────────────────
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen(this.d, {super.key});
  final Doctor d;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          final l = app.reviewsOf(d);
          return RedPage(
            title: 'التقييمات',
            bottomBar: btnBar(c, 'أضف تقييمك', () => go(c, RateScreen(d)), icon: Icons.rate_review_rounded),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              panel([
                Row(children: [
                  Column(children: [Text(d.rating, style: t(40, h: 1.1)), stars(double.tryParse(d.rating) ?? 0, size: 15), const SizedBox(height: 4), Text('${d.reviews} تقييم', style: t(11, w: FontWeight.w500, c: kGrey))]),
                  gapW(20),
                  Expanded(
                    child: Column(children: [
                      for (var s = 5; s >= 1; s--)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Text('$s', style: t(11.5, c: kGrey)),
                            const SizedBox(width: 6),
                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: l.isEmpty ? 0 : l.where((r) => r.stars == s).length / l.length, minHeight: 6, color: kGold, backgroundColor: kChip))),
                          ]),
                        ),
                    ]),
                  ),
                ]),
              ]),
              for (final r in l)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: cardBox(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 38, height: 38, alignment: Alignment.center, decoration: const BoxDecoration(color: kTint, shape: BoxShape.circle), child: Text(initial(r.name), style: t(16, c: kRed))),
                      gapW(10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.name, style: t(13.5)), Text(r.time, style: t(11, w: FontWeight.w500, c: kGrey))])),
                      stars(r.stars.toDouble(), size: 15),
                    ]),
                    gap(8),
                    Text(r.text, style: t(12.5, w: FontWeight.w500, c: kSub, h: 1.7)),
                  ]),
                ),
            ]),
          );
        },
      );
}

class RateScreen extends StatefulWidget {
  const RateScreen(this.d, {super.key});
  final Doctor d;
  @override
  State<RateScreen> createState() => _RateState();
}

class _RateState extends State<RateScreen> {
  static const tags = ['وقت انتظار قصير', 'تعامل ممتاز', 'شرح واضح', 'نظافة المكان', 'التزام بالموعد'];
  int rate = 0;
  Set<int> picked = {};
  final ctl = TextEditingController();

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  void submit() {
    if (rate == 0) {
      snack(context, 'اختر عدد النجوم أولاً');
      return;
    }
    final parts = [for (final i in (picked.toList()..sort())) tags[i], if (ctl.text.trim().isNotEmpty) ctl.text.trim()];
    app.reviewsOf(widget.d).insert(0, Review(app.name, rate, parts.isEmpty ? 'تجربة ${rate >= 4 ? 'رائعة' : 'جيدة'}.' : parts.join(' · '), 'الآن'));
    app.ping();
    Navigator.pop(context);
    snack(context, 'شكراً لتقييمك', ok: true);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return RedPage(
      title: 'قيّم تجربتك',
      bottomBar: btnBar(context, 'إرسال التقييم', submit, enabled: rate > 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        gap(8),
        Center(child: Pic(d.img, size: 84, radius: 28, label: d.name)),
        gap(10),
        Center(child: Text(d.name, style: t(17))),
        Center(child: Text(d.spec, style: t(12.5, w: FontWeight.w500, c: kGrey))),
        gap(18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 1; i <= 5; i++)
            Tap(onTap: () => setState(() => rate = i), child: Padding(padding: const EdgeInsets.all(5), child: AnimatedScale(scale: i <= rate ? 1.12 : 1, duration: const Duration(milliseconds: 150), child: Icon(i <= rate ? Icons.star_rounded : Icons.star_outline_rounded, size: 44, color: i <= rate ? kGold : const Color(0xFFD6DBE6))))),
        ]),
        Center(child: Text(rate == 0 ? 'اضغط على النجوم للتقييم' : const ['', 'سيئة', 'مقبولة', 'جيدة', 'ممتازة', 'رائعة'][rate], style: t(13, w: FontWeight.w600, c: kGrey))),
        sec('ما الذي أعجبك؟'),
        ChipWrap(tags, multi: true, sel: const {}, onChanged: (s) => picked = s),
        AppField('تعليقك (اختياري)', controller: ctl, hint: 'شاركنا تفاصيل تجربتك...', lines: 3),
      ]),
    );
  }
}

// ───────────────────────── 19. Favorites ─────────────────────────
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          final l = doctors.where(app.isFav).toList();
          return RedPage(
            title: 'المفضلة',
            body: l.isEmpty
                ? EmptyState(Icons.favorite_border_rounded, 'لا توجد أطباء في المفضلة', 'اضغط على القلب في بطاقة الطبيب لإضافته هنا.', btn: 'استعرض الأطباء', onTap: () => go(c, const DoctorListScreen()))
                : ListView.separated(padding: const EdgeInsets.all(16), itemCount: l.length, separatorBuilder: (_, __) => const SizedBox(height: 14), itemBuilder: (_, i) => DoctorCard(l[i])),
          );
        },
      );
}

// ───────────────────────── 20. Profile ─────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget stat(String v, String l, IconData i) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: cardBox(18),
          child: Column(children: [Icon(i, color: kRed, size: 20), const SizedBox(height: 4), Text(v, style: t(17)), Text(l, style: t(11, w: FontWeight.w500, c: kGrey))]),
        ),
      );

  Future<void> logout(BuildContext c) async {
    final ok = await confirm(c, 'تسجيل الخروج؟', 'يمكنك الدخول مجدداً برقم هاتفك ورمز التحقق، وستعود بياناتك كما هي.', yes: 'تسجيل الخروج', no: 'بقاء');
    if (!ok || !c.mounted) return;
    app.signOut();
    Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) => RedPage(
          title: 'حسابي',
          nav: const AppNav(active: {3}),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardBox(24),
              child: Row(children: [
                Tap(
                  onTap: () => app.registered ? photoSheet(c) : go(c, const LoginScreen()),
                  child: Stack(clipBehavior: Clip.none, children: [
                    const UserAvatar(size: 66),
                    Positioned(bottom: -2, left: -2, child: Container(width: 24, height: 24, decoration: BoxDecoration(color: kRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13))),
                  ]),
                ),
                gapW(14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.registered ? app.name : 'زائر', style: t(17)),
                    const SizedBox(height: 2),
                    Text(app.registered ? fmtPhone(app.phone) : 'سجّل رقمك لتتمكن من الحجز', textDirection: TextDirection.ltr, style: t(12.5, w: FontWeight.w500, c: kGrey)),
                  ]),
                ),
                Tap(onTap: () => go(c, const PersonalInfoScreen()), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(14)), child: Text('تعديل', style: t(12.5, c: kRed)))),
              ]),
            ),
            gap(12),
            Row(children: [
              stat('${app.appts.where((a) => a.upcoming).length}', 'حجوزات قادمة', Icons.event_available_rounded),
              stat('${app.favs.length}', 'المفضلة', Icons.favorite_rounded),
              stat('${app.addrs.length}', 'العناوين', Icons.location_on_rounded),
            ]),
            secRow('حسابي'),
            group([
              menuRow(Icons.person_rounded, 'المعلومات الشخصية', onTap: () => go(c, const PersonalInfoScreen())),
              menuRow(Icons.health_and_safety_rounded, 'ملفي الصحي', trailing: cnt('${app.health.done}/${HealthProfile.steps.length}'), onTap: () => go(c, const HealthProfileScreen())),
              menuRow(Icons.family_restroom_rounded, 'أفراد العائلة', trailing: cnt('${app.family.length + 1}'), onTap: () => go(c, const FamilyScreen())),
              menuRow(Icons.location_on_rounded, 'عناويني', trailing: cnt('${app.addrs.length}'), onTap: () => go(c, const AddressesScreen())),
              menuRow(Icons.favorite_rounded, 'المفضلة', trailing: cnt('${app.favs.length}'), onTap: () => go(c, const FavoritesScreen())),
              menuRow(Icons.folder_shared_rounded, 'السجل الطبي', onTap: () => go(c, const RecordsScreen())),
            ]),
            secRow('الخدمات'),
            group([
              menuRow(Icons.home_work_rounded, 'طلباتي المنزلية', onTap: () => go(c, const HomeOrdersScreen())),
              menuRow(Icons.receipt_long_rounded, 'المدفوعات والفواتير', onTap: () => go(c, const PaymentsScreen())),
              menuRow(Icons.local_offer_rounded, 'العروض والكوبونات', onTap: () => go(c, const OffersScreen())),
            ]),
            secRow('الدعم'),
            group([
              menuRow(Icons.settings_rounded, 'الإعدادات', onTap: () => go(c, const SettingsScreen())),
              menuRow(Icons.support_agent_rounded, 'مركز المساعدة', onTap: () => go(c, const HelpScreen())),
            ]),
            gap(14),
            OutBtn('تسجيل الخروج', icon: Icons.logout_rounded, danger: true, onTap: () => logout(c)),
          ]),
        ),
      );
}

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});
  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfoScreen> {
  static const bloods = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  late final nm = TextEditingController(text: app.name);
  late final ph = TextEditingController(text: fmtPhone(app.phone));
  late final dob = TextEditingController(text: app.dob);
  late int blood = bloods.indexOf(app.blood); // -1 = غير محددة
  late int gender = app.gender == 'أنثى' ? 1 : (app.gender == 'ذكر' ? 0 : -1);
  String? eName, ePhone;

  @override
  void dispose() {
    nm.dispose();
    ph.dispose();
    dob.dispose();
    super.dispose();
  }

  void save() {
    setState(() => eName = nm.text.trim().length < 3 ? 'أدخل اسمك الكامل' : null);
    if (eName != null) return;
    app.name = nm.text.trim();
    app.dob = dob.text;
    app.blood = blood < 0 ? '' : bloods[blood];
    app.gender = gender < 0 ? '' : (gender == 0 ? 'ذكر' : 'أنثى');
    app.ping();
    Navigator.pop(context);
    snack(context, 'تم حفظ التغييرات', ok: true);
  }

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'المعلومات الشخصية',
        bottomBar: btnBar(context, 'حفظ التغييرات', save),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
          gap(8),
          Center(
            child: Tap(
              onTap: () async {
                await photoSheet(context);
                if (mounted) setState(() {});
              },
              child: Stack(clipBehavior: Clip.none, children: [
                const UserAvatar(size: 92),
                Positioned(bottom: 0, left: 0, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: kRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16))),
              ]),
            ),
          ),
          AppField('الاسم الكامل', controller: nm, icon: Icons.person_outline_rounded, error: eName),
          AppField('رقم الهاتف (هو هويتك في التطبيق ولا يتغيّر من هنا)', controller: ph, icon: Icons.phone_outlined, ltr: true, readOnly: true),
          AppField('تاريخ الميلاد', controller: dob, icon: Icons.calendar_today_outlined, readOnly: true, onTap: () async {
            final v = await pickDob(context);
            if (v != null && mounted) setState(() => dob.text = v);
          }),
          sec('الجنس'),
          ChipWrap(const ['ذكر', 'أنثى'], sel: {gender}, onChanged: (s) => gender = s.first),
          sec('فصيلة الدم'),
          ChipWrap(bloods, sel: {blood}, onChanged: (s) => blood = s.first),
        ]),
      );
}

// ───────────────────────── 21. Settings / info ─────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget sw(IconData i, String s, bool v, ValueChanged<bool> on) => menuRow(i, s, trailing: Switch(value: v, onChanged: on));

  void fontSheet(BuildContext c) => sheet(
        c,
        Column(children: [
          Text('حجم الخط', style: t(17)),
          gap(14),
          for (var i = 0; i < 3; i++)
            Tap(
              onTap: () {
                app.fontIdx = i;
                app.ping();
                Navigator.pop(c);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: app.fontIdx == i ? const Color(0xFFFFF5F6) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: app.fontIdx == i ? kRed : kLine, width: 1.5)),
                child: Row(children: [Expanded(child: Text(const ['صغير', 'عادي', 'كبير'][i], style: t(const [13.0, 15.0, 17.0][i]))), if (app.fontIdx == i) const Icon(Icons.check_circle_rounded, color: kRed)]),
              ),
            ),
        ]),
      );

  void langSheet(BuildContext c) => sheet(
        c,
        Column(children: [
          Text('اللغة', style: t(17)),
          gap(14),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF5F6), borderRadius: BorderRadius.circular(16), border: Border.all(color: kRed, width: 1.5)), child: Row(children: [Expanded(child: Text('العربية', style: t(15))), const Icon(Icons.check_circle_rounded, color: kRed)])),
          gap(10),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)), child: Row(children: [Expanded(child: Text('English', style: t(15, c: kGrey))), pill('قريباً', kChip, kGrey)])),
        ]),
      );

  Future<void> deleteAccount(BuildContext c) async {
    final ok = await confirm(c, 'حذف الحساب؟', 'سيتم حذف بياناتك وحجوزاتك نهائياً ولا يمكن التراجع.', yes: 'نعم، احذف حسابي', no: 'تراجع');
    if (!ok || !c.mounted) return;
    app.deleteAccount();
    Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    snack(c, 'تم حذف الحساب');
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) => RedPage(
          title: 'الإعدادات',
          body: ListView(padding: const EdgeInsets.all(16), children: [
            group([
              sw(Icons.notifications_rounded, 'الإشعارات', app.notifOn, (v) {
                app.notifOn = v;
                app.ping();
              }),
              sw(Icons.alarm_rounded, 'تذكير بالمواعيد', app.remindOn, (v) {
                app.remindOn = v;
                app.ping();
              }),
              sw(Icons.my_location_rounded, 'خدمة الموقع', app.locOn, (v) {
                app.locOn = v;
                app.ping();
              }),
            ]),
            gap(12),
            group([
              menuRow(Icons.text_fields_rounded, 'حجم الخط', trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(const ['صغير', 'عادي', 'كبير'][app.fontIdx], style: t(12.5, c: kGrey)), const SizedBox(width: 4), chev(kGrey, 20)]), onTap: () => fontSheet(c)),
              menuRow(Icons.language_rounded, 'اللغة', trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('العربية', style: t(12.5, c: kGrey)), const SizedBox(width: 4), chev(kGrey, 20)]), onTap: () => langSheet(c)),
              menuRow(Icons.lock_rounded, 'الخصوصية والأمان', onTap: () => go(c, InfoScreen.privacy())),
              menuRow(Icons.description_rounded, 'الشروط والأحكام', onTap: () => go(c, InfoScreen.terms())),
              menuRow(Icons.info_rounded, 'عن التطبيق', onTap: () => go(c, InfoScreen.about())),
            ]),
            gap(12),
            group([menuRow(Icons.delete_forever_rounded, 'حذف الحساب', color: kRed, text: kRed, onTap: () => deleteAccount(c))]),
          ]),
        ),
      );
}

class InfoScreen extends StatelessWidget {
  const InfoScreen(this.title, this.items, {super.key});
  final String title;
  final List<(String, String)> items;

  static InfoScreen terms() => const InfoScreen('الشروط والأحكام', [
        ('استخدام التطبيق', 'يوفّر طبيبك خدمة حجز المواعيد والأسرّة وطلب الخدمات الطبية المنزلية. باستخدامك للتطبيق فإنك توافق على هذه الشروط.'),
        ('الحجوزات', 'الحجز يصبح مؤكداً بعد مراجعة المركز. يمكن إلغاء الحجز أو تعديله قبل 24 ساعة من الموعد دون رسوم.'),
        ('الدفع', 'تُعرض الرسوم قبل التأكيد ولا تُضاف أي رسوم خفية. تُطبّق سياسة الاسترداد حسب كل مركز.'),
        ('المسؤولية الطبية', 'التطبيق وسيط للحجز ولا يُغني عن استشارة الطبيب. في الحالات الطارئة اطلب الإسعاف فوراً.'),
      ]);

  static InfoScreen privacy() => const InfoScreen('الخصوصية والأمان', [
        ('بياناتك', 'نجمع الاسم ورقم الهاتف والبيانات الطبية اللازمة لتقديم الخدمة فقط.'),
        ('المشاركة', 'لا نشارك بياناتك إلا مع المركز أو الطبيب الذي تحجز عنده.'),
        ('الأمان', 'يتم حماية بياناتك وفق معايير الأمان، ويمكنك طلب حذف حسابك في أي وقت من الإعدادات.'),
        ('الموقع', 'نستخدم موقعك لعرض أقرب المراكز وتوجيه الإسعاف، ويمكنك إيقافه من الإعدادات.'),
      ]);

  static InfoScreen about() => const InfoScreen('عن التطبيق', [
        ('طبيبك', 'تطبيق يجمع حجز الأطباء والأسرّة والإسعاف والخدمات المنزلية في مكان واحد.'),
        ('الإصدار', '2.0.0'),
        ('تواصل معنا', 'support@tabibak.sd'),
      ]);

  @override
  Widget build(BuildContext context) => RedPage(
        title: title,
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final it in items)
            panel([Text(it.$1, style: t(15)), gap(6), Text(it.$2, style: t(13, w: FontWeight.w500, c: kSub, h: 1.8))]),
        ]),
      );
}

// ───────────────────────── 22. Help & support chat ─────────────────────────
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpState();
}

class _HelpState extends State<HelpScreen> {
  final ctl = TextEditingController();
  final open = <int>{};

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  Widget contact(IconData i, String l, VoidCallback on, Color col) => Expanded(
        child: Tap(
          onTap: on,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: cardBox(20),
            child: Column(children: [gTile(i, size: 44, color: col), gap(8), Text(l, style: t(12.5))]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final q = ctl.text.trim();
    final idx = [for (var i = 0; i < kFaqs.length; i++) if (q.isEmpty || kFaqs[i].$1.contains(q) || kFaqs[i].$2.contains(q)) i];
    return RedPage(
      title: 'مركز المساعدة',
      bottomBar: btnBar(context, 'تواصل مع الدعم', () => go(context, const SupportChatScreen()), icon: Icons.chat_rounded),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppSearch('كيف يمكننا مساعدتك؟', controller: ctl, fill: Colors.white, onChanged: (_) => setState(() {})),
        gap(16),
        Row(children: [
          contact(Icons.phone_rounded, 'اتصال', () => contactSheet(context, 'خدمة العملاء', '+249 912 000 000'), kRed),
          contact(Icons.chat_rounded, 'واتساب', () => contactSheet(context, 'واتساب الدعم', '+249 912 000 000', icon: Icons.chat_rounded), kGreen),
          contact(Icons.mail_rounded, 'بريد', () => contactSheet(context, 'البريد الإلكتروني', 'support@tabibak.sd', icon: Icons.mail_rounded), kBlue),
        ]),
        sec('الأسئلة الشائعة'),
        if (idx.isEmpty) panel([Center(child: Text('لا توجد نتائج مطابقة', style: t(13, w: FontWeight.w500, c: kGrey)))]),
        for (final i in idx)
          Tap(
            scale: .99,
            onTap: () => setState(() {
              if (open.contains(i)) {
                open.remove(i);
              } else {
                open.add(i);
              }
            }),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: cardBox(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(kFaqs[i].$1, style: t(13.5))), Icon(open.contains(i) ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: kRed)]),
                  if (open.contains(i)) ...[gap(8), Text(kFaqs[i].$2, style: t(12.5, w: FontWeight.w500, c: kSub, h: 1.7))],
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});
  @override
  State<SupportChatScreen> createState() => _SupportChatState();
}

class _SupportChatState extends State<SupportChatScreen> {
  final ctl = TextEditingController();
  final sc = ScrollController();
  final msgs = <(bool, String)>[(false, 'مرحباً بك في دعم طبيبك. كيف يمكنني مساعدتك اليوم؟')];
  Timer? timer;
  bool typing = false;

  @override
  void dispose() {
    timer?.cancel();
    ctl.dispose();
    sc.dispose();
    super.dispose();
  }

  void toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (sc.hasClients) sc.animateTo(sc.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  String answer(String q) {
    for (final f in kFaqs) {
      final words = f.$1.replaceAll('؟', '').split(' ').where((w) => w.length > 3);
      if (words.any((w) => q.contains(w))) return f.$2;
    }
    return 'تم استلام رسالتك، وسيرد عليك أحد ممثلي الدعم خلال دقائق.';
  }

  void send([String? text]) {
    final q = (text ?? ctl.text).trim();
    if (q.isEmpty) return;
    ctl.clear();
    setState(() {
      msgs.add((true, q));
      typing = true;
    });
    toEnd();
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        typing = false;
        msgs.add((false, answer(q)));
      });
      toEnd();
    });
  }

  Widget bubble((bool, String) m) => Align(
        alignment: m.$1 ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: m.$1 ? kGradient : null,
            color: m.$1 ? null : Colors.white,
            borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(m.$1 ? 18 : 4), bottomRight: Radius.circular(m.$1 ? 4 : 18)),
            boxShadow: kShadow,
          ),
          child: Text(m.$2, style: t(13, w: FontWeight.w500, c: m.$1 ? Colors.white : kInk, h: 1.6)),
        ),
      );

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'دعم طبيبك',
        body: Column(children: [
          Expanded(
            child: ListView(controller: sc, padding: const EdgeInsets.all(16), children: [
              for (final m in msgs) bubble(m),
              if (typing) bubble((false, '... جارٍ الكتابة')),
            ]),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kFaqs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Tap(onTap: () => send(kFaqs[i].$1), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)), child: Text(kFaqs[i].$1, style: t(12, w: FontWeight.w600, c: kSub)))),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
            color: Colors.white,
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(22)),
                  child: TextField(controller: ctl, onSubmitted: (_) => send(), style: t(13.5, w: FontWeight.w500), decoration: InputDecoration(border: InputBorder.none, hintText: 'اكتب رسالتك...', hintStyle: t(13, w: FontWeight.w500, c: kGrey), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
                ),
              ),
              gapW(10),
              Tap(onTap: send, child: Container(width: 46, height: 46, decoration: BoxDecoration(gradient: kGradient, shape: BoxShape.circle, boxShadow: kGlow), child: const Icon(Icons.send_rounded, color: Colors.white, size: 21, textDirection: TextDirection.ltr))),
            ]),
          ),
        ]),
      );
}

// ───────────────────────── 23. Medical records ─────────────────────────
Future<void> fakeDownload(BuildContext c, String name) async {
  showDialog<void>(context: c, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: kRed)));
  await Future.delayed(const Duration(milliseconds: 1100));
  if (!c.mounted) return;
  Navigator.pop(c);
  snack(c, 'تم تحميل «$name»', ok: true);
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          final last = app.appts.where((a) => a.status == 'مكتمل').toList();
          return RedPage(
            title: 'السجل الطبي',
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                for (final s in [('فصيلة الدم', app.blood.isEmpty ? '—' : app.blood, Icons.bloodtype_rounded), ('الجنس', app.gender.isEmpty ? '—' : app.gender, Icons.person_rounded), ('الزيارات', '${last.length}', Icons.event_available_rounded)])
                  Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 14), decoration: cardBox(20), child: Column(children: [Icon(s.$3, color: kRed, size: 22), gap(6), Text(s.$2, style: t(16)), Text(s.$1, style: t(11, w: FontWeight.w500, c: kGrey))]))),
              ]),
              gap(14),
              group([
                menuRow(Icons.science_rounded, 'نتائج التحاليل', trailing: cnt('3'), onTap: () => go(c, const LabResultsScreen())),
                menuRow(Icons.medication_rounded, 'الوصفات الطبية', trailing: cnt('${kRx.length}'), onTap: () => go(c, const PrescriptionsScreen())),
                menuRow(Icons.description_rounded, 'التقارير الطبية', trailing: cnt('${kReports.length}'), onTap: () => go(c, const MedReportsScreen())),
              ]),
              if (last.isNotEmpty) ...[
                sec('آخر زيارة'),
                Tap(
                  onTap: () => go(c, AppointmentDetailsScreen(last.first)),
                  scale: .98,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: cardBox(20),
                    child: Row(children: [
                      last.first.doctor != null ? Pic(last.first.doctor!.img, size: 52, radius: 16, label: last.first.title) : gTile(last.first.icon, size: 52, color: kindColor(last.first.kind)),
                      gapW(12),
                      Expanded(child: two(last.first.title, '${last.first.sub.split(' · ').first} · ${last.first.day}')),
                      chev(kGrey, 20),
                    ]),
                  ),
                ),
              ],
            ]),
          );
        },
      );
}

const kRx = [
  ('د. أحمد محمد علي', 'باطنية', ['ميتفورمين 500 مجم — مرتان يومياً بعد الأكل', 'أملوديبين 5 مجم — مرة صباحاً', 'فيتامين D — حبة أسبوعياً']),
  ('د. حسن محمود', 'أطفال', ['باراسيتامول شراب — 5 مل كل 6 ساعات عند الحمى', 'محلول معالجة الجفاف — بعد كل إسهال']),
];

const kReports = [
  ('تقرير الفحص الشامل', 'د. أحمد محمد علي', 'تقرير يلخص الفحص السريري ونتائج التحاليل مع التوصيات العامة للمتابعة.'),
  ('تقرير متابعة الضغط والسكر', 'د. أحمد محمد علي', 'قراءات الضغط والسكر خلال الأسابيع الأخيرة ضمن الحدود المقبولة مع الاستمرار على العلاج.'),
  ('تقرير رعاية الطفل', 'د. حسن محمود', 'النمو والتطعيمات مكتملة للعمر، مع توصية بمتابعة التغذية.'),
];

class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'الوصفات الطبية',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final r in kRx)
            panel([
              Row(children: [tileIcon(Icons.medication_rounded, size: 44), gapW(12), Expanded(child: two(r.$1, r.$2))]),
              const Divider(color: kLine, height: 24),
              for (final m in r.$3) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 7, color: kRed)), gapW(10), Expanded(child: Text(m, style: t(12.5, w: FontWeight.w500, c: kSub, h: 1.6)))])),
              gap(10),
              OutBtn('نسخ الوصفة', icon: Icons.content_copy_rounded, height: 42, onTap: () {
                Clipboard.setData(ClipboardData(text: '${r.$1}\n${r.$3.join('\n')}'));
                snack(context, 'تم نسخ الوصفة', ok: true);
              }),
            ]),
        ]),
      );
}

class MedReportsScreen extends StatelessWidget {
  const MedReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'التقارير الطبية',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final r in kReports)
            Tap(
              scale: .98,
              onTap: () => sheet(
                context,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [tileIcon(Icons.picture_as_pdf_rounded, size: 46), gapW(12), Expanded(child: two(r.$1, r.$2))]),
                  gap(14),
                  Text(r.$3, style: t(13, w: FontWeight.w500, c: kSub, h: 1.8)),
                  gap(18),
                  Builder(builder: (ctx) => RedButton('تحميل PDF', icon: Icons.download_rounded, onTap: () {
                        Navigator.pop(ctx);
                        fakeDownload(context, r.$1);
                      })),
                ]),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: cardBox(20),
                child: Row(children: [tileIcon(Icons.picture_as_pdf_rounded, size: 46), gapW(12), Expanded(child: two(r.$1, r.$2)), chev(kGrey, 20)]),
              ),
            ),
        ]),
      );
}

class LabResultsScreen extends StatelessWidget {
  const LabResultsScreen({super.key});
  static const rows = [
    ('الهيموجلوبين', '13.5', 'g/dL', 'طبيعي', true),
    ('كريات الدم البيضاء', '7,200', '/µL', 'طبيعي', true),
    ('السكر الصائم', '118', 'mg/dL', 'مرتفع قليلاً', false),
    ('الصفائح الدموية', '250,000', '/µL', 'طبيعي', true),
  ];
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'نتائج التحاليل',
        bottomBar: btnBar(context, 'تحميل PDF', () => fakeDownload(context, 'نتائج التحاليل'), icon: Icons.download_rounded, alt: 'مشاركة (نسخ)', onAlt: () {
          Clipboard.setData(ClipboardData(text: rows.map((r) => '${r.$1}: ${r.$2} ${r.$3} (${r.$4})').join('\n')));
          snack(context, 'تم نسخ النتائج للمشاركة', ok: true);
        }),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          panel([Row(children: [gTile(Icons.science_rounded, size: 52, color: kTeal), gapW(12), Expanded(child: two('صورة دم كاملة + سكر', app.appts.firstWhere((a) => a.kind == 3, orElse: () => app.appts.first).day)), pillOk('جاهزة')])]),
          panel([
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(color: kLine, height: 22),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(rows[i].$1, style: t(13.5)), Directionality(textDirection: TextDirection.ltr, child: Text('${rows[i].$2} ${rows[i].$3}', style: t(12, w: FontWeight.w500, c: kGrey)))])),
                rows[i].$5 ? pillOk(rows[i].$4) : pillWarn(rows[i].$4),
              ]),
            ],
          ]),
        ]),
      );
}

// ───────────────────────── 24. Family ─────────────────────────
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  Widget card(BuildContext c, String name, String rel, String sub, {Member? m}) => Tap(
        scale: .98,
        onTap: () => sheet(
          c,
          Column(children: [
            Container(width: 70, height: 70, alignment: Alignment.center, decoration: const BoxDecoration(color: kTint, shape: BoxShape.circle), child: Text(initial(name), style: t(28, c: kRed))),
            gap(10),
            Text(name, style: t(17)),
            Text('$rel · $sub', style: t(12.5, w: FontWeight.w500, c: kGrey)),
            gap(18),
            Builder(builder: (ctx) => RedButton('احجز لهذا الفرد', icon: Icons.event_available_rounded, onTap: () {
                  Navigator.pop(ctx);
                  go(c, const DoctorListScreen());
                })),
            if (m != null) ...[
              gap(10),
              Builder(builder: (ctx) => OutBtn('حذف من العائلة', danger: true, icon: Icons.delete_outline_rounded, onTap: () {
                    Navigator.pop(ctx);
                    app.family.remove(m);
                    app.ping();
                    snack(c, 'تم حذف ${m.name}');
                  })),
            ],
          ]),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: cardBox(20),
          child: Row(children: [
            Container(width: 50, height: 50, alignment: Alignment.center, decoration: const BoxDecoration(color: kTint, shape: BoxShape.circle), child: Text(initial(name), style: t(21, c: kRed))),
            gapW(12),
            Expanded(child: two(name, '$rel · $sub')),
            chev(kGrey, 20),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) => RedPage(
          title: 'أفراد العائلة',
          bottomBar: btnBar(c, 'إضافة فرد جديد', () => go(c, const AddMemberScreen()), icon: Icons.person_add_alt_1_rounded),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            card(c, app.name, 'الحساب الرئيسي', 'أنت'),
            for (final m in app.family) card(c, m.name, m.rel, '${m.age} سنة', m: m),
          ]),
        ),
      );
}

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});
  @override
  State<AddMemberScreen> createState() => _AddMemberState();
}

class _AddMemberState extends State<AddMemberScreen> {
  static const rels = ['الزوج / الزوجة', 'ابن', 'ابنة', 'أب', 'أم', 'أخ', 'أخت', 'آخر'];
  final nm = TextEditingController(), dob = TextEditingController();
  int rel = 1;
  String? eName, eDob;

  @override
  void dispose() {
    nm.dispose();
    dob.dispose();
    super.dispose();
  }

  void save() {
    setState(() {
      eName = nm.text.trim().length < 3 ? 'أدخل اسم الفرد' : null;
      eDob = dob.text.isEmpty ? 'اختر تاريخ الميلاد' : null;
    });
    if (eName != null || eDob != null) return;
    final y = int.tryParse(dob.text.split('/').last.trim()) ?? DateTime.now().year;
    app.family.add(Member(nm.text.trim(), rels[rel], DateTime.now().year - y));
    app.ping();
    Navigator.pop(context);
    snack(context, 'تمت إضافة ${nm.text.trim()}', ok: true);
  }

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'إضافة فرد',
        bottomBar: btnBar(context, 'حفظ', save),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
          AppField('الاسم الكامل', controller: nm, hint: 'اسم الفرد', icon: Icons.person_outline_rounded, error: eName),
          AppField('تاريخ الميلاد', controller: dob, hint: 'يوم / شهر / سنة', icon: Icons.calendar_today_outlined, readOnly: true, error: eDob, onTap: () async {
            final v = await pickDob(context);
            if (v != null && mounted) setState(() => dob.text = v);
          }),
          sec('صلة القرابة'),
          ChipWrap(rels, sel: {rel}, onChanged: (s) => rel = s.first),
        ]),
      );
}

// ───────────────────────── 25. Addresses ─────────────────────────
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) => RedPage(
          title: 'عناويني',
          bottomBar: btnBar(c, 'إضافة عنوان جديد', () => go(c, const AddAddressScreen()), icon: Icons.add_location_alt_rounded),
          body: app.addrs.isEmpty
              ? EmptyState(Icons.location_off_rounded, 'لا توجد عناوين', 'أضف عنواناً لتسهيل طلب الخدمات المنزلية والإسعاف.', btn: 'إضافة عنوان', onTap: () => go(c, const AddAddressScreen()))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  Text('اضغط على العنوان لاختياره كعنوان افتراضي', style: t(12, w: FontWeight.w500, c: kGrey)),
                  gap(10),
                  for (var i = 0; i < app.addrs.length; i++)
                    Tap(
                      scale: .98,
                      onTap: () {
                        app.selAddr = i;
                        app.ping();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: app.selAddr == i ? const Color(0xFFFFF5F6) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: app.selAddr == i ? kRed : kLine, width: 1.5)),
                        child: Row(children: [
                          tileIcon(app.addrs[i].icon, size: 46),
                          gapW(12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(app.addrs[i].label, style: t(14.5)), Text(app.addrs[i].line, style: t(12, w: FontWeight.w500, c: kSub)), if (app.addrs[i].note.isNotEmpty) Text(app.addrs[i].note, style: t(11, w: FontWeight.w500, c: kGrey))])),
                          if (app.selAddr == i) const Icon(Icons.check_circle_rounded, color: kRed),
                          InkWell(
                            onTap: () async {
                              final ok = await confirm(c, 'حذف العنوان؟', 'سيتم حذف «${app.addrs[i].label}» من عناوينك.', yes: 'حذف');
                              if (!ok) return;
                              app.addrs.removeAt(i);
                              if (app.selAddr >= app.addrs.length) app.selAddr = 0;
                              app.ping();
                            },
                            child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.delete_outline_rounded, color: kGrey)),
                          ),
                        ]),
                      ),
                    ),
                ]),
        ),
      );
}

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});
  @override
  State<AddAddressScreen> createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddressScreen> {
  static const labels = ['المنزل', 'العمل', 'آخر'];
  static const icons = [Icons.home_rounded, Icons.work_rounded, Icons.place_rounded];
  final line = TextEditingController(), note = TextEditingController();
  int label = 0;
  String? eLine;

  @override
  void dispose() {
    line.dispose();
    note.dispose();
    super.dispose();
  }

  void save() {
    if (line.text.trim().length < 4) {
      setState(() => eLine = 'أدخل العنوان (الحي - الشارع)');
      return;
    }
    app.addrs.add(Addr(labels[label], line.text.trim(), note.text.trim(), icons[label]));
    app.selAddr = app.addrs.length - 1;
    app.ping();
    Navigator.pop(context);
    snack(context, 'تمت إضافة العنوان', ok: true);
  }

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'إضافة عنوان',
        bottomBar: btnBar(context, 'حفظ العنوان', save),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
          sec('نوع العنوان'),
          ChipWrap(labels, onChanged: (s) => label = s.first),
          AppField('العنوان', controller: line, hint: 'المدينة - الحي - الشارع', icon: Icons.location_on_outlined, error: eLine, onChanged: (_) {
            if (eLine != null) setState(() => eLine = null);
          }),
          AppField('ملاحظات للوصول (اختياري)', controller: note, hint: 'معلم قريب، رقم المنزل...', icon: Icons.sticky_note_2_outlined, lines: 2),
        ]),
      );
}

// ───────────────────────── 26. Offers & payments ─────────────────────────
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});
  static const offers = [
    ('خصم 20% على أول كشف', 'يُطبّق على رسوم الكشف عند حجز أي طبيب.', 'TABIBAK20', kRed),
    ('خصم 10% ترحيبي', 'للمستخدمين الجدد على أي حجز طبيب.', 'WELCOME10', kTeal),
  ];
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'العروض والكوبونات',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final o in offers)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              clipBehavior: Clip.antiAlias,
              decoration: cardBox(24),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: grad(o.$4)),
                  child: Row(children: [const Icon(Icons.local_offer_rounded, color: Colors.white, size: 34), gapW(12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o.$1, style: t(16, c: Colors.white)), Text(o.$2, style: t(11.5, w: FontWeight.w500, c: const Color(0xE6FFFFFF)))]))]),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 11), alignment: Alignment.center, decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)), child: Text(o.$3, style: t(15, c: kInk)))),
                    gapW(10),
                    SizedBox(
                      width: 100,
                      child: RedButton('نسخ', height: 44, onTap: () {
                        Clipboard.setData(ClipboardData(text: o.$3));
                        snack(context, 'تم نسخ الكود ${o.$3}', ok: true);
                      }),
                    ),
                  ]),
                ),
              ]),
            ),
          panel([Text('كيف أستخدم الكود؟', style: t(14.5)), gap(6), Text('انسخ الكود ثم الصقه في خانة «كود الخصم» في صفحة الدفع عند حجز طبيب.', style: t(12.5, w: FontWeight.w500, c: kSub, h: 1.7))]),
        ]),
      );
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (c, _) {
          final l = app.appts.where((a) => a.price > 0 && a.status != 'ملغي').toList();
          final sum = l.fold<int>(0, (s, a) => s + a.price);
          return RedPage(
            title: 'المدفوعات والفواتير',
            body: l.isEmpty
                ? const EmptyState(Icons.receipt_long_rounded, 'لا توجد مدفوعات', 'ستظهر هنا فواتير حجوزاتك.')
                : ListView(padding: const EdgeInsets.all(16), children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(24), boxShadow: kGlow),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('إجمالي المدفوعات', style: t(12.5, w: FontWeight.w500, c: const Color(0xE6FFFFFF))), Text('${money(sum)} ج.س', style: t(26, c: Colors.white))])),
                        const Icon(Icons.account_balance_wallet_rounded, color: Color(0x80FFFFFF), size: 44),
                      ]),
                    ),
                    gap(14),
                    for (final a in l)
                      Tap(
                        scale: .98,
                        onTap: () => go(c, AppointmentDetailsScreen(a)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: cardBox(18),
                          child: Row(children: [
                            tileIcon(a.icon, size: 44, color: kindColor(a.kind), bg: kindColor(a.kind).withAlpha(28)),
                            gapW(12),
                            Expanded(child: two(a.title, '${a.day} · ${a.method.isEmpty ? '—' : a.method}')),
                            Text('${money(a.price)} ج.س', style: t(13.5)),
                          ]),
                        ),
                      ),
                  ]),
          );
        },
      );
}
