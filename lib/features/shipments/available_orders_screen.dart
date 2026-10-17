import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/shipments/driver_offer_feed.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';

const _screen04Reference = 'refrinces/screens/04_orders_list.png';
const _forest = Color(0xFF075A35);
const _orange = Color(0xFFC95A22);
const _ink = Color(0xFF153B2D);
const _muted = Color(0xFF77736D);
const _cream = Color(0xFFFFFCF5);

enum _OfferSort { all, nearby, highestEarning }

class AvailableOrdersScreen extends ConsumerStatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  ConsumerState<AvailableOrdersScreen> createState() =>
      _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends ConsumerState<AvailableOrdersScreen> {
  _OfferSort _sort = _OfferSort.all;
  int? _busyOfferId;

  Future<void> _refresh() async {
    ref.invalidate(driverOfferFeedProvider);
    ref.invalidate(unreadNotificationsProvider);
    await Future.wait([
      ref.read(driverOfferFeedProvider.future),
      ref.read(unreadNotificationsProvider.future),
    ]);
  }

  Future<void> _showOffer(DriverOfferCard offer) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _cream,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                offer.shipmentNumber,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _forest,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _OfferSheetLine(label: 'الاستلام', value: offer.pickupName),
              if (offer.pickupAddress?.isNotEmpty == true)
                _OfferSheetLine(
                  label: 'عنوان الاستلام',
                  value: offer.pickupAddress!,
                ),
              if (offer.destinationLabel.isNotEmpty)
                _OfferSheetLine(
                  label: 'التوصيل',
                  value: offer.destinationLabel,
                ),
              if (offer.routeDistanceKm != null)
                _OfferSheetLine(
                  label: 'المسافة',
                  value: '${_compact(offer.routeDistanceKm!)} كم',
                ),
              if (offer.estimatedMinutes != null)
                _OfferSheetLine(
                  label: 'الوقت المتوقع',
                  value: '${offer.estimatedMinutes} دقيقة',
                ),
              _OfferSheetLine(
                label: 'عائد التوصيل',
                value: _earning(offer),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busyOfferId == null
                          ? () async {
                              Navigator.pop(sheetContext);
                              await _reject(offer);
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _orange,
                        side: const BorderSide(color: _orange),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('رفض'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _busyOfferId == null
                          ? () async {
                              Navigator.pop(sheetContext);
                              await _accept(offer);
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _forest,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('قبول الطلب'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _accept(DriverOfferCard offer) async {
    setState(() => _busyOfferId = offer.offerId);
    try {
      await ref.read(driverApiProvider).acceptOffer(offer.offerId);
      ref.invalidate(driverOfferFeedProvider);
      ref.invalidate(shipmentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول الطلب من السيرفر.')),
      );
      context.push('/shipments/${offer.shipmentId}');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busyOfferId = null);
    }
  }

  Future<void> _reject(DriverOfferCard offer) async {
    setState(() => _busyOfferId = offer.offerId);
    try {
      await ref.read(driverApiProvider).rejectOffer(offer.offerId);
      ref.invalidate(driverOfferFeedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض العرض وإرساله للسيرفر.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busyOfferId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(driverOfferFeedProvider);
    final unread = ref.watch(unreadNotificationsProvider).asData?.value ?? 0;

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        bottom: false,
        child: feedAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _forest),
          ),
          error: (error, _) => _Screen04Error(
            error: error,
            onRetry: _refresh,
          ),
          data: (feed) {
            final offers = [...feed.offers];
            switch (_sort) {
              case _OfferSort.all:
                break;
              case _OfferSort.nearby:
                offers.sort((a, b) =>
                    (a.distanceToPickupKm ?? double.infinity).compareTo(
                      b.distanceToPickupKm ?? double.infinity,
                    ));
              case _OfferSort.highestEarning:
                offers.sort(
                  (a, b) => b.deliveryEarnings.compareTo(a.deliveryEarnings),
                );
            }

            return RefreshIndicator(
              color: _forest,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 18),
                children: [
                  _ReferenceOrdersHeader(
                    unread: unread,
                    locationLabel: feed.locationLabel,
                    onLocation: () => _showLocation(feed.locationLabel),
                    onNotifications: () => context.go('/notifications'),
                    onProfile: () => context.go('/profile'),
                  ),
                  const SizedBox(height: 17),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined, color: _forest, size: 27),
                      SizedBox(width: 7),
                      Text(
                        'الطلبات المتاحة',
                        style: TextStyle(
                          color: _forest,
                          fontSize: 27,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _SortChip(
                          label: 'الكل',
                          icon: Icons.layers_rounded,
                          selected: _sort == _OfferSort.all,
                          onTap: () => setState(() => _sort = _OfferSort.all),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SortChip(
                          label: 'قريبة مني',
                          icon: Icons.location_on,
                          selected: _sort == _OfferSort.nearby,
                          onTap: () =>
                              setState(() => _sort = _OfferSort.nearby),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SortChip(
                          label: 'الأعلى ربحاً',
                          icon: Icons.bar_chart_rounded,
                          selected: _sort == _OfferSort.highestEarning,
                          onTap: () => setState(
                            () => _sort = _OfferSort.highestEarning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (offers.isEmpty)
                    const _NoOffers()
                  else
                    ...List.generate(
                      offers.length,
                      (index) => Padding(
                        padding: EdgeInsets.only(bottom: index == offers.length - 1 ? 0 : 10),
                        child: _OfferCard(
                          offer: offers[index],
                          index: index,
                          busy: _busyOfferId == offers[index].offerId,
                          onView: () => _showOffer(offers[index]),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showLocation(String? label) async {
    final value = label?.trim();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Text(
            value == null || value.isEmpty
                ? 'لم يرسل السيرفر مدينة افتراضية لحساب السائق.'
                : 'منطقة عمل السائق المسجلة في السيرفر: $value',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ReferenceOrdersHeader extends StatelessWidget {
  const _ReferenceOrdersHeader({
    required this.unread,
    required this.locationLabel,
    required this.onLocation,
    required this.onNotifications,
    required this.onProfile,
  });

  final int unread;
  final String? locationLabel;
  final VoidCallback onLocation;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final location = locationLabel?.trim();
    return SizedBox(
      height: 67,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _ReferenceCrop(
            width: 48,
            height: 48,
            alignment: Alignment(0, -.92),
            radius: 0,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onLocation,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _forest, size: 22),
                    const SizedBox(width: 3),
                    Text(
                      location == null || location.isEmpty ? 'موقعي' : location,
                      style: const TextStyle(
                        color: _forest,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.location_on, color: _forest, size: 25),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onNotifications,
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: _forest, size: 27),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 4,
                        top: 2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _orange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                InkWell(
                  onTap: onProfile,
                  borderRadius: BorderRadius.circular(30),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _ReferenceCrop(
                            width: 44,
                            height: 44,
                            alignment: Alignment(.83, -.91),
                            radius: 24,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF15C765),
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              child: SizedBox(width: 10, height: 10),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1),
                      Text(
                        'سائق توصيل',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _forest : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _forest : const Color(0xFFE8E2D7),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : _forest),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.index,
    required this.busy,
    required this.onView,
  });

  final DriverOfferCard offer;
  final int index;
  final bool busy;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final artSlot = offer.isNew ? index % 2 : 2 + (index % 2);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE6DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Metrics(offer: offer),
                      const SizedBox(width: 7),
                      Expanded(child: _RouteInfo(offer: offer)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 37,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : onView,
                      style: FilledButton.styleFrom(
                        backgroundColor: _forest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'عرض الطلب',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(width: 9),
                                Icon(Icons.chevron_left_rounded, size: 22),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ProductArt(slot: artSlot),
          ],
        ),
      ),
    );
  }
}

class _ProductArt extends StatelessWidget {
  const _ProductArt({required this.slot});
  final int slot;

  @override
  Widget build(BuildContext context) {
    const alignments = <Alignment>[
      Alignment(-.75, -.43),
      Alignment(-.75, -.02),
      Alignment(-.75, .38),
      Alignment(-.75, .78),
    ];
    final safeSlot = slot < 0 ? 0 : (slot > 3 ? 3 : slot);
    return _ReferenceCrop(
      width: 94,
      height: 101,
      alignment: alignments[safeSlot],
      radius: 15,
    );
  }
}

class _ReferenceCrop extends StatelessWidget {
  const _ReferenceCrop({
    required this.width,
    required this.height,
    required this.alignment,
    required this.radius,
  });

  final double width;
  final double height;
  final Alignment alignment;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          _screen04Reference,
          scale: 3,
          fit: BoxFit.none,
          alignment: alignment,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _RouteInfo extends StatelessWidget {
  const _RouteInfo({required this.offer});
  final DriverOfferCard offer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'استلام من',
          style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        Text(
          offer.pickupName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w900),
        ),
        if (offer.pickupAddress?.isNotEmpty == true)
          Text(
            offer.pickupAddress!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 9.5),
          ),
        const SizedBox(height: 5),
        const Text(
          'توصيل إلى',
          style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        Text(
          offer.destinationLabel.isEmpty ? '—' : offer.destinationLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _ink, fontSize: 12.5, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.offer});
  final DriverOfferCard offer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Metric(
            icon: Icons.route_rounded,
            value: offer.routeDistanceKm == null
                ? '—'
                : '${_compact(offer.routeDistanceKm!)} كم',
          ),
          const SizedBox(height: 4),
          _Metric(
            icon: Icons.schedule_rounded,
            value: offer.estimatedMinutes == null
                ? '—'
                : '${offer.estimatedMinutes} دقيقة',
          ),
          const SizedBox(height: 4),
          _Metric(
            icon: Icons.monetization_on_outlined,
            value: _earning(offer),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: emphasize ? _orange : _forest, size: 13),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              color: emphasize ? _orange : _ink,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferSheetLine extends StatelessWidget {
  const _OfferSheetLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: _muted)),
        ],
      ),
    );
  }
}

class _NoOffers extends StatelessWidget {
  const _NoOffers();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined, color: _forest, size: 48),
          SizedBox(height: 12),
          Text(
            'لا توجد طلبات متاحة من السيرفر الآن',
            textAlign: TextAlign.center,
            style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Screen04Error extends StatelessWidget {
  const _Screen04Error({required this.error, required this.onRetry});
  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 150),
        const Icon(Icons.cloud_off_rounded, color: _orange, size: 50),
        const SizedBox(height: 14),
        const Text(
          'تعذر تحميل الطلبات المتاحة من السيرفر',
          textAlign: TextAlign.center,
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(error.toString(), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(backgroundColor: _forest),
          child: const Text('إعادة المحاولة'),
        ),
      ],
    );
  }
}

String _compact(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < .05) return rounded.toInt().toString();
  return value.toStringAsFixed(1);
}

String _earning(DriverOfferCard offer) {
  final amount = _compact(math.max(0, offer.deliveryEarnings));
  final currency = offer.currency?.trim();
  if (currency == null || currency.isEmpty) return amount;
  if (currency.toUpperCase() == 'SAR') return '$amount ر.س';
  return '$amount $currency';
}
