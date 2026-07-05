/// Development priority tier for application modules.
enum ModuleTier {
  /// Active Phase 1 development — prominent in navigation.
  primary,

  /// Available in system but not prioritized (e.g. Workshop, Trading).
  secondary,

  /// Admin-only modules (Users, system settings).
  admin,
}

/// Identifies a functional module within DM Auto OS.
enum AppModuleId {
  dashboard,
  rentals,
  cashbook,
  rentalPeriods,
  vehicleProfitability,
  customers,
  drivers,
  documents,
  vehicles,
  workshop,
  trading,
  reports,
  users,
  settings,
}

/// Metadata for a module including development priority.
class AppModule {
  const AppModule({
    required this.id,
    required this.label,
    required this.tier,
    required this.developmentPriority,
    this.description,
  });

  final AppModuleId id;
  final String label;
  final ModuleTier tier;

  /// Lower number = higher development priority (1 is highest).
  final int developmentPriority;
  final String? description;

  bool get isPrimary => tier == ModuleTier.primary;
  bool get isSecondary => tier == ModuleTier.secondary;

  static const phase1Modules = [
    AppModule(
      id: AppModuleId.rentals,
      label: 'Rentals',
      tier: ModuleTier.primary,
      developmentPriority: 1,
      description: 'Rental agreements and fleet assignments',
    ),
    AppModule(
      id: AppModuleId.cashbook,
      label: 'Cashbook',
      tier: ModuleTier.primary,
      developmentPriority: 2,
      description: 'Income and expense ledger (XAF)',
    ),
    AppModule(
      id: AppModuleId.rentalPeriods,
      label: 'Period Closing',
      tier: ModuleTier.primary,
      developmentPriority: 3,
      description: 'Rental period grouping and closing',
    ),
    AppModule(
      id: AppModuleId.vehicleProfitability,
      label: 'Profitability',
      tier: ModuleTier.primary,
      developmentPriority: 4,
      description: 'Per-vehicle income vs expense analysis',
    ),
    AppModule(
      id: AppModuleId.customers,
      label: 'Customers',
      tier: ModuleTier.primary,
      developmentPriority: 5,
    ),
    AppModule(
      id: AppModuleId.drivers,
      label: 'Drivers',
      tier: ModuleTier.primary,
      developmentPriority: 6,
    ),
    AppModule(
      id: AppModuleId.documents,
      label: 'Documents',
      tier: ModuleTier.primary,
      developmentPriority: 7,
    ),
  ];

  static const workshopModule = AppModule(
    id: AppModuleId.workshop,
    label: 'Workshop',
    tier: ModuleTier.secondary,
    developmentPriority: 20,
    description: 'Optional service orders — Phase 2 priority',
  );

  static AppModule? findById(AppModuleId id) {
    if (id == AppModuleId.workshop) return workshopModule;
    for (final module in phase1Modules) {
      if (module.id == id) return module;
    }
    return null;
  }
}
