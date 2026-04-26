import '../entities/nationality.dart';

abstract class NationalityRepository {
  Future<List<Nationality>> fetchNationalities({
    required String token,
    String search = '',
  });
}
