/// User roles within DM Auto OS.
enum UserRole {
  administrator('administrator', 'Administrator'),
  employee('employee', 'Employee');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.employee,
    );
  }

  bool get isAdministrator => this == UserRole.administrator;
  bool get isEmployee => this == UserRole.employee;
}
