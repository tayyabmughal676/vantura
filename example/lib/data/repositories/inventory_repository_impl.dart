import '../../data/database/database_helper.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final DatabaseHelper _databaseHelper;

  InventoryRepositoryImpl(this._databaseHelper);

  @override
  Future<List<InventoryItem>> getInventoryItems() async {
    return await _databaseHelper.getInventoryItems();
  }

  @override
  Future<InventoryItem?> getInventoryItem(int id) async {
    return await _databaseHelper.getInventoryItem(id);
  }

  @override
  Future<int> insertInventoryItem(InventoryItem item) async {
    return await _databaseHelper.insertInventoryItem(item);
  }

  @override
  Future<int> updateInventoryItem(InventoryItem item) async {
    return await _databaseHelper.updateInventoryItem(item);
  }

  @override
  Future<int> deleteInventoryItem(int id) async {
    return await _databaseHelper.deleteInventoryItem(id);
  }

  @override
  Future<int> getLowStockItemsCount() async {
    return await _databaseHelper.getLowStockItemsCount();
  }

  @override
  Future<int> getTotalItemsCount() async {
    return await _databaseHelper.getTotalInventoryItems();
  }

  @override
  Future<void> updateStockQuantity(String name, int change) async {
    await _databaseHelper.updateStockQuantity(name, change);
  }
}
