import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<AppProvider>();
      if (prov.nurseriesState == LoadState.idle) prov.fetchNurseries();
    });
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
        title: const Text('Nearby Nurseries'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
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

          // ── Nurseries List ──────────────────────────────────────
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _selectedCity != null ? 'No nurseries found in $_selectedCity.' : 'No nurseries found.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        if (_selectedCity != null) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() => _selectedCity = null),
                            child: const Text('Show All Cities', style: TextStyle(color: AppColors.botanicalGreen)),
                          ),
                        ],
                      ],
                    ),
                  );
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
}
