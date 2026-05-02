// lib/main.dart
import 'package:flutter/material.dart';
import 'core/offline/offline_manager.dart';
import 'core/sync/sync_service.dart';
import 'core/connectivity/connectivity_service.dart';
import 'constants.dart';
import 'screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineManager().init();
  runApp(const GreenSpaceApp());
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
        '/home':                (_) => const HomeScreen(),
        '/role-selection':      (_) => const RoleSelectionScreen(),
        '/inscription':         (_) => const InscriptionScreen(),
        '/connexion':           (_) => const ConnexionScreen(),
        '/dashboard-national':  (_) => const DashboardNationalScreen(),
        '/dashboard-agriculteur': (_) => const DashboardAgriculteurScreen(),
        '/enregistrer-lot':     (_) => const EnregistrerLotScreen(),
        '/verification':        (_) => const VerificationScreen(),
        '/gestion-lots':        (_) => const GestionLotsScreen(),
        '/gestion-exports':     (_) => const GestionExportsScreen(),
      },
      builder: (context, child) {
        // ✅ Bannière de connectivité affichée sur toutes les pages
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
  State<ConnectivityWrapper> createState() =>
      _ConnectivityWrapperState();
}

class _ConnectivityWrapperState
    extends State<ConnectivityWrapper> {
  bool _isOnline    = true;
  bool _showBanner  = false;
  SyncStatus _sync  = SyncStatus.idle;

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
          _isOnline   = connected;
          _showBanner = true;
        });
        // Cacher la bannière "En ligne" après 3 secondes
        if (connected) {
          Future.delayed(
              const Duration(seconds: 3),
              () { if (mounted) setState(() => _showBanner = false); });
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

        // ── Bannière offline ──
        if (!_isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 6, horizontal: 16),
            color: kWarning,
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
            padding: const EdgeInsets.symmetric(
                vertical: 6, horizontal: 16),
            color: kSuccess,
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
                    width: 12, height: 12,
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
// DASHBOARD AGRICULTEUR (nouveau screen)
// ════════════════════════════════════════════
class DashboardAgriculteurScreen extends StatefulWidget {
  const DashboardAgriculteurScreen({super.key});
  @override
  State<DashboardAgriculteurScreen> createState() =>
      _DashboardAgriculteurState();
}

class _DashboardAgriculteurState
    extends State<DashboardAgriculteurScreen> {
  List<Map<String, dynamic>> _lots = [];
  Map<String, dynamic> _syncStats  = {};
  bool _loading                    = true;
  bool _isOnline                   = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Charger les lots via OfflineManager
    final result = await OfflineManager().getLots();
    final stats  = await OfflineManager().getSyncStats();
    final online = await ConnectivityService().isConnected();

    if (mounted) {
      setState(() {
        _lots      = result.data != null
            ? List<Map<String, dynamic>>.from(result.data)
            : [];
        _syncStats = stats;
        _isOnline  = online;
        _loading   = false;
      });
    }
  }

  Future<void> _forcerSync() async {
    final result = await OfflineManager().forcerSync();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.succes > 0 ? kSuccess : kWarning,
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nonSynces = _syncStats['lots_non_synces'] ?? 0;

    return Scaffold(
      backgroundColor: kGrayLight,
      appBar: AppBar(
        title: const Text('Mon Dashboard'),
        actions: [
          // ── Bouton synchronisation manuelle ──
          if (!_isOnline)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off, color: kWarning),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _forcerSync,
              tooltip: 'Synchroniser',
            ),
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
          const CircleAvatar(
              backgroundColor: kGreen,
              radius: 18,
              child:
                  Icon(Icons.person, color: kWhite, size: 18)),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Bannière données non synchronisées ──
                    if (nonSynces > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: kWarning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: kWarning.withValues(
                                  alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_upload_outlined,
                                color: kWarning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$nonSynces lot(s) en attente de synchronisation',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: kWarning,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            TextButton(
                              onPressed: _forcerSync,
                              child: const Text('Sync',
                                  style: TextStyle(
                                      color: kWarning,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    // ── Stats ──
                    Row(children: [
                      StatCard('${_lots.length}',   'Mes lots',   Icons.inventory_2_outlined, kGreen,  ''),
                      const SizedBox(width: 12),
                      StatCard('$nonSynces',         'Non sync.', Icons.cloud_off,             kWarning,''),
                    ]),
                    const SizedBox(height: 20),

                    // ── Bouton enregistrer ──
                    ElevatedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.pushNamed(
                            context, '/enregistrer-lot');
                        if (res == true) _load();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text(
                          'Enregistrer un nouveau lot'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen),
                    ),
                    const SizedBox(height: 20),

                    // ── Liste des lots ──
                    if (_lots.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('Aucun lot enregistré',
                              style:
                                  TextStyle(color: kGray)),
                        ),
                      )
                    else
                      ..._lots.map((lot) => LotCard(
                          Map<String, dynamic>.from(lot))),
                  ],
                ),
              ),
            ),
      bottomNavigationBar:
          buildBottomNav(context, 0, 'AGRICULTEUR'),
    );
  }
}