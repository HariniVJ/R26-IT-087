import 'package:flutter/material.dart';

import '../../common/brand_color.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_notification.dart';
import '../../services/firebase/firestore_service.dart';
import '../../utils/format_datetime.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await FirestoreService.instance.getNotifications(limit: 80);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      await FirestoreService.instance.markNotificationRead(item.id);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Text(item.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('markRead')),
          ),
        ],
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      bottomNavigationBar: const AppBottomNavBar(current: AppNavTab.home),
      appBar: AppBar(
        title: Text(t('notifications')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(t('noAlerts')))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        onTap: () => _open(item),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: item.isRead
                            ? Colors.white
                            : BrandColor.primary.withOpacity(0.06),
                        leading: CircleAvatar(
                          backgroundColor: BrandColor.primary.withOpacity(0.12),
                          child: Icon(
                            item.isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: BrandColor.primary,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight:
                                item.isRead ? FontWeight.w600 : FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '${item.message}\n${formatFarmDateTime(item.createdAt)}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
    );
  }
}
