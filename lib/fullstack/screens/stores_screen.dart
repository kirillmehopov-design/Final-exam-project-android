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
                              ? const Color(0xFFB9DC3E)
                              : SneakerDesign.ink,
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
            separatorBuilder: (_, __) =>
              const SizedBox(width: 10, height: 10),
            itemBuilder: (context, index) {
              final store = visible[index];
              final active = store['id'] == _selectedId;
              final photos = (store['photos'] as List?) ?? const [];
              Widget shopButton() => FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: SneakerDesign.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9)),
                onPressed: () => _openBranch(store),
                icon: const Icon(Icons.arrow_outward, size: 16),
                label: const Text('VIEW STORE',
                  style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w900)),
              );
              Widget photoTile(double height) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: photos.isEmpty
                  ? Container(color: SneakerDesign.imageSurface,
                    height: height, child:
                      const Icon(Icons.storefront_outlined))
                  : Image.network(photos.first as String,
                    height: height, width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                      Container(height: height,
                        color: SneakerDesign.imageSurface,
                        child: const Icon(Icons.storefront_outlined))),
              );
              return SizedBox(
                width: narrow ? 274 : null,
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(color: active
                      ? SneakerDesign.ink : SneakerDesign.line,
                      width: active ? 2 : .8)),
                  child: InkWell(
                    onTap: () => _focus(store),
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: narrow
                        ? Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(store['name'] as String,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(store['district'] as String,
                                style: const TextStyle(
                                  color: SneakerDesign.muted, fontSize: 11)),
                              const SizedBox(height: 8),
                              Expanded(child: Row(children: [
                                SizedBox(width: 96, child: photoTile(90)),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${store['available_models']} models in stock',
                                      maxLines: 2,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11)),
                                    Text('Open hours: ${store['hours']}',
                                      maxLines: 2,
                                      style: const TextStyle(
                                        color: SneakerDesign.muted,
                                        fontSize: 10)),
                                    shopButton(),
                                  ]),
                                )),
                              ])),
                            ])
                        : Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              photoTile(120),
                              const SizedBox(height: 12),
                              Text(store['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 17)),
                              const SizedBox(height: 4),
                              Text('${store['district']} • ${store['address_hint']}',
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 8),
                              Text('${store['available_models']} models in stock · ${store['hours']}',
                                style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 9),
                              Row(children: [
                                Expanded(child: shopButton()),
                                IconButton(
                                  tooltip: 'Open directions',
                                  onPressed: () => _directions(store),
                                  icon: const Icon(Icons.directions_outlined)),
                              ]),
                            ]),
                    ),
                  ),
                ),
              );
            },
          );
          final details = Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(children: [
                Expanded(child: Text('Find your store.',
                  style: TextStyle(fontWeight: FontWeight.w900,
                    fontSize: narrow ? 20 : 24, letterSpacing: -1))),
                const Icon(Icons.map_outlined, size: 21),
              ]),
            ),
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
            if (!narrow && selected != null)
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
                borderRadius: BorderRadius.circular(5),
                child: mapWidget,
              )),
              SizedBox(height: 176, child: cards),
            ]);
          }
          return Row(children: [
            SizedBox(width: 340, child: Column(children: [
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
