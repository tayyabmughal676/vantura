// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(databaseHelper)
final databaseHelperProvider = DatabaseHelperProvider._();

final class DatabaseHelperProvider
    extends $FunctionalProvider<DatabaseHelper, DatabaseHelper, DatabaseHelper>
    with $Provider<DatabaseHelper> {
  DatabaseHelperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseHelperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHelperHash();

  @$internal
  @override
  $ProviderElement<DatabaseHelper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseHelper create(Ref ref) {
    return databaseHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseHelper>(value),
    );
  }
}

String _$databaseHelperHash() => r'd9a91b257d3ed9a4f2d87bd829e17dc900678685';

@ProviderFor(clientRepository)
final clientRepositoryProvider = ClientRepositoryProvider._();

final class ClientRepositoryProvider
    extends
        $FunctionalProvider<
          ClientRepository,
          ClientRepository,
          ClientRepository
        >
    with $Provider<ClientRepository> {
  ClientRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClientRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClientRepository create(Ref ref) {
    return clientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClientRepository>(value),
    );
  }
}

String _$clientRepositoryHash() => r'6afacfba085630c2855730096769f1b5e18a72d3';

@ProviderFor(inventoryRepository)
final inventoryRepositoryProvider = InventoryRepositoryProvider._();

final class InventoryRepositoryProvider
    extends
        $FunctionalProvider<
          InventoryRepository,
          InventoryRepository,
          InventoryRepository
        >
    with $Provider<InventoryRepository> {
  InventoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<InventoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryRepository create(Ref ref) {
    return inventoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryRepository>(value),
    );
  }
}

String _$inventoryRepositoryHash() =>
    r'd4c7004795d4296e180ad2f3dcfd69b6b34c079a';

@ProviderFor(invoiceRepository)
final invoiceRepositoryProvider = InvoiceRepositoryProvider._();

final class InvoiceRepositoryProvider
    extends
        $FunctionalProvider<
          InvoiceRepository,
          InvoiceRepository,
          InvoiceRepository
        >
    with $Provider<InvoiceRepository> {
  InvoiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<InvoiceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InvoiceRepository create(Ref ref) {
    return invoiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvoiceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvoiceRepository>(value),
    );
  }
}

String _$invoiceRepositoryHash() => r'7fdd1b4af6e70fa5072be44a46cac50c1b708694';

@ProviderFor(ledgerRepository)
final ledgerRepositoryProvider = LedgerRepositoryProvider._();

final class LedgerRepositoryProvider
    extends
        $FunctionalProvider<
          LedgerRepository,
          LedgerRepository,
          LedgerRepository
        >
    with $Provider<LedgerRepository> {
  LedgerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerRepositoryHash();

  @$internal
  @override
  $ProviderElement<LedgerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LedgerRepository create(Ref ref) {
    return ledgerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerRepository>(value),
    );
  }
}

String _$ledgerRepositoryHash() => r'9d6a79706f85bc1de8fb5b97ae7f6c85e582938e';

@ProviderFor(Clients)
final clientsProvider = ClientsProvider._();

final class ClientsProvider
    extends $AsyncNotifierProvider<Clients, List<Client>> {
  ClientsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientsHash();

  @$internal
  @override
  Clients create() => Clients();
}

String _$clientsHash() => r'312ec1d7eded5667248e0a544e9fd8b05c9b5613';

abstract class _$Clients extends $AsyncNotifier<List<Client>> {
  FutureOr<List<Client>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Client>>, List<Client>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Client>>, List<Client>>,
              AsyncValue<List<Client>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(Inventory)
final inventoryProvider = InventoryProvider._();

final class InventoryProvider
    extends $AsyncNotifierProvider<Inventory, List<InventoryItem>> {
  InventoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryHash();

  @$internal
  @override
  Inventory create() => Inventory();
}

String _$inventoryHash() => r'eed6cf0d6de24e9f2afd5c47590ca4a45baa7b35';

abstract class _$Inventory extends $AsyncNotifier<List<InventoryItem>> {
  FutureOr<List<InventoryItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<InventoryItem>>, List<InventoryItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<InventoryItem>>, List<InventoryItem>>,
              AsyncValue<List<InventoryItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(Invoices)
final invoicesProvider = InvoicesProvider._();

final class InvoicesProvider
    extends $AsyncNotifierProvider<Invoices, List<Invoice>> {
  InvoicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoicesHash();

  @$internal
  @override
  Invoices create() => Invoices();
}

String _$invoicesHash() => r'2df262419a08fcb0529f3b4ba90b43cc60b6903b';

abstract class _$Invoices extends $AsyncNotifier<List<Invoice>> {
  FutureOr<List<Invoice>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Invoice>>, List<Invoice>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Invoice>>, List<Invoice>>,
              AsyncValue<List<Invoice>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(LedgerEntries)
final ledgerEntriesProvider = LedgerEntriesProvider._();

final class LedgerEntriesProvider
    extends $AsyncNotifierProvider<LedgerEntries, List<LedgerEntry>> {
  LedgerEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerEntriesHash();

  @$internal
  @override
  LedgerEntries create() => LedgerEntries();
}

String _$ledgerEntriesHash() => r'9d697ec705de1b167c9054a4486a2aa99c766e44';

abstract class _$LedgerEntries extends $AsyncNotifier<List<LedgerEntry>> {
  FutureOr<List<LedgerEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<LedgerEntry>>, List<LedgerEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LedgerEntry>>, List<LedgerEntry>>,
              AsyncValue<List<LedgerEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(totalIncome)
final totalIncomeProvider = TotalIncomeProvider._();

final class TotalIncomeProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  TotalIncomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalIncomeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalIncomeHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return totalIncome(ref);
  }
}

String _$totalIncomeHash() => r'6e73872f84dcf472b6346fa34e544cd79d603564';

@ProviderFor(totalExpenses)
final totalExpensesProvider = TotalExpensesProvider._();

final class TotalExpensesProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  TotalExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalExpensesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalExpensesHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return totalExpenses(ref);
  }
}

String _$totalExpensesHash() => r'2d9b2beb0bd6ef04aa2afe5c5be247c6cd7315d8';

@ProviderFor(lowStockCount)
final lowStockCountProvider = LowStockCountProvider._();

final class LowStockCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  LowStockCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lowStockCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lowStockCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return lowStockCount(ref);
  }
}

String _$lowStockCountHash() => r'feec99a75d346b58da8bd8e3d5bafbaa017a95e3';

@ProviderFor(totalInventoryCount)
final totalInventoryCountProvider = TotalInventoryCountProvider._();

final class TotalInventoryCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  TotalInventoryCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalInventoryCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalInventoryCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return totalInventoryCount(ref);
  }
}

String _$totalInventoryCountHash() =>
    r'0e192cd43e8f0f03fa52430a1273adbe68a1c3fa';
