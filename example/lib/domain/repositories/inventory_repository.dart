import '../../domain/entities/inventory_item.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getInventoryItems();
  Future<InventoryItem?> getInventoryItem(int id);
  Future<int> insertInventoryItem(InventoryItem item);
  Future<int> updateInventoryItem(InventoryItem item);
  Future<int> deleteInventoryItem(int id);
  Future<int> getLowStockItemsCount();
  Future<int> getTotalItemsCount();
  Future<void> updateStockQuantity(String name, int change);
}
