import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/constants/app_colors.dart';
import 'models/nursery.dart';
import 'nursery_detail_screen.dart';

class NurseriesScreen extends StatefulWidget {
  const NurseriesScreen({super.key});

  @override
  State<NurseriesScreen> createState() => _NurseriesScreenState();
}

class _NurseriesScreenState extends State<NurseriesScreen> {
  String? _selectedCity;
  bool _isMapView = false;
  Nursery? _selectedMapNursery;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<AppProvider>();
      if (prov.nurseriesState == LoadState.idle) prov.fetchNurseries();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _openDirections(Nursery nursery) async {
    Uri url;
    if (nursery.hasCoordinates) {
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${nursery.latitude},${nursery.longitude}',
      );
    } else if (nursery.address != null && nursery.address!.isNotEmpty) {
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${nursery.name}, ${nursery.address}')}',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location coordinates or address recorded for this nursery.')),
      );
      return;
    }

    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map application.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appProv = context.watch<AppProvider>();
    final locProv = context.watch<LocationProvider>();

    // Extract unique available cities from the real nurseries data
    final cities = appProv.nurseries
        .map((n) => n.city?.trim())
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    cities.sort();

    // Filter nurseries by selected city if any
    var displayNurseries = List<Nursery>.from(appProv.nurseries);
    if (_selectedCity != null) {
      displayNurseries = displayNurseries.where((n) => n.city?.trim() == _selectedCity).toList();
    }

    // Sort by real distance if user coordinates are known
    if (locProv.hasLocation) {
      displayNurseries.sort((a, b) {
        final distA = a.distanceFrom(locProv.latitude, locProv.longitude) ?? 999999;
        final distB = b.distanceFrom(locProv.latitude, locProv.longitude) ?? 999999;
        return distA.compareTo(distB);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isMapView ? 'Nursery Map Discovery' : 'Nearby Nurseries'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isMapView ? Icons.format_list_bulleted : Icons.map_outlined,
              color: AppColors.botanicalGreen,
            ),
            tooltip: _isMapView ? 'Switch to List View' : 'Switch to Map Discovery',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Refresh Nurseries',
            onPressed: () => appProv.fetchNurseries(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Location & Fallback Status Banner ────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                if (locProv.hasLocation) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.botanicalGreenLight.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.botanicalGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: AppColors.botanicalGreen, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPS Location Active',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.botanicalGreenDark),
                              ),
                              Text(
                                'Sorted by precise distance from you',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => locProv.clearLocation(),
                          child: const Text('Reset', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me_outlined, color: AppColors.botanicalGreen, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sort by Distance',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Used on-device only to calculate proximity',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: locProv.isLoading
                              ? null
                              : () async {
                                  await locProv.requestUserLocation();
                                  if (locProv.errorMessage != null && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(locProv.errorMessage!),
                                        action: SnackBarAction(
                                          label: 'Settings',
                                          onPressed: () => locProv.openAppSettings(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.botanicalGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          icon: locProv.isLoading
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.gps_fixed, size: 14),
                          label: Text(locProv.isLoading ? 'Locating…' : 'Locate Me'),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Manual City Fallback Filter ─────────────────────
                if (cities.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Cities'),
                          selected: _selectedCity == null,
                          selectedColor: AppColors.botanicalGreenLight,
                          labelStyle: TextStyle(
                            color: _selectedCity == null ? AppColors.botanicalGreenDark : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: _selectedCity == null ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => setState(() => _selectedCity = null),
                        ),
                        const SizedBox(width: 8),
                        ...cities.map((city) {
                          final isSel = _selectedCity == city;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(city),
                              selected: isSel,
                              selectedColor: AppColors.botanicalGreenLight,
                              labelStyle: TextStyle(
                                color: isSel ? AppColors.botanicalGreenDark : AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCity = selected ? city : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Nurseries Content: Map Discovery vs List ───────────────────
          Expanded(
            child: Consumer<AppProvider>(
              builder: (ctx, prov, _) {
                if (prov.nurseriesState == LoadState.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.botanicalGreen),
                  );
                }
                if (prov.nurseriesState == LoadState.error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.store_outlined, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Could not load nurseries', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: prov.fetchNurseries,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.botanicalGreen),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (displayNurseries.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.botanicalGreen,
                    onRefresh: () => prov.fetchNurseries(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 56, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                _selectedCity != null
                                    ? 'No nurseries found in $_selectedCity.'
                                    : 'No registered nurseries found yet.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Pull down to refresh or check back soon',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: prov.fetchNurseries,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.botanicalGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                              if (_selectedCity != null) ...[
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () => setState(() => _selectedCity = null),
                                  child: const Text('Show All Cities', style: TextStyle(color: AppColors.botanicalGreen)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_isMapView) {
                  return _buildMapView(displayNurseries, locProv);
                }

                return RefreshIndicator(
                  color: AppColors.botanicalGreen,
                  onRefresh: () => prov.fetchNurseries(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayNurseries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final n = displayNurseries[i];
                      final distStr = locProv.hasLocation ? n.distanceDisplayFrom(locProv.latitude, locProv.longitude) : null;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => NurseryDetailScreen(nursery: n)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.botanicalGreenLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: n.logoUrl != null && n.logoUrl!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(n.logoUrl!, fit: BoxFit.cover),
                                            )
                                          : const Icon(Icons.park_outlined, color: AppColors.botanicalGreen, size: 28),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  n.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (n.isVerified) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified, color: AppColors.botanicalGreen, size: 18),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (n.address != null && n.address!.isNotEmpty)
                                            Text(
                                              n.address!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (distStr != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.directions_walk, size: 13, color: AppColors.primaryBlue),
                                            const SizedBox(width: 4),
                                            Text(
                                              distStr,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (n.plantCount != null)
                                      Text(
                                        '${n.plantCount} plants in stock',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.botanicalGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    const Spacer(),
                                    OutlinedButton.icon(
                                      onPressed: () => _openDirections(n),
                                      icon: const Icon(Icons.directions, size: 14),
                                      label: const Text('Directions'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryBlue,
                                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => NurseryDetailScreen(nursery: n)),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.botanicalGreen,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('View Plants'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(List<Nursery> nurseries, LocationProvider locProv) {
    final nurseriesWithCoords = nurseries.where((n) => n.hasCoordinates).toList();

    LatLng initialCenter;
    if (locProv.hasLocation) {
      initialCenter = LatLng(locProv.latitude!, locProv.longitude!);
    } else if (nurseriesWithCoords.isNotEmpty) {
      initialCenter = LatLng(nurseriesWithCoords.first.latitude!, nurseriesWithCoords.first.longitude!);
    } else {
      initialCenter = const LatLng(18.5204, 73.8567);
    }

    final markers = <Marker>[];

    // User location marker
    if (locProv.hasLocation) {
      markers.add(
        Marker(
          point: LatLng(locProv.latitude!, locProv.longitude!),
          width: 50,
          height: 50,
          child: Tooltip(
            message: 'You are here',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha: 0.25),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade700,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Nursery markers
    for (final n in nurseriesWithCoords) {
      final isSelected = _selectedMapNursery?.id == n.id;
      markers.add(
        Marker(
          point: LatLng(n.latitude!, n.longitude!),
          width: 70,
          height: 60,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMapNursery = n;
              });
              _mapController.move(LatLng(n.latitude!, n.longitude!), 14.5);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentGold : AppColors.botanicalGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSelected ? Icons.storefront : Icons.eco,
                    color: Colors.white,
                    size: isSelected ? 22 : 18,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    n.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 12.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.gogreenai.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Controls (Recenter, Zoom In, Zoom Out)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'map_recenter',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.botanicalGreen,
                onPressed: () {
                  if (locProv.hasLocation) {
                    _mapController.move(LatLng(locProv.latitude!, locProv.longitude!), 14.0);
                  } else {
                    locProv.requestUserLocation().then((_) {
                      if (locProv.hasLocation && mounted) {
                        _mapController.move(LatLng(locProv.latitude!, locProv.longitude!), 14.0);
                      }
                    });
                  }
                },
                tooltip: 'My Location',
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_zoom_in',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                onPressed: () {
                  final zoom = _mapController.camera.zoom + 1.0;
                  _mapController.move(_mapController.camera.center, zoom);
                },
                tooltip: 'Zoom In',
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_zoom_out',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                onPressed: () {
                  final zoom = _mapController.camera.zoom - 1.0;
                  _mapController.move(_mapController.camera.center, zoom);
                },
                tooltip: 'Zoom Out',
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),

        // Bottom Selected Nursery Card
        if (_selectedMapNursery != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.botanicalGreen.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.botanicalGreenLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _selectedMapNursery!.logoUrl != null && _selectedMapNursery!.logoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(_selectedMapNursery!.logoUrl!, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.storefront, color: AppColors.botanicalGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedMapNursery!.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_selectedMapNursery!.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: AppColors.botanicalGreen, size: 16),
                                ],
                              ],
                            ),
                            if (_selectedMapNursery!.city != null)
                              Text(
                                _selectedMapNursery!.city!,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _selectedMapNursery = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (locProv.hasLocation && _selectedMapNursery!.hasCoordinates) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedMapNursery!.distanceDisplayFrom(locProv.latitude, locProv.longitude) ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_selectedMapNursery!.plantCount != null)
                        Text(
                          '${_selectedMapNursery!.plantCount} plants in stock',
                          style: const TextStyle(fontSize: 12, color: AppColors.botanicalGreen, fontWeight: FontWeight.w600),
                        ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _openDirections(_selectedMapNursery!),
                        icon: const Icon(Icons.directions, size: 14),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => NurseryDetailScreen(nursery: _selectedMapNursery!)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.botanicalGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('View Plants'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
