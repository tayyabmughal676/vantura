import '../../data/database/database_helper.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final DatabaseHelper _databaseHelper;

  ClientRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Client>> getClients() async {
    return await _databaseHelper.getClients();
  }

  @override
  Future<Client?> getClient(int id) async {
    return await _databaseHelper.getClient(id);
  }

  @override
  Future<int> insertClient(Client client) async {
    return await _databaseHelper.insertClient(client);
  }

  @override
  Future<int> updateClient(Client client) async {
    return await _databaseHelper.updateClient(client);
  }

  @override
  Future<int> deleteClient(int id) async {
    return await _databaseHelper.deleteClient(id);
  }
}
