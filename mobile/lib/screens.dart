// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'constants.dart';
import 'api_service.dart';

// ════════════════════════════════════════════
// DESIGN SYSTEM — calqué sur app_theme.dart du zip
// ════════════════════════════════════════════

class AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color backgroundGreen = Color(0xFFF1F8F1);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF4A4A4A);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color brown = Color(0xFF795548);
  static const Color brownDark = Color(0xFF4E342E);
  static const Color statusVerified = Color(0xFF43A047);
  static const Color statusPending = Color(0xFFFB8C00);
  static const Color statusRejected = Color(0xFFE53935);
  static const Color pink = Color(0xFFFFF3F3);
}

// ════════════════════════════════════════════
// WIDGETS PARTAGÉS
// ════════════════════════════════════════════

class GreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GreenAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'GREENSPACE',
            style: TextStyle(
              color: AppColors.brown,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textMedium),
          onPressed: () {},
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: const CircleAvatar(
            backgroundColor: AppColors.primaryGreen,
            radius: 18,
            child: Icon(Icons.person, color: AppColors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

class GreenButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;

  const GreenButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = AppColors.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statutColor(String s) => switch (s) {
      'CONFORME' || 'EXPORTE' => AppColors.statusVerified,
      'REFUSE' => AppColors.statusRejected,
      _ => AppColors.statusPending,
    };

class LotCard extends StatelessWidget {
  final Map<String, dynamic> lot;
  final VoidCallback? onTransferer;

  const LotCard(this.lot, {super.key, this.onTransferer});

  @override
  Widget build(BuildContext context) {
    final statut = lot['statut']?.toString() ?? '';
    final color = _statutColor(statut);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lot['id_lot']?.toString() ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              _StatusBadge(
                label: lot['conforme_eudr'] == true ? 'Conforme' : statut,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.scale_outlined, size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text('${lot['poids_kg']} kg',
                style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
            const SizedBox(width: 14),
            const Icon(Icons.eco_outlined, size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text(lot['type_culture']?.toString() ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _OutlineBtn(
                label: 'Détails',
                color: AppColors.primaryGreen,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilledBtn(
                label: 'Transférer →',
                color: AppColors.brown,
                onTap: onTransferer,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _FilledBtn({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _OutlineBtn({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

class StatCard extends StatelessWidget {
  final String value, label, trend;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (trend.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusVerified.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(trend,
                          style: const TextStyle(
                              color: AppColors.statusVerified,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _CounterBadge extends StatelessWidget {
  final String value, label;
  final Color color;

  const _CounterBadge({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: color)),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMedium))),
            ],
          ),
        ),
      );
}

class _ZoneBar extends StatelessWidget {
  final String zone;
  final double valeur;

  const _ZoneBar(this.zone, this.valeur);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(zone,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                Text('${valeur.toStringAsFixed(0)} kts',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (valeur / 600).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ),
          ],
        ),
      );
}

Widget buildBottomNav(BuildContext context, int current, String role) {
  final items = <Map<String, dynamic>>[
    {'icon': Icons.home_outlined, 'label': 'Accueil'},
    if (role == 'AGRICULTEUR') ...[
      {'icon': Icons.grass_outlined, 'label': 'Agriculture'},
      {'icon': Icons.verified_outlined, 'label': 'Vérifier'},
    ],
    if (role == 'COOPERATIVE') ...[
      {'icon': Icons.inventory_2_outlined, 'label': 'Lots'},
      {'icon': Icons.swap_horiz, 'label': 'Transferts'},
    ],
    if (role == 'EXPORTATEUR') ...[
      {'icon': Icons.local_shipping_outlined, 'label': 'Exports'},
      {'icon': Icons.qr_code, 'label': 'EUDR'},
    ],
    if (role == 'VERIFICATEUR') ...[
      {'icon': Icons.qr_code_scanner, 'label': 'Scanner'},
      {'icon': Icons.check_circle_outline, 'label': 'Valider'},
    ],
    if (role == 'ADMIN') ...[
      {'icon': Icons.bar_chart_outlined, 'label': 'Statistiques'},
      {'icon': Icons.map_outlined, 'label': 'Zones'},
    ],
    {'icon': Icons.person_outline, 'label': 'Profil'},
  ];

  return Container(
    decoration: const BoxDecoration(
      color: AppColors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 16,
          offset: Offset(0, -3),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 62,
        child: Row(
          children: items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final selected = i == current;
            return Expanded(
              child: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 36 : 0,
                      height: selected ? 3 : 0,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      item['icon'] as IconData,
                      size: 22,
                      color: selected ? AppColors.primaryGreen : AppColors.textLight,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        color: selected ? AppColors.primaryGreen : AppColors.textLight,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════
// 1. HOME — Splash / Accueil
// ════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundGreen, Color(0xFFC8E6C9)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.white.withOpacity(0.3),
                              ),
                              child: const Center(child: Text('🍫', style: TextStyle(fontSize: 72))),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'GREENSPACE',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brown,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Traçabilité cacao · Togo',
                              style: TextStyle(color: AppColors.textMedium, fontSize: 15),
                            ),
                            const SizedBox(height: 56),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/role-selection'),
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryGreenDark.withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "S'inscrire",
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/connexion'),
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// 2. SÉLECTION DU RÔLE
// ════════════════════════════════════════════
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundGreen, Color(0xFFBBDEBB)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.eco, color: AppColors.primaryGreen, size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'GREENSPACE',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brown,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreenDark.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'VOTRE PROFIL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...kRoles.entries.map((e) => _RoleTile(
                                  role: e.key,
                                  label: e.value['label'] as String,
                                  icon: e.value['icon'] as IconData,
                                  onTap: () => Navigator.pushNamed(context, '/inscription',
                                      arguments: e.key),
                                )),
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/connexion'),
                              child: const Text(
                                'Déjà un compte ? Se connecter',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String role, label;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// 3. INSCRIPTION
// ════════════════════════════════════════════
class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});
  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _tel = TextEditingController();
  final _region = TextEditingController();
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  bool _loading = false;

  Future<void> _inscrire(String role) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.inscription({
        'username': _email.text.split('@').first,
        'email': _email.text,
        'first_name': _prenom.text,
        'last_name': _nom.text,
        'password': _mdp.text,
        'role': role,
        'telephone': _tel.text,
        'region': _region.text,
      });
      if (mounted) _redirectByRole(res['user']['role'] as String);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _redirectByRole(String role) {
    final routes = {
      'AGRICULTEUR': '/dashboard-agriculteur',
      'EXPORTATEUR': '/gestion-exports',
      'VERIFICATEUR': '/verification',
      'TRANSFORMATEUR': '/validation-lots',
      'COOPERATIVE': '/gestion-lots',
      'ADMIN': '/dashboard-national',
    };
    Navigator.pushReplacementNamed(context, routes[role] ?? '/home');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.statusRejected,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  @override
  Widget build(BuildContext context) {
    final role = ModalRoute.of(context)?.settings.arguments as String? ?? 'AGRICULTEUR';
    final roleInfo = kRoles[role]!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundGreen, Color(0xFFBBDEBB)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _form,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  size: 16, color: AppColors.textDark),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.eco,
                                    color: AppColors.primaryGreen, size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text('GREENSPACE',
                                  style: TextStyle(
                                      color: AppColors.brown,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15)),
                            ],
                          ),
                          const Spacer(),
                          const SizedBox(width: 36),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreenDark.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "PAGE D'INSCRIPTION",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(roleInfo['icon'] as IconData, color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  roleInfo['label'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _field(_prenom, 'Votre prénom', Icons.person_outline),
                            const SizedBox(height: 12),
                            _field(_nom, 'Votre nom', Icons.badge_outlined),
                            const SizedBox(height: 12),
                            _field(_email, 'Votre email', Icons.email_outlined,
                                type: TextInputType.emailAddress),
                            const SizedBox(height: 12),
                            _field(_tel, 'Votre téléphone', Icons.phone_outlined,
                                type: TextInputType.phone),
                            const SizedBox(height: 12),
                            _field(_region, 'Votre région', Icons.location_on_outlined),
                            const SizedBox(height: 12),
                            _field(_mdp, 'Votre mot de passe', Icons.lock_outline, obscure: true),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: _loading ? null : () => _inscrire(role),
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.brown,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brownDark.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : const Text(
                                          "S'inscrire",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text, bool obscure = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primaryGreen),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryGreenLight, width: 1.5),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
    );
  }
}

// ════════════════════════════════════════════
// 4. CONNEXION
// ════════════════════════════════════════════
class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});
  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _connect() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.connexion(_user.text, _pass.text);
      final role = res['user']['role'] as String;
      if (!mounted) return;
      final routes = {
        'AGRICULTEUR': '/dashboard-agriculteur',
        'EXPORTATEUR': '/gestion-exports',
        'VERIFICATEUR': '/verification',
        'TRANSFORMATEUR': '/validation-lots',
        'COOPERATIVE': '/gestion-lots',
        'ADMIN': '/dashboard-national',
      };
      Navigator.pushReplacementNamed(context, routes[role] ?? '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.statusRejected,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundGreen, Color(0xFFBBDEBB)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/role-selection'),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                size: 16, color: AppColors.textDark),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.lightGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.eco,
                                  color: AppColors.primaryGreen, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text('GREENSPACE',
                                style: TextStyle(
                                    color: AppColors.brown,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15)),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 36),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreenDark.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'PAGE DE CONNEXION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _LoginInput(
                              controller: _user,
                              hint: 'Votre identifiant',
                              icon: Icons.person_outline),
                          const SizedBox(height: 12),
                          _LoginInput(
                              controller: _pass,
                              hint: 'Mot de passe',
                              icon: Icons.lock_outline,
                              obscure: true),
                          const SizedBox(height: 28),
                          GestureDetector(
                            onTap: _loading ? null : _connect,
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.brown,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brownDark.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/role-selection'),
                            child: const Text(
                              "Pas encore de compte ? S'inscrire",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;

  const _LoginInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primaryGreen),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryGreenLight, width: 1.5),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// 5. DASHBOARD NATIONAL (Admin)
// ════════════════════════════════════════════
class DashboardNationalScreen extends StatefulWidget {
  const DashboardNationalScreen({super.key});
  @override
  State<DashboardNationalScreen> createState() => _DashboardNationalState();
}

class _DashboardNationalState extends State<DashboardNationalScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getDashboardNational();
      setState(() {
        _data = Map<String, dynamic>.from(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: const GreenAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _data == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, size: 48, color: AppColors.textLight.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('Impossible de charger les données',
                          style: TextStyle(color: AppColors.textLight)),
                    ],
                  ))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primaryGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.dashboard_outlined,
                                    color: AppColors.primaryGreen, size: 22),
                              ),
                              const SizedBox(width: 14),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dashboard National',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    "Ministère de l'Agriculture · Togo",
                                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          StatCard(
                            value: '${_data!['total_lots']}',
                            label: 'Lots enregistrés',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.primaryGreen,
                            trend: '+4%',
                          ),
                          const SizedBox(width: 12),
                          StatCard(
                            value: '${_data!['total_certifications']}',
                            label: 'Certifications',
                            icon: Icons.verified_outlined,
                            color: AppColors.brown,
                            trend: '+8%',
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          StatCard(
                            value: '${_data!['total_agriculteurs']}',
                            label: 'Agriculteurs',
                            icon: Icons.grass_outlined,
                            color: AppColors.primaryGreenDark,
                            trend: '+2%',
                          ),
                          const SizedBox(width: 12),
                          StatCard(
                            value: '${_data!['total_cooperatives']}',
                            label: 'Coopératives',
                            icon: Icons.groups,
                            color: AppColors.textMedium,
                            trend: '',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: '📍 Zones de production',
                          child: Column(
                            children: (_data!['zones_production'] as Map<String, dynamic>)
                                .entries
                                .map((e) => _ZoneBar(e.key, (e.value as num).toDouble()))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: '🌍 Impact social & économique',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ImpactTile(
                                value: '${_data!['total_agriculteurs']}',
                                label: 'Agriculteurs',
                                color: AppColors.primaryGreen,
                              ),
                              _ImpactTile(
                                value: '${_data!['pc_conforme_eudr']}%',
                                label: 'EUDR Conf.',
                                color: AppColors.statusVerified,
                              ),
                              const _ImpactTile(
                                value: '0%',
                                label: 'Litiges',
                                color: AppColors.statusRejected,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: buildBottomNav(context, 0, 'ADMIN'),
    );
  }
}

class _ImpactTile extends StatelessWidget {
  final String value, label;
  final Color color;

  const _ImpactTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 3),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ════════════════════════════════════════════
// 6. ENREGISTRER UN LOT (Agriculteur)
// ════════════════════════════════════════════
class EnregistrerLotScreen extends StatefulWidget {
  const EnregistrerLotScreen({super.key});
  @override
  State<EnregistrerLotScreen> createState() => _EnregistrerLotState();
}

class _EnregistrerLotState extends State<EnregistrerLotScreen> {
  final _form = GlobalKey<FormState>();
  String _culture = 'CACAO';
  final _poids = TextEditingController();
  final _gps = TextEditingController();
  DateTime? _dateRecolte;
  bool _loading = false;
  bool _gpsLoading = false;

  Future<void> _getLocation() async {
    setState(() => _gpsLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    _gps.text = '6.1319, 1.2228';
    setState(() => _gpsLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Position obtenue ✓'),
          backgroundColor: AppColors.statusVerified,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate() || _dateRecolte == null) return;
    setState(() => _loading = true);
    try {
      final parts = _gps.text.split(',');
      await ApiService.creerLot({
        'type_culture': _culture,
        'poids_kg': _poids.text,
        'latitude': parts[0].trim(),
        'longitude': parts[1].trim(),
        'date_recolte': _dateRecolte!.toIso8601String().split('T').first,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Lot enregistré avec succès ✓'),
            backgroundColor: AppColors.statusVerified,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.statusRejected,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: const Text('Enregistrer un lot',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text('🌾', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouveau lot de récolte',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        ),
                        Text(
                          'Traçabilité EUDR · Togo',
                          style: TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                icon: '📍',
                title: 'Géolocalisation',
                child: Column(
                  children: [
                    GreenButton(
                      label: _gpsLoading ? 'Chargement...' : 'Obtenir ma position',
                      icon: Icons.my_location,
                      onTap: _gpsLoading ? null : _getLocation,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _gps,
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Coordonnées GPS',
                        filled: true,
                        fillColor: AppColors.backgroundGreen,
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            color: AppColors.primaryGreen, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FormSection(
                icon: '⚖️',
                title: 'Poids du lot (kg)',
                child: TextFormField(
                  controller: _poids,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Ex.: 50',
                    suffixText: 'kg',
                    filled: true,
                    fillColor: AppColors.backgroundGreen,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              ),
              const SizedBox(height: 12),
              _FormSection(
                icon: '🌿',
                title: 'Type de culture',
                child: Row(
                  children: ['CACAO', 'CAFE'].map((c) {
                    final selected = c == _culture;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _culture = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primaryGreen : AppColors.backgroundGreen,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: selected ? AppColors.primaryGreen : AppColors.divider),
                          ),
                          child: Text(
                            c == 'CACAO' ? '🍫 Cacao' : '☕ Café',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? AppColors.white : AppColors.textMedium,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _FormSection(
                icon: '📅',
                title: 'Date de récolte',
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _dateRecolte = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppColors.primaryGreen, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _dateRecolte == null
                              ? 'jj/mm/aaaa'
                              : '${_dateRecolte!.day}/${_dateRecolte!.month}/${_dateRecolte!.year}',
                          style: TextStyle(
                              color: _dateRecolte == null ? AppColors.textLight : AppColors.textDark,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _loading ? null : _enregistrer,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.brown,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brownDark.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Enregistrer le lot',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String icon, title;
  final Widget child;

  const _FormSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

// ════════════════════════════════════════════
// 7. VÉRIFICATION TRACABILITÉ (Scanner QR)
// ════════════════════════════════════════════
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});
  @override
  State<VerificationScreen> createState() => _VerificationState();
}

class _VerificationState extends State<VerificationScreen> {
  final _idCtrl = TextEditingController();
  Map<String, dynamic>? _lot;
  bool _scanning = false;
  bool _loading = false;

  Future<void> _rechercher(String idLot) async {
    setState(() {
      _loading = true;
      _lot = null;
    });
    try {
      final data = await ApiService.scannerLot(idLot);
      setState(() {
        _lot = Map<String, dynamic>.from(data);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.statusRejected,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: const GreenAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Text('🔍', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vérification Traçabilité',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      Text(
                        "Scannez le QR code ou entrez l'ID du lot",
                        style: TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'ID du lot',
              child: Column(
                children: [
                  TextFormField(
                    controller: _idCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'LOT-TG-2026-XXXX',
                      filled: true,
                      fillColor: AppColors.backgroundGreen,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GreenButton(
                    label: 'Rechercher',
                    icon: Icons.search,
                    onTap: () => _rechercher(_idCtrl.text),
                  ),
                  const SizedBox(height: 8),
                  GreenButton(
                    label: _scanning ? 'Mode scan actif' : 'Scanner un QR Code',
                    icon: Icons.qr_code_scanner,
                    color: _scanning ? AppColors.statusVerified : AppColors.primaryGreenDark,
                    onTap: () => setState(() => _scanning = !_scanning),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_scanning)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 240,
                  child: MobileScanner(
                    onDetect: (BarcodeCapture capture) {
                      final code = capture.barcodes.firstOrNull?.rawValue;
                      if (code != null) {
                        setState(() => _scanning = false);
                        _rechercher(code);
                      }
                    },
                  ),
                ),
              ),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primaryGreen)),
            if (_lot != null) ...[
              const SizedBox(height: 16),
              _LotDetailCard(lot: _lot!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNav(context, 0, 'VERIFICATEUR'),
    );
  }
}

class _LotDetailCard extends StatelessWidget {
  final Map<String, dynamic> lot;

  const _LotDetailCard({required this.lot});

  @override
  Widget build(BuildContext context) {
    final conforme = lot['conforme_eudr'] == true;
    final color = conforme ? AppColors.statusVerified : AppColors.statusPending;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(lot['id_lot']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
            _StatusBadge(label: conforme ? 'Conforme EUDR' : 'En attente', color: color),
          ]),
          const Divider(height: 20, color: AppColors.divider),
          _row('Agriculteur', lot['agriculteur_nom']?.toString() ?? '-'),
          _row('Type culture', lot['type_culture']?.toString() ?? '-'),
          _row('Poids', '${lot['poids_kg']} kg'),
          _row('Date récolte', lot['date_recolte']?.toString() ?? '-'),
          if ((lot['transferts'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            const Text('Historique des transferts',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
            ...(lot['transferts'] as List).map((t) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.arrow_forward, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(
                        '${t['role_destinataire']} · ${t['poids_kg']} kg',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ]),
                )),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark)),
          ],
        ),
      );
}

// ════════════════════════════════════════════
// 8. GESTION DES LOTS (Coopérative)
// ════════════════════════════════════════════
class GestionLotsScreen extends StatefulWidget {
  const GestionLotsScreen({super.key});
  @override
  State<GestionLotsScreen> createState() => _GestionLotsState();
}

class _GestionLotsState extends State<GestionLotsScreen> {
  List<dynamic> _lots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getLots();
      setState(() {
        _lots = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enAttente = _lots.where((l) => l['statut'] == 'ENREGISTRE').length;
    final enTransit = _lots.where((l) => l['statut'] == 'EN_TRANSIT').length;

    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: const GreenAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Text('🏛', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestion des lots',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                          Text('Coopérative agricole',
                              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _CounterBadge(
                    value: '$enAttente',
                    label: 'Lots en attente',
                    color: AppColors.statusPending,
                  ),
                  const SizedBox(width: 12),
                  _CounterBadge(
                    value: '$enTransit',
                    label: 'En transit',
                    color: AppColors.primaryGreen,
                  ),
                ]),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primaryGreen,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _lots.length,
                      itemBuilder: (_, i) => LotCard(
                        Map<String, dynamic>.from(_lots[i]),
                        onTransferer: () => _load(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNav(context, 0, 'COOPERATIVE'),
    );
  }
}

// ════════════════════════════════════════════
// 9. GESTION EXPORTS (Exportateur)
// ════════════════════════════════════════════
class GestionExportsScreen extends StatefulWidget {
  const GestionExportsScreen({super.key});
  @override
  State<GestionExportsScreen> createState() => _GestionExportsState();
}

class _GestionExportsState extends State<GestionExportsScreen> {
  List<dynamic> _lots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getLots();
      setState(() {
        _lots = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prets = _lots.where((l) => l['statut'] == 'EN_EXPORT').length;
    final totalKg = _lots.fold<double>(
        0, (s, l) => s + (double.tryParse(l['poids_kg'].toString()) ?? 0));

    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: const GreenAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Text('🚢', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestion des exports',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                          Text('Exportateur agréé',
                              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _CounterBadge(
                    value: '$prets',
                    label: 'Prêts à exporter',
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 12),
                  _CounterBadge(
                    value: '${totalKg.toStringAsFixed(0)} kg',
                    label: 'Total',
                    color: AppColors.brown,
                  ),
                ]),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primaryGreen,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _lots.length,
                      itemBuilder: (_, i) => _ExportCard(lot: Map<String, dynamic>.from(_lots[i])),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNav(context, 0, 'EXPORTATEUR'),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final Map<String, dynamic> lot;

  const _ExportCard({required this.lot});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lot['id_lot']?.toString() ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text('${lot['poids_kg']} kg · ${lot['type_culture']}',
                style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(
                child: _OutlineBtn(
                  label: 'Détails',
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.brown,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('Preuve EUDR',
                            style: TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      );
}