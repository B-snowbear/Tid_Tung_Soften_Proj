import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/notification_api_service.dart';
import '../theme.dart';
// import '../models.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if mounted to prevent errors
      if (mounted) {
        context.read<NotificationApiService>().fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TTColors.bgStart, TTColors.bgEnd],
        ),
      ),
      child: Consumer<NotificationApiService>(
        builder: (context, service, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              elevation: 0,
              title: const Text(
                "Notifications",
                style: TextStyle(
                  color: TTColors.textOnDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              iconTheme: const IconThemeData(color: TTColors.textOnDark),
            ),

            body: _buildBody(context, service),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationApiService service) {
    // if (service.loading) {
    //   return const Center(
    //     child: CircularProgressIndicator(color: TTColors.accent),
    //   );
    // }

    if (service.notifications.isEmpty) {
      return const Center(
        child: Text(
          "No notifications.",
          style: TextStyle(
            color: TTColors.textOnDark,
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => service.fetchNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: service.notifications.length,
        itemBuilder: (context, i) {
          final n = service.notifications[i];
          final bool unread = !n.isRead;
          
          final DateTime date = n.createdAt.toLocal(); 
          final String timeString= timeago.format(date, locale: 'en_short');
      
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unread
                  ? TTColors.surface.withOpacity(0.08)
                  : TTColors.surface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: unread
                    ? TTColors.accent.withOpacity(0.7)
                    : Colors.white10,
                width: unread ? 1.2 : 0.8,
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
      
              leading: Icon(
                unread ? Icons.notifications : Icons.notifications_none,
                color: unread ? TTColors.accent : TTColors.cC9D7FF,
                size: 28,
              ),
      
              title: Text(
                n.title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
      
              subtitle: n.body.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            n.body,
                            style: const TextStyle(
                              fontSize: 14,
                              color: TTColors.cC9D7FF,
                            ),
                          ),
      
                          const SizedBox(height: 6),

                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
      
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white70),
                onPressed: () => service.deleteNotification(n.id),
              ),
      
              onTap: () => service.markRead(n.id),
            ),
          );
        },
      ),
    );
  }
}
