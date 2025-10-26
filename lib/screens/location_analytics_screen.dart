// lib/screens/location_analytics_screen.dart - Complete working version

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saveplus_plus/state/app_state.dart';
import 'package:saveplus_plus/utils/constants.dart';

class LocationAnalyticsScreen extends StatefulWidget {
  const LocationAnalyticsScreen({super.key});

  @override
  State<LocationAnalyticsScreen> createState() => _LocationAnalyticsScreenState();
}

class _LocationAnalyticsScreenState extends State<LocationAnalyticsScreen> {
  List<LocationSpendingGroup> _locationGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocationAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: isDark ? const Color(0xFF121212) : Colors.white,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: Column(
          children: [
            // Custom app bar
            Container(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Spending Locations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_locationGroups.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Location Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enable location tracking when adding transactions to see spending patterns by location.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _locationGroups.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final group = _locationGroups[index];
                    return _buildLocationCard(group, appState, isDark);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(LocationSpendingGroup group, AppState appState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location name and total
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.locationName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                appState.formatCurrency(group.totalSpent),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.orangeAlert,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Transaction count and breakdown
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${group.transactionCount} transaction${group.transactionCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Avg: ${appState.formatCurrency(group.totalSpent / group.transactionCount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Address if available
          if (group.fullAddress.isNotEmpty) ...[
            Text(
              group.fullAddress,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadLocationAnalytics() async {
    final appState = context.read<AppState>();
    
    // Group transactions by location
    final Map<String, LocationSpendingGroup> locationMap = {};
    
    for (final transaction in appState.allTxns) {
      // Only include expenses with location data
      if (transaction.amount >= 0 || transaction.location == null) continue;
      
      final locationKey = transaction.location!.shortName;
      
      if (locationMap.containsKey(locationKey)) {
        final group = locationMap[locationKey]!;
        group.totalSpent += transaction.amount.abs();
        group.transactionCount++;
      } else {
        locationMap[locationKey] = LocationSpendingGroup(
          locationName: transaction.location!.shortName,
          fullAddress: transaction.location!.address,
          totalSpent: transaction.amount.abs(),
          transactionCount: 1,
        );
      }
    }
    
    // Sort by total spending (highest first)
    final sortedGroups = locationMap.values.toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    setState(() {
      _locationGroups = sortedGroups.take(20).toList(); // Show top 20
      _isLoading = false;
    });
  }
}

// Helper class for grouping spending by location
class LocationSpendingGroup {
  final String locationName;
  final String fullAddress;
  double totalSpent;
  int transactionCount;

  LocationSpendingGroup({
    required this.locationName,
    required this.fullAddress,
    required this.totalSpent,
    required this.transactionCount,
  });
}