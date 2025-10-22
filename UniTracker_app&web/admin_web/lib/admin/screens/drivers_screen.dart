import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:flutter/services.dart';

class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String driverId;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String status;
  final String? assignedBus;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.driverId,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.status,
    this.assignedBus,
  });
}

final List<Driver> mockDrivers = [
  Driver(
    id: '1',
    name: 'John Smith',
    email: 'john.smith@university.edu',
    phone: '(555) 123-4567',
    driverId: 'D-101',
    licenseNumber: 'DL-12345678',
    licenseExpiry: DateTime(2025, 6, 15),
    status: 'Active',
    assignedBus: 'Bus 101',
  ),
  Driver(
    id: '2',
    name: 'Sarah Johnson',
    email: 'sarah.johnson@university.edu',
    phone: '(555) 234-5678',
    driverId: 'D-102',
    licenseNumber: 'DL-23456789',
    licenseExpiry: DateTime(2024, 8, 22),
    status: 'Active',
    assignedBus: 'Bus 102',
  ),
  Driver(
    id: '3',
    name: 'Michael Brown',
    email: 'michael.brown@university.edu',
    phone: '(555) 345-6789',
    driverId: 'D-103',
    licenseNumber: 'DL-34567890',
    licenseExpiry: DateTime(2025, 2, 18),
    status: 'Active',
    assignedBus: 'Bus 103',
  ),
  Driver(
    id: '4',
    name: 'Emily Davis',
    email: 'emily.davis@university.edu',
    phone: '(555) 456-7890',
    driverId: 'D-104',
    licenseNumber: 'DL-45678901',
    licenseExpiry: DateTime(2024, 11, 30),
    status: 'Active',
    assignedBus: 'Bus 104',
  ),
  Driver(
    id: '5',
    name: 'Robert Wilson',
    email: 'robert.wilson@university.edu',
    phone: '(555) 567-8901',
    driverId: 'D-105',
    licenseNumber: 'DL-56789012',
    licenseExpiry: DateTime(2025, 4, 5),
    status: 'Active',
    assignedBus: 'Bus 105',
  ),
  Driver(
    id: '6',
    name: 'Jennifer Lee',
    email: 'jennifer.lee@university.edu',
    phone: '(555) 678-9012',
    driverId: 'D-106',
    licenseNumber: 'DL-67890123',
    licenseExpiry: DateTime(2024, 10, 12),
    status: 'Inactive',
    assignedBus: null,
  ),
];

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (status == 'Active') {
      bg = const Color(0xFF22C55E);
      fg = Colors.white;
    } else if (status == 'Inactive') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    } else {
      bg = const Color(0xFFFFF7E0);
      fg = const Color(0xFFF59E42);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class EditableField extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;

  const EditableField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.hintText,
    this.inputFormatters,
    Key? key,
  }) : super(key: key);

  @override
  State<EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<EditableField> {
  bool editing = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant EditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          widget.readOnly ? widget.onTap : () => setState(() => editing = true),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(widget.icon, color: AppTheme.secondaryTextColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.label,
                      style: TextStyle(
                          color: AppTheme.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12)),
                  editing && !widget.readOnly
                      ? TextFormField(
                          controller: controller,
                          autofocus: true,
                          style: const TextStyle(fontSize: 15),
                          keyboardType: widget.keyboardType,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                            fillColor: const Color(0xFFEAF0FB),
                            filled: true,
                            hintText: widget.hintText,
                          ),
                          onFieldSubmitted: (val) {
                            widget.onChanged(val);
                            setState(() => editing = false);
                          },
                          onEditingComplete: () =>
                              setState(() => editing = false),
                          inputFormatters: widget.inputFormatters,
                        )
                      : Text(
                          widget.value.isEmpty
                              ? (widget.hintText ?? '')
                              : widget.value,
                          style: const TextStyle(fontSize: 15),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add DateInputFormatter for YYYY-MM-DD
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 4 || i == 6) buffer.write('-');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({Key? key}) : super(key: key);

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen> {
  String _search = '';
  String _statusFilter = 'All';
  int _rowsPerPage = 10;
  final List<String> _statusTabs = ['All', 'Active', 'Inactive', 'On Leave'];

  List<Driver> get filteredDrivers {
    var drivers = mockDrivers;
    if (_statusFilter != 'All') {
      drivers = drivers.where((d) => d.status == _statusFilter).toList();
    }
    if (_search.isNotEmpty) {
      drivers = drivers
          .where((d) =>
              d.name.toLowerCase().contains(_search.toLowerCase()) ||
              d.email.toLowerCase().contains(_search.toLowerCase()) ||
              d.phone.toLowerCase().contains(_search.toLowerCase()) ||
              d.driverId.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return drivers;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isVerySmall = width < 450;
    final isTiny = width < 350;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Drivers',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manage and monitor all drivers in the system.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  isMobile
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: isVerySmall ? double.infinity : 300,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search drivers...',
                                  hintStyle: TextStyle(
                                      color: AppTheme.secondaryTextColor),
                                  prefixIcon: Icon(Icons.search,
                                      color: AppTheme.secondaryTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 0.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 0.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 0.5),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 16),
                                ),
                                onChanged: (value) {
                                  setState(() => _search = value);
                                },
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                ..._statusTabs.map((tab) => ChoiceChip(
                                      label: Text(
                                        tab,
                                        style: TextStyle(
                                          color: _statusFilter == tab
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      selected: _statusFilter == tab,
                                      onSelected: (_) {
                                        setState(() => _statusFilter = tab);
                                      },
                                      selectedColor: AppTheme.primaryColor,
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: _statusFilter == tab
                                              ? AppTheme.primaryColor
                                              : const Color(0xFFE5E7EB),
                                          width: 1.5,
                                        ),
                                      ),
                                      elevation: 0,
                                      showCheckmark: false,
                                    )),
                              ],
                            ),
                            SizedBox(
                              height: 44,
                              width: isVerySmall ? double.infinity : null,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showEditDriverDialog(null, isMobile);
                                },
                                icon: const Icon(Icons.add,
                                    size: 20, color: Colors.white),
                                label: const Text('Add Driver'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search drivers...',
                                  hintStyle: TextStyle(
                                      color: AppTheme.secondaryTextColor),
                                  prefixIcon: Icon(Icons.search,
                                      color: AppTheme.secondaryTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 0.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 0.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 0.5),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 16),
                                ),
                                onChanged: (value) {
                                  setState(() => _search = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                ..._statusTabs.map((tab) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: ChoiceChip(
                                        label: Text(
                                          tab,
                                          style: TextStyle(
                                            color: _statusFilter == tab
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        selected: _statusFilter == tab,
                                        onSelected: (_) {
                                          setState(() => _statusFilter = tab);
                                        },
                                        selectedColor: AppTheme.primaryColor,
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: _statusFilter == tab
                                                ? AppTheme.primaryColor
                                                : const Color(0xFFE5E7EB),
                                            width: 1.5,
                                          ),
                                        ),
                                        elevation: 0,
                                        showCheckmark: false,
                                      ),
                                    )),
                              ],
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showEditDriverDialog(null, isMobile);
                                },
                                icon: const Icon(Icons.add,
                                    size: 20, color: Colors.white),
                                label: const Text('Add Driver'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 32),
                ],
              ),
              // Use card/list layout for all screens below 900px
              width < 900
                  ? Column(
                      children: filteredDrivers
                          .take(_rowsPerPage)
                          .map((driver) => Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor:
                                                const Color(0xFFF1F5F9),
                                            child: Text(
                                              driver.name[0],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B),
                                                  fontSize: 20),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(driver.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16)),
                                                Text(driver.driverId,
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFF64748B),
                                                        fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          // Status badge and actions
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              _StatusBadge(
                                                  status: driver.status),
                                              const SizedBox(height: 8),
                                              PopupMenuButton<int>(
                                                icon: const Icon(
                                                    Icons.more_horiz,
                                                    color: Color(0xFF64748B)),
                                                color: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                itemBuilder: (context) => [
                                                  PopupMenuItem<int>(
                                                    value: 0,
                                                    height: 36,
                                                    child: SizedBox(
                                                      width: 145,
                                                      child: Text(
                                                          'View details',
                                                          style: TextStyle(
                                                              fontSize: 14)),
                                                    ),
                                                  ),
                                                  PopupMenuItem<int>(
                                                    value: 1,
                                                    height: 36,
                                                    child: SizedBox(
                                                      width: 145,
                                                      child: Text('Edit driver',
                                                          style: TextStyle(
                                                              fontSize: 14)),
                                                    ),
                                                  ),
                                                  const PopupMenuDivider(),
                                                  PopupMenuItem<int>(
                                                    value: 2,
                                                    height: 36,
                                                    child: SizedBox(
                                                      width: 145,
                                                      child: Text(
                                                          'Remove driver',
                                                          style: TextStyle(
                                                              color: Colors.red,
                                                              fontSize: 14)),
                                                    ),
                                                  ),
                                                ],
                                                onSelected: (value) {
                                                  switch (value) {
                                                    case 0:
                                                      _showDriverDetailsDialog(
                                                          driver, isMobile);
                                                      break;
                                                    case 1:
                                                      _showEditDriverDialog(
                                                          driver, isMobile);
                                                      break;
                                                    case 2:
                                                      _showRemoveDriverDialog(
                                                          driver);
                                                      break;
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Contact info
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 4,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.email_outlined,
                                                  size: 16,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(driver.email,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black),
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.phone_outlined,
                                                  size: 16,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(driver.phone,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black),
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // License info
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 4,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.badge,
                                                  size: 16,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 4),
                                              Text(driver.licenseNumber,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14)),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.calendar_today,
                                                  size: 14,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 4),
                                              Text(
                                                  'Expires: ${DateFormat('yyyy-MM-dd').format(driver.licenseExpiry)}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Color(0xFF64748B))),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Assigned bus
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_bus,
                                              size: 16,
                                              color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(driver.assignedBus ?? 'None',
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth < 900 ? 0 : 900,
                          maxWidth: constraints.maxWidth,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 24),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                        flex: 3,
                                        child: Text('Driver',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: AppTheme
                                                    .secondaryTextColor))),
                                    Expanded(
                                        flex: 3,
                                        child: Text('Contact',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: AppTheme
                                                    .secondaryTextColor))),
                                    Expanded(
                                        flex: 2,
                                        child: Text('License',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: AppTheme
                                                    .secondaryTextColor))),
                                    Expanded(
                                        flex: 2,
                                        child: Text('Status',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: AppTheme
                                                    .secondaryTextColor))),
                                    Expanded(
                                        flex: 2,
                                        child: Text('Assigned Bus',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: AppTheme
                                                    .secondaryTextColor))),
                                    const SizedBox(width: 40),
                                  ],
                                ),
                              ),
                              const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFE5E7EB)),
                              // Rows
                              ...filteredDrivers
                                  .take(_rowsPerPage)
                                  .map((driver) {
                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18, horizontal: 24),
                                      color: Colors.white,
                                      child: Row(
                                        children: [
                                          // Driver (avatar, name, id)
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 22,
                                                  backgroundColor:
                                                      const Color(0xFFF1F5F9),
                                                  child: Text(
                                                    driver.name[0],
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF64748B),
                                                        fontSize: 20),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Flexible(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(driver.name,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 16),
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                      Text(driver.driverId,
                                                          style: const TextStyle(
                                                              color: Color(
                                                                  0xFF64748B),
                                                              fontSize: 13),
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Contact
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.email_outlined,
                                                        size: 16,
                                                        color:
                                                            Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                        child: Text(
                                                            driver.email,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Colors
                                                                        .black),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis)),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.phone_outlined,
                                                        size: 16,
                                                        color:
                                                            Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                        child: Text(
                                                            driver.phone,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Colors
                                                                        .black),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // License
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(driver.licenseNumber,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15),
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.calendar_today,
                                                        size: 14,
                                                        color:
                                                            Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                          'Expires: ${DateFormat('yyyy-MM-dd').format(driver.licenseExpiry)}',
                                                          style: const TextStyle(
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xFF64748B)),
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Status
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: SizedBox(
                                                height: 28,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: _StatusBadge(
                                                      status: driver.status),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Assigned Bus
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              driver.assignedBus ?? 'None',
                                              style:
                                                  const TextStyle(fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Actions
                                          SizedBox(
                                            width: 40,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: PopupMenuButton<int>(
                                                icon: const Icon(
                                                    Icons.more_horiz,
                                                    color: Color(0xFF64748B)),
                                                color: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                itemBuilder: (context) => [
                                                  PopupMenuItem<int>(
                                                    value: 0,
                                                    height: 36,
                                                    child: SizedBox(
                                                      width: 145,
                                                      child: Text(
                                                          'View details',
                                                          style: TextStyle(
                                                              fontSize: 14)),
                                                    ),
                                                  ),
                                                  PopupMenuItem<int>(
                                                    value: 1,
                                                    height: 36,
                                                    child: SizedBox(
                                                      width: 145,
                                                      child: Text('Edit driver',
                                                          style: TextStyle(
                                                              fontSize: 14)),
                                                    ),
                                                  ),
                                                  const PopupMenuDivider(),
                                                  PopupMenuItem<int>(
                                                    value: 2,
                                                    height: 36,
                                                    child: SizedBox(
                                                      width: 145,
                                                      child: Text(
                                                          'Remove driver',
                                                          style: TextStyle(
                                                              color: Colors.red,
                                                              fontSize: 14)),
                                                    ),
                                                  ),
                                                ],
                                                onSelected: (value) {
                                                  switch (value) {
                                                    case 0:
                                                      _showDriverDetailsDialog(
                                                          driver, isMobile);
                                                      break;
                                                    case 1:
                                                      _showEditDriverDialog(
                                                          driver, isMobile);
                                                      break;
                                                    case 2:
                                                      _showRemoveDriverDialog(
                                                          driver);
                                                      break;
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFE5E7EB)),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              // Flexible pagination row
              isMobile
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Rows per page:'),
                          const SizedBox(height: 8),
                          DropdownButton<int>(
                            value: _rowsPerPage,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 10, child: Text('10')),
                              DropdownMenuItem(value: 20, child: Text('20')),
                              DropdownMenuItem(value: 50, child: Text('50')),
                              DropdownMenuItem(value: 100, child: Text('100')),
                            ],
                            onChanged: (value) {
                              if (value != null)
                                setState(() => _rowsPerPage = value);
                            },
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Rows per page:'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _rowsPerPage,
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10')),
                            DropdownMenuItem(value: 20, child: Text('20')),
                            DropdownMenuItem(value: 50, child: Text('50')),
                            DropdownMenuItem(value: 100, child: Text('100')),
                          ],
                          onChanged: (value) {
                            if (value != null)
                              setState(() => _rowsPerPage = value);
                          },
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  void _showDriverDetailsDialog(Driver driver, bool isMobile) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogWidth =
            MediaQuery.of(context).size.width * (isMobile ? 0.95 : 0.5);
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 32, vertical: isMobile ? 8 : 24),
          child: Container(
            width: dialogWidth,
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 32, vertical: isMobile ? 16 : 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text('Driver Details',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22)),
                      ),
                      _StatusBadge(status: driver.status),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFF1F5F9),
                        child: Text(
                          driver.name[0],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driver.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20)),
                            Text(driver.driverId,
                                style: const TextStyle(
                                    color: Color(0xFF64748B), fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _driverDetailRow(Icons.email_outlined, 'Email', driver.email),
                  _driverDetailRow(Icons.phone_outlined, 'Phone', driver.phone),
                  _driverDetailRow(Icons.description_outlined, 'License',
                      driver.licenseNumber),
                  _driverDetailRow(
                      Icons.calendar_today_outlined,
                      'License Expiry',
                      DateFormat('yyyy-MM-dd').format(driver.licenseExpiry)),
                  _driverDetailRow(Icons.directions_bus, 'Assigned Bus',
                      driver.assignedBus ?? 'None'),
                  const SizedBox(height: 18),
                  const Divider(height: 32),
                  _driverDetailRow(
                      Icons.calendar_today, 'Join Date', '2020-03-10'),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _driverDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.secondaryTextColor, size: 20),
          const SizedBox(width: 14),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: TextStyle(color: AppTheme.textColor, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void _showEditDriverDialog(Driver? driver, bool isMobile) {
    bool isAdd = driver == null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: driver?.name ?? '');
    final emailController = TextEditingController(text: driver?.email ?? '');
    final phoneController = TextEditingController(text: driver?.phone ?? '');
    final licenseController =
        TextEditingController(text: driver?.licenseNumber ?? '');
    final expiryController = TextEditingController(
        text: driver != null
            ? DateFormat('yyyy-MM-dd').format(driver.licenseExpiry)
            : '');
    final statusOptions = ['Active', 'Inactive', 'On Leave'];
    String status = driver?.status ?? 'Active';
    InputDecoration fieldDecoration(String label, IconData icon) =>
        InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.secondaryTextColor),
          filled: true,
          fillColor: const Color(0xFFEAF0FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 18, vertical: isMobile ? 8 : 12),
        );
    showDialog(
      context: context,
      builder: (context) {
        final dialogWidth =
            MediaQuery.of(context).size.width * (isMobile ? 0.98 : 0.5);
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 4 : 32, vertical: isMobile ? 8 : 24),
          child: Container(
            width: dialogWidth,
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 32, vertical: isMobile ? 12 : 28),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                        isAdd ? 'Add Driver' : 'Edit ${driver!.driverId}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22)),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: nameController,
                    decoration: fieldDecoration('Name', Icons.person),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: fieldDecoration('Email', Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter email';
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(value))
                        return 'Please enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: fieldDecoration('Phone', Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter phone';
                      final phoneDigits =
                          value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (phoneDigits.length < 7)
                        return 'Please enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: licenseController,
                    decoration:
                        fieldDecoration('License', Icons.description_outlined),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter license'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: expiryController,
                    decoration: fieldDecoration('License Expiry (YYYY-MM-DD)',
                        Icons.calendar_today_outlined),
                    keyboardType: TextInputType.number,
                    inputFormatters: [DateInputFormatter()],
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter license expiry date';
                      DateTime? parsed = DateTime.tryParse(value);
                      if (parsed == null)
                        return 'Invalid date format. Use YYYY-MM-DD.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 14,
                        vertical: isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user,
                            color: AppTheme.secondaryTextColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Status',
                                  style: TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12)),
                              DropdownButtonFormField<String>(
                                value: status,
                                items: statusOptions
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) => status = v!,
                                dropdownColor: Colors.white,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  hintText: 'Status',
                                  contentPadding: EdgeInsets.zero,
                                  fillColor: Color(0xFFEAF0FB),
                                  filled: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              if (isAdd) {
                                final newDriver = Driver(
                                  id: (mockDrivers.length + 1).toString(),
                                  name: nameController.text,
                                  email: emailController.text,
                                  phone: phoneController.text,
                                  driverId: 'D-${100 + mockDrivers.length + 1}',
                                  licenseNumber: licenseController.text,
                                  licenseExpiry:
                                      DateTime.parse(expiryController.text),
                                  status: status,
                                  assignedBus: null,
                                );
                                _addDriver(newDriver);
                                Navigator.pop(context);
                                return;
                              }
                              setState(() {
                                final idx = mockDrivers
                                    .indexWhere((d) => d.id == driver!.id);
                                if (idx != -1) {
                                  mockDrivers[idx] = Driver(
                                    id: driver!.id,
                                    name: nameController.text,
                                    email: emailController.text,
                                    phone: phoneController.text,
                                    driverId: driver!.driverId,
                                    licenseNumber: licenseController.text,
                                    licenseExpiry:
                                        DateTime.parse(expiryController.text),
                                    status: status,
                                    assignedBus: driver!.assignedBus,
                                  );
                                }
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Driver updated successfully')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(isAdd ? 'Add' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRemoveDriverDialog(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text('Remove Driver'),
        content: Text('Are you sure you want to remove ${driver.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                mockDrivers.removeWhere((d) => d.id == driver.id);
              });
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addDriver(Driver driver) {
    setState(() {
      mockDrivers.insert(0, driver);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Driver ${driver.name} added successfully')),
    );
  }
}
