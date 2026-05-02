import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'constants.dart';
import 'api_service.dart';

// ════════════════════════════════════════════
// 1. HOME — Splash / Accueil
// ════════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreenLight,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 120, color: kGreen),
              const SizedBox(height: 24),
              const Text(
                'GREENSPACE',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: kBrown,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Traçabilité cacao · Togo',
                style: TextStyle(color: kGray, fontSize: 15),
              ),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/role-selection'),
                      child: const Text('S\'inscrire'),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/connexion'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      backgroundColor: kGreenLight,
      appBar: AppBar(
          title: const Text('Votre profil'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choisissez votre rôle',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kGreenDark)),
            const SizedBox(height: 8),
            const Text(
                'Votre rôle détermine vos accès sur la plateforme.',
                style: TextStyle(color: kGray)),
            const SizedBox(height: 28),
            ...kRoles.entries.map((e) => _RoleTile(
                  role: e.key,
                  label: e.value['label'] as String,
                  icon: e.value['icon'] as IconData,
                  onTap: () => Navigator.pushNamed(
                      context, '/inscription',
                      arguments: e.key),
                )),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/connexion'),
                child: const Text('Déjà un compte ? Se connecter',
                    style: TextStyle(color: kGreen)),
              ),
            )
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
  const _RoleTile(
      {required this.role,
      required this.label,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kGreenLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: kGreen, size: 22),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: kGray),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// 3. INSCRIPTION (par rôle)
// ════════════════════════════════════════════
class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});
  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _form    = GlobalKey<FormState>();
  final _nom     = TextEditingController();
  final _prenom  = TextEditingController();
  final _tel     = TextEditingController();
  final _region  = TextEditingController();
  final _email   = TextEditingController();
  final _mdp     = TextEditingController();
  bool _loading  = false;

  Future<void> _inscrire(String role) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.inscription({
        'username':   _email.text.split('@').first,
        'email':      _email.text,
        'first_name': _prenom.text,
        'last_name':  _nom.text,
        'password':   _mdp.text,
        'role':       role,
        'telephone':  _tel.text,
        'region':     _region.text,
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
      'AGRICULTEUR':    '/dashboard-agriculteur',
      'EXPORTATEUR':    '/gestion-exports',
      'VERIFICATEUR':   '/verification',
      'TRANSFORMATEUR': '/validation-lots',
      'COOPERATIVE':    '/gestion-lots',
      'ADMIN':          '/dashboard-national',
    };
    Navigator.pushReplacementNamed(context, routes[role] ?? '/home');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger));
  }

  @override
  Widget build(BuildContext context) {
    final role =
        ModalRoute.of(context)?.settings.arguments as String? ??
            'AGRICULTEUR';
    final roleInfo = kRoles[role]!;

    return Scaffold(
      backgroundColor: kGreenLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.eco, size: 60, color: kGreen),
                const Text('GREENSPACE',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: kBrown,
                        fontSize: 18)),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kGreenDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PAGE D\'INSCRIPTION',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(roleInfo['icon'] as IconData,
                              color: kWhite, size: 20),
                          const SizedBox(width: 8),
                          Text(roleInfo['label'] as String,
                              style: const TextStyle(
                                  color: kWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _field(_nom,    'Votre nom',          Icons.person_outline),
                      const SizedBox(height: 12),
                      _field(_prenom, 'Votre prénom',       Icons.person_outline),
                      const SizedBox(height: 12),
                      _field(_tel,    'Votre téléphone',    Icons.phone_outlined,
                          type: TextInputType.phone),
                      const SizedBox(height: 12),
                      _field(_region, 'Votre région',       Icons.location_on_outlined),
                      const SizedBox(height: 12),
                      _field(_email,  'Votre email',        Icons.email_outlined,
                          type: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _field(_mdp,    'Votre mot de passe', Icons.lock_outline,
                          obscure: true),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _loading ? null : () => _inscrire(role),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kBrown),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: kWhite, strokeWidth: 2))
                              : const Text('S\'inscrire'),
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
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text, bool obscure = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kGray),
        prefixIcon: Icon(icon, color: kGray, size: 20),
        filled: true,
        fillColor: kWhite,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Requis' : null,
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
      final res =
          await ApiService.connexion(_user.text, _pass.text);
      final role = res['user']['role'] as String;
      if (!mounted) return;
      final routes = {
        'AGRICULTEUR':    '/dashboard-agriculteur',
        'EXPORTATEUR':    '/gestion-exports',
        'VERIFICATEUR':   '/verification',
        'TRANSFORMATEUR': '/validation-lots',
        'COOPERATIVE':    '/gestion-lots',
        'ADMIN':          '/dashboard-national',
      };
      Navigator.pushReplacementNamed(
          context, routes[role] ?? '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: kDanger));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreenLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.eco, size: 70, color: kGreen),
              const Text('GREENSPACE',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kBrown,
                      fontSize: 20)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: kGreenDark,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _user,
                      decoration: InputDecoration(
                        hintText: 'Votre identifiant',
                        prefixIcon: const Icon(
                            Icons.person_outline,
                            color: kGray),
                        filled: true,
                        fillColor: kWhite,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Mot de passe',
                        prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: kGray),
                        filled: true,
                        fillColor: kWhite,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _connect,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kBrown),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: kWhite, strokeWidth: 2)
                            : const Text('Se connecter'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, '/role-selection'),
                      child: const Text(
                          'Pas encore compte ? S\'inscrire',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// 5. DASHBOARD NATIONAL (Ministère / Admin)
// ════════════════════════════════════════════
class DashboardNationalScreen extends StatefulWidget {
  const DashboardNationalScreen({super.key});
  @override
  State<DashboardNationalScreen> createState() =>
      _DashboardNationalState();
}

class _DashboardNationalState extends State<DashboardNationalScreen> {
  // ✅ FIX : Map<String, dynamic>? avec cast dans l'assignation
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
        // ✅ FIX : cast explicite
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
      backgroundColor: kGrayLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard National',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Ministère de l\'Agriculture · Togo',
                style: TextStyle(fontSize: 11, color: kGray)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
          const CircleAvatar(
              backgroundColor: kGreen,
              radius: 18,
              child: Icon(Icons.person, color: kWhite, size: 18)),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kGreen))
          : _data == null
              ? const Center(
                  child: Text('Impossible de charger les données'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(children: [
                          StatCard(
                              '${_data!['total_lots']}',
                              'Lots enregistrés',
                              Icons.inventory_2_outlined,
                              kGreen,
                              '+4%'),
                          const SizedBox(width: 12),
                          StatCard(
                              '${_data!['total_certifications']}',
                              'Certifications',
                              Icons.verified_outlined,
                              kBrown,
                              '+8%'),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          StatCard(
                              '${_data!['total_agriculteurs']}',
                              'Agriculteurs',
                              Icons.agriculture,
                              kGreenDark,
                              '+2%'),
                          const SizedBox(width: 12),
                          StatCard(
                              '${_data!['total_cooperatives']}',
                              'Coopératives',
                              Icons.groups,
                              kGray,
                              ''),
                        ]),
                        const SizedBox(height: 20),
                        _SectionCard(
                          title: 'Zones de production',
                          child: Column(
                            children: (_data!['zones_production']
                                    as Map<String, dynamic>)
                                .entries
                                .map((e) => _ZoneBar(e.key,
                                    (e.value as num).toDouble()))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Impact social & économique',
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _ImpactItem(
                                  '${_data!['total_agriculteurs']}',
                                  'Agriculteurs',
                                  kGreen),
                              _ImpactItem(
                                  '${_data!['pc_conforme_eudr']}%',
                                  'EUDR Conf.',
                                  kSuccess),
                              const _ImpactItem('0%', 'Litiges', kDanger),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar:
          buildBottomNav(context, 0, 'ADMIN'),
    );
  }
}

// ════════════════════════════════════════════
// 6. ENREGISTRER UN LOT (Agriculteur)
// ════════════════════════════════════════════
class EnregistrerLotScreen extends StatefulWidget {
  const EnregistrerLotScreen({super.key});
  @override
  State<EnregistrerLotScreen> createState() =>
      _EnregistrerLotState();
}

class _EnregistrerLotState extends State<EnregistrerLotScreen> {
  final _form    = GlobalKey<FormState>();
  String _culture = 'CACAO';
  final _poids   = TextEditingController();
  final _gps     = TextEditingController();
  DateTime? _dateRecolte;
  bool _loading  = false;

  Future<void> _getLocation() async {
    _gps.text = '6.1319, 1.2228';
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Position obtenue ✓'),
        backgroundColor: kSuccess));
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate() || _dateRecolte == null) {
      return;
    }
    setState(() => _loading = true);
    try {
      final parts = _gps.text.split(',');
      await ApiService.creerLot({
        'type_culture': _culture,
        'poids_kg':     _poids.text,
        'latitude':     parts[0].trim(),
        'longitude':    parts[1].trim(),
        'date_recolte':
            _dateRecolte!.toIso8601String().split('T').first,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Lot enregistré avec succès ✓'),
            backgroundColor: kSuccess));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: kDanger));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrayLight,
      appBar: AppBar(
        title: const Text('Enregistrer un nouveau lot'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Enregistrer un lot de récolte pour la traçabilité EUDR.',
                  style: TextStyle(color: kGray, fontSize: 13)),
              const SizedBox(height: 20),
              _SectionCard(
                title: '📍 Géolocalisation',
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _getLocation,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Obtenir ma position'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _gps,
                      decoration: const InputDecoration(
                          hintText: 'Coordonnées GPS'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: '⚖️ Poids du lot (kg)',
                child: TextFormField(
                  controller: _poids,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'Poids en kg', suffixText: 'kg'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: '🌱 Type de culture',
                child: Row(
                  children: ['CACAO', 'CAFE'].map((c) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _culture = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _culture == c ? kGreen : kWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _culture == c
                                  ? kGreen
                                  : const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          c == 'CACAO' ? '🍫 Cacao' : '☕ Café',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _culture == c ? kWhite : kTextDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: '📅 Date de récolte',
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: kGray, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _dateRecolte == null
                              ? 'jj/mm/aaaa'
                              : '${_dateRecolte!.day}/${_dateRecolte!.month}/${_dateRecolte!.year}',
                          style: TextStyle(
                              color: _dateRecolte == null
                                  ? kGray
                                  : kTextDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _enregistrer,
                style:
                    ElevatedButton.styleFrom(backgroundColor: kBrown),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: kWhite, strokeWidth: 2))
                    : const Text('Enregistrer le lot'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// 7. VÉRIFICATION TRAÇABILITÉ (Scanner QR)
// ════════════════════════════════════════════
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});
  @override
  State<VerificationScreen> createState() => _VerificationState();
}

class _VerificationState extends State<VerificationScreen> {
  final _idCtrl = TextEditingController();
  // ✅ FIX : Map<String, dynamic>? avec cast
  Map<String, dynamic>? _lot;
  bool _scanning = false;
  bool _loading  = false;

  Future<void> _rechercher(String idLot) async {
    setState(() {
      _loading = true;
      _lot     = null;
    });
    try {
      final data = await ApiService.scannerLot(idLot);
      setState(() {
        // ✅ FIX : cast explicite
        _lot = Map<String, dynamic>.from(data);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: kDanger));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrayLight,
      appBar: AppBar(
        title: const Text('Vérification Traçabilité'),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
          const CircleAvatar(
              backgroundColor: kGreen,
              radius: 18,
              child: Icon(Icons.person, color: kWhite, size: 18)),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
                'Scanner le QR code ou entrez l\'ID du lot',
                style: TextStyle(color: kGray, fontSize: 13)),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'ID du lot',
              child: Column(
                children: [
                  TextFormField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(
                        hintText: 'LOT-TG-2026-XXXX'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _rechercher(_idCtrl.text),
                    icon: const Icon(Icons.search),
                    label: const Text('Rechercher'),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kGreen),
                        minimumSize: const Size(double.infinity, 46)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _scanning = !_scanning),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(_scanning
                        ? 'Mode scan actif'
                        : 'Scanner un QR Code'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _scanning ? kSuccess : kGreen,
                        minimumSize:
                            const Size(double.infinity, 46)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ✅ FIX : nouvelle syntaxe mobile_scanner v7
            if (_scanning)
              SizedBox(
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    onDetect: (BarcodeCapture capture) {
                      final code =
                          capture.barcodes.firstOrNull?.rawValue;
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
                  child:
                      CircularProgressIndicator(color: kGreen)),
            if (_lot != null) ...[
              const SizedBox(height: 16),
              _LotDetailCard(_lot!),
            ],
          ],
        ),
      ),
      bottomNavigationBar:
          buildBottomNav(context, 0, 'VERIFICATEUR'),
    );
  }
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
        _lots    = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enAttente =
        _lots.where((l) => l['statut'] == 'ENREGISTRE').length;
    final enTransit =
        _lots.where((l) => l['statut'] == 'EN_TRANSIT').length;

    return Scaffold(
      backgroundColor: kGrayLight,
      appBar: AppBar(
        title: const Text('Gestion des lots'),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
          const CircleAvatar(
              backgroundColor: kGreen,
              radius: 18,
              child: Icon(Icons.person, color: kWhite, size: 18)),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _CounterBadge(
                    '$enAttente', 'Lots en attente', kWarning),
                const SizedBox(width: 12),
                _CounterBadge('$enTransit', 'Transferts', kGreen),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kGreen))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
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
      bottomNavigationBar:
          buildBottomNav(context, 0, 'COOPERATIVE'),
    );
  }
}

// ════════════════════════════════════════════
// 9. GESTION EXPORTS (Exportateur)
// ════════════════════════════════════════════
class GestionExportsScreen extends StatefulWidget {
  const GestionExportsScreen({super.key});
  @override
  State<GestionExportsScreen> createState() =>
      _GestionExportsState();
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
        _lots    = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prets =
        _lots.where((l) => l['statut'] == 'EN_EXPORT').length;
    final totalKg = _lots.fold<double>(
        0,
        (s, l) =>
            s + (double.tryParse(l['poids_kg'].toString()) ?? 0));

    return Scaffold(
      backgroundColor: kGrayLight,
      appBar: AppBar(
        title: const Text('Gestion des exports'),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
          const CircleAvatar(
              backgroundColor: kGreen,
              radius: 18,
              child: Icon(Icons.person, color: kWhite, size: 18)),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _CounterBadge(
                    '$prets', 'Prêts à exporter', kGreen),
                const SizedBox(width: 12),
                _CounterBadge(
                    '${totalKg.toStringAsFixed(0)} kg',
                    'Total',
                    kBrown),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kGreen))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _lots.length,
                      itemBuilder: (_, i) => _ExportCard(
                          Map<String, dynamic>.from(_lots[i])),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar:
          buildBottomNav(context, 0, 'EXPORTATEUR'),
    );
  }
}

// ════════════════════════════════════════════
// WIDGETS PARTAGÉS
// ════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: kGreenDark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class StatCard extends StatelessWidget {
  final String value, label, trend;
  final IconData icon;
  final Color color;
  const StatCard(
      this.value, this.label, this.icon, this.color, this.trend, {super.key});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (trend.isNotEmpty)
                    Text(trend,
                        style: const TextStyle(
                            color: kSuccess,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style:
                      const TextStyle(color: kGray, fontSize: 11)),
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
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(zone,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                Text('${valeur.toStringAsFixed(0)} kts',
                    style:
                        const TextStyle(fontSize: 12, color: kGray)),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (valeur / 600).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(kGreen),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
}

class _ImpactItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _ImpactItem(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: kGray)),
        ],
      );
}

class _CounterBadge extends StatelessWidget {
  final String value, label;
  final Color color;
  const _CounterBadge(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            // ✅ FIX : withOpacity → withValues
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: color)),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: kGray))),
            ],
          ),
        ),
      );
}

class LotCard extends StatelessWidget {
  final Map<String, dynamic> lot;
  final VoidCallback? onTransferer;
  const LotCard(this.lot, {super.key, this.onTransferer});

  Color _statutColor(String s) => switch (s) {
        'CONFORME' || 'EXPORTE' => kSuccess,
        'REFUSE'                => kDanger,
        _                       => kWarning,
      };

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lot['id_lot']?.toString() ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    // ✅ FIX : withValues
                    color: _statutColor(lot['statut']?.toString() ?? '')
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lot['conforme_eudr'] == true
                        ? 'Conforme'
                        : lot['statut']?.toString() ?? '',
                    style: TextStyle(
                        fontSize: 11,
                        color: _statutColor(
                            lot['statut']?.toString() ?? ''),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.scale_outlined,
                  size: 14, color: kGray),
              const SizedBox(width: 4),
              Text('${lot['poids_kg']} kg',
                  style:
                      const TextStyle(fontSize: 13, color: kGray)),
              const SizedBox(width: 16),
              const Icon(Icons.eco_outlined,
                  size: 14, color: kGray),
              const SizedBox(width: 4),
              Text(lot['type_culture']?.toString() ?? '',
                  style:
                      const TextStyle(fontSize: 13, color: kGray)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: kGreen)),
                  child: const Text('Détails',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onTransferer,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: EdgeInsets.zero,
                      backgroundColor: kGreen),
                  child: const Text('Transférer →',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ]),
          ],
        ),
      );
}

class _ExportCard extends StatelessWidget {
  final Map<String, dynamic> lot;
  const _ExportCard(this.lot);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lot['id_lot']?.toString() ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Text(
                '${lot['poids_kg']} kg · ${lot['type_culture']}',
                style:
                    const TextStyle(color: kGray, fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      side: const BorderSide(color: kGreen)),
                  child: const Text('Détails',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf, size: 14),
                  label: const Text('Générer preuve EUDR',
                      style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      backgroundColor: kBrown),
                ),
              ),
            ]),
          ],
        ),
      );
}

class _LotDetailCard extends StatelessWidget {
  final Map<String, dynamic> lot;
  const _LotDetailCard(this.lot);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: lot['conforme_eudr'] == true
                  ? kSuccess
                  : kWarning,
              width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lot['id_lot']?.toString() ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (lot['conforme_eudr'] == true
                            ? kSuccess
                            : kWarning)
                        // ✅ FIX : withValues
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lot['conforme_eudr'] == true
                        ? 'Conforme EUDR'
                        : 'En attente',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: lot['conforme_eudr'] == true
                            ? kSuccess
                            : kWarning),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _row('Agriculteur',
                lot['agriculteur_nom']?.toString() ?? '-'),
            _row('Type culture',
                lot['type_culture']?.toString() ?? '-'),
            _row('Poids', '${lot['poids_kg']} kg'),
            _row('Date récolte',
                lot['date_recolte']?.toString() ?? '-'),
            if ((lot['transferts'] as List?)?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              const Text('Historique des transferts',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              ...(lot['transferts'] as List).map((t) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      const Icon(Icons.arrow_forward,
                          size: 14, color: kGray),
                      const SizedBox(width: 6),
                      Text(
                          '${t['role_destinataire']} · ${t['poids_kg']} kg',
                          style: const TextStyle(
                              fontSize: 12, color: kGray)),
                    ]),
                  )),
            ],
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: kGray, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      );
}

// ── Bottom Navigation Bar ─────────────────────
Widget buildBottomNav(
    BuildContext context, int current, String role) {
  final items = <Map<String, dynamic>>[
    {'icon': Icons.home_outlined, 'label': 'Accueil'},
    if (role == 'AGRICULTEUR') ...[
      {'icon': Icons.add_circle_outline, 'label': 'Agriculture'},
      {'icon': Icons.verified_outlined,  'label': 'Vérifier'},
    ],
    if (role == 'COOPERATIVE') ...[
      {'icon': Icons.inventory_2_outlined, 'label': 'Lots'},
      {'icon': Icons.swap_horiz,           'label': 'Transferts'},
    ],
    if (role == 'EXPORTATEUR') ...[
      {'icon': Icons.local_shipping_outlined, 'label': 'Exports'},
      {'icon': Icons.picture_as_pdf,          'label': 'EUDR'},
    ],
    if (role == 'VERIFICATEUR') ...[
      {'icon': Icons.qr_code_scanner,     'label': 'Scanner'},
      {'icon': Icons.check_circle_outline, 'label': 'Valider'},
    ],
    {'icon': Icons.person_outline, 'label': 'Profil'},
  ];

  return BottomNavigationBar(
    currentIndex: current,
    selectedItemColor: kGreen,
    unselectedItemColor: kGray,
    backgroundColor: kWhite,
    type: BottomNavigationBarType.fixed,
    selectedFontSize: 10,
    unselectedFontSize: 10,
    items: items
        .map((i) => BottomNavigationBarItem(
              icon: Icon(i['icon'] as IconData),
              label: i['label'] as String,
            ))
        .toList(),
  );
}