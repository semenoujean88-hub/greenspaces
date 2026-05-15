// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'core/offline/offline_manager.dart';
import 'core/sync/sync_service.dart';
import 'core/connectivity/connectivity_service.dart';
// import 'constants.dart';
import 'screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineManager().init();
  runApp(const GreenSpaceApp());
}

// Thème général de l'application
ThemeData greenSpaceTheme() {
  return ThemeData(
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.backgroundGreen,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.textDark),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryGreenLight, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class GreenSpaceApp extends StatelessWidget {
  const GreenSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenSpace',
      debugShowCheckedModeBanner: false,
      theme: greenSpaceTheme(),
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/role-selection': (_) => const RoleSelectionScreen(),
        '/inscription': (_) => const InscriptionScreen(),
        '/connexion': (_) => const ConnexionScreen(),
        '/dashboard-national': (_) => const DashboardNationalScreen(),
        '/dashboard-agriculteur': (_) => const DashboardAgriculteurScreen(),
        '/enregistrer-lot': (_) => const EnregistrerLotScreen(),
        '/verification': (_) => const VerificationScreen(),
        '/gestion-lots': (_) => const GestionLotsScreen(),
        '/gestion-exports': (_) => const GestionExportsScreen(),
      },
      builder: (context, child) {
        return ConnectivityWrapper(child: child!);
      },
    );
  }
}

// ════════════════════════════════════════════
// BANNIÈRE CONNECTIVITÉ (affichée partout)
// ════════════════════════════════════════════
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isOnline = true;
  bool _showBanner = false;
  SyncStatus _sync = SyncStatus.idle;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _listenConnectivity();
    _listenSync();
  }

  Future<void> _checkInitial() async {
    final connected = await ConnectivityService().isConnected();
    setState(() => _isOnline = connected);
  }

  void _listenConnectivity() {
    ConnectivityService().listen((connected) {
      if (mounted) {
        setState(() {
          _isOnline = connected;
          _showBanner = true;
        });
        if (connected) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showBanner = false);
          });
        }
      }
    });
  }

  void _listenSync() {
    SyncService().onSyncStatusChanged.listen((status) {
      if (mounted) setState(() => _sync = status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),

        // ── Bannière hors ligne ──
        if (!_isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: AppColors.statusPending,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 14),
                SizedBox(width: 8),
                Text(
                  'Hors ligne — données sauvegardées localement',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

        // ── Bannière retour en ligne ──
        if (_isOnline && _showBanner)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: AppColors.statusVerified,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi, color: Colors.white, size: 14),
                const SizedBox(width: 8),
                Text(
                  _sync == SyncStatus.enCours
                      ? 'Synchronisation en cours...'
                      : 'En ligne — données synchronisées ✓',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                if (_sync == SyncStatus.enCours) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════
// DASHBOARD AGRICULTEUR
// ════════════════════════════════════════════
class DashboardAgriculteurScreen extends StatefulWidget {
  const DashboardAgriculteurScreen({super.key});
  @override
  State<DashboardAgriculteurScreen> createState() =>
      _DashboardAgriculteurState();
}

class _DashboardAgriculteurState extends State<DashboardAgriculteurScreen> {
  List<Map<String, dynamic>> _lots = [];
  Map<String, dynamic> _syncStats = {};
  bool _loading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await OfflineManager().getLots();
    final stats = await OfflineManager().getSyncStats();
    final online = await ConnectivityService().isConnected();
    if (mounted) {
      setState(() {
        _lots = result.data != null
            ? List<Map<String, dynamic>>.from(result.data)
            : [];
        _syncStats = stats;
        _isOnline = online;
        _loading = false;
      });
    }
  }

  Future<void> _forcerSync() async {
    final result = await OfflineManager().forcerSync();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.succes > 0 ? AppColors.statusVerified : AppColors.statusPending,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nonSynces = _syncStats['lots_non_synces'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Mon Dashboard',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          if (!_isOnline)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off, color: AppColors.statusPending),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync, color: AppColors.primaryGreen),
              onPressed: _forcerSync,
              tooltip: 'Synchroniser',
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textMedium),
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
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Bannière données non synchronisées ──
                    if (nonSynces > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.statusPending.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.statusPending.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_upload_outlined,
                                color: AppColors.statusPending, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$nonSynces lot(s) en attente de synchronisation',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.statusPending,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            TextButton(
                              onPressed: _forcerSync,
                              child: const Text(
                                'Sync',
                                style: TextStyle(
                                    color: AppColors.statusPending,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Stats (CORRIGÉ : utilisation des paramètres nommés) ──
                    Row(children: [
                      StatCard(
                        value: '${_lots.length}',
                        label: 'Mes lots',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primaryGreen,
                        trend: '',
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        value: '$nonSynces',
                        label: 'Non sync.',
                        icon: Icons.cloud_off,
                        color: AppColors.statusPending,
                        trend: '',
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Bouton enregistrer ──
                    GreenButton(
                      label: 'Enregistrer un nouveau lot',
                      icon: Icons.add_circle_outline,
                      onTap: () async {
                        final res = await Navigator.pushNamed(
                            context, '/enregistrer-lot');
                        if (res == true) _load();
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Liste des lots ──
                    if (_lots.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 48,
                                  color: AppColors.textLight.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'Aucun lot enregistré',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._lots.map((lot) => LotCard(Map<String, dynamic>.from(lot))),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: buildBottomNav(context, 0, 'AGRICULTEUR'),
    );
  }
}