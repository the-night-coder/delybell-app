import '../repositories/dashboard_repository.dart';
import '../../../../dashboard/models/dashboard_summary.dart';

class GetDashboardSummary {
  const GetDashboardSummary(this._repository);

  final DashboardRepository _repository;

  Future<DashboardSummary> call({required String token}) {
    return _repository.fetchDashboard(token: token);
  }
}
