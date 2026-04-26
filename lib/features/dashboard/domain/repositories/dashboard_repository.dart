import '../../../../dashboard/models/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> fetchDashboard({required String token});
  Future<DashboardSummary?> loadCachedSummary();
}
