part of '../shop_ui.dart';

/// All locations are fictional branches and are served by the SQLite API.
/// The map works in Flutter web and Android without Google Maps API keys.
class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  final MapController _map = MapController();
  late Future<List<Json>> _locations;
  String _district = 'All districts';
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final api = context.read<ShopCubit>().api;
    _locations = api.get('/stores').then(asJsonList);
  }

  void _focus(Json store) {
    setState(() => _selectedId = store['id'] as int);
    _map.move(LatLng((store['latitude'] as num).toDouble(),
        (store['longitude'] as num).toDouble()), 13.4);
  }


  Future<void> _openBranch(Json store) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<ShopCubit>(),
        child: StoreDetailPage(storeId: store['id'] as int),
      ),
    ));
  }

  Future<void> _directions(Json store) async {
    final lat = store['latitude'];
    final lng = store['longitude'];
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Json>>(
      future: _locations,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            const Text('Store map could not load'),
            const SizedBox(height: 8),
            Text('${snapshot.error}', textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh), label: const Text('Retry'),
            ),
          ]));
        }
        final stores = snapshot.data ?? <Json>[];
        final districts = <String>{
          for (final s in stores) s['district'] as String,
        }.toList()..sort();
        final visible = stores.where(
          (s) => _district == 'All districts' || s['district'] == _district,
        ).toList();
        Json? selected;
        for (final s in visible) {
          if (s['id'] == _selectedId) selected = s;
        }
        return LayoutBuilder(builder: (context, bounds) {
          final narrow = bounds.maxWidth < 570;
          final mapWidget = FlutterMap(
            mapController: _map,
            options: const MapOptions(
              initialCenter: LatLng(43.251, 76.915),
              initialZoom: 10.9,
              minZoom: 9,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'kz.narxoz.sneakerhub',
              ),
              MarkerLayer(markers: [
                for (final store in visible)
                  Marker(
                    point: LatLng((store['latitude'] as num).toDouble(),
                        (store['longitude'] as num).toDouble()),
                    width: 48, height: 52,
                    child: Tooltip(
                      message: store['name'] as String,
                      child: GestureDetector(
                        onTap: () => _focus(store),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: store['id'] == _selectedId ? 48 : 40,
                          color: store['id'] == _selectedId
                              ? const Color(0xFFEF7740)
                              : const Color(0xFF25345B),
                        ),
                      ),
                    ),
                  ),
              ]),
              const RichAttributionWidget(attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ]),
            ],
          );
          final cards = ListView.separated(
            padding: const EdgeInsets.all(10),
            scrollDirection: narrow ? Axis.horizontal : Axis.vertical,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8, height: 8),
            itemBuilder: (context, index) {
              final store = visible[index];
              final active = store['id'] == _selectedId;
              return SizedBox(
                width: narrow ? 275 : null,
                child: Card(
                  color: active
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _focus(store),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            Expanded(child: Text(store['name'] as String,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                            IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18),
                              tooltip: 'Explore store', onPressed: () => _openBranch(store)),
                          ]),
                          if ((store['photos'] as List?)?.isNotEmpty == true)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.network((store['photos'] as List).first as String,
                                height: 92, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 92, child: Icon(Icons.storefront))),
                            ),
                          const SizedBox(height: 3),
                          Text('${store['available_models'] ?? 0} models with stock',
                            style: Theme.of(context).textTheme.bodySmall),
                          Text('${store['district']} • ${store['address_hint']}',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.schedule, size: 14),
                            const SizedBox(width: 4),
                            Expanded(child: Text('Demo hours: ${store['hours']}',
                              style: Theme.of(context).textTheme.bodySmall)),
                            IconButton(
                              tooltip: 'Shop this store',
                              onPressed: () => _openBranch(store),
                              icon: const Icon(Icons.shopping_bag_outlined),
                            ),
                            IconButton(
                              tooltip: 'Open directions',
                              onPressed: () => _directions(store),
                              icon: const Icon(Icons.directions_outlined),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
          final details = Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: _district,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Almaty district',
                    prefixIcon: Icon(Icons.filter_alt_outlined),
                    isDense: true, border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'All districts',
                        child: Text('All districts')),
                    for (final d in districts)
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: (value) => setState(() {
                    _district = value ?? 'All districts';
                    _selectedId = null;
                  }),
                )),
                IconButton(
                  tooltip: 'Reload branches from API',
                  onPressed: () => setState(_reload),
                  icon: const Icon(Icons.refresh),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('${visible.length} demo stores',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('Fictional locations',
                    style: TextStyle(fontSize: 11)),
              ]),
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Selected: ${selected['name']} • ${selected['hours']}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
          ]);
          if (narrow) {
            return Column(children: [
              details,
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: mapWidget,
              )),
              SizedBox(height: 235, child: cards),
            ]);
          }
          return Row(children: [
            SizedBox(width: 330, child: Column(children: [
              details, Expanded(child: cards),
            ])),
            Expanded(child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: mapWidget,
              ),
            )),
          ]);
        });
      },
    );
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }
}
