import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/whatsapp_service.dart';
import '../data/property_repository.dart';
import '../domain/models/property.dart';
import '../domain/models/unit.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../tenants/presentation/add_edit_tenant_screen.dart';
import '../../rent/data/rent_repository.dart';
import '../../rent/domain/models/rent_entry.dart';
import '../../rent/presentation/add_payment_dialog.dart';
import 'add_edit_property_screen.dart';
import 'add_edit_unit_screen.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  UnitStatus? _statusFilter; // null = all, occupied, vacant

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final property = properties.where((p) => p.id == widget.propertyId).firstOrNull;

    if (property == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldDark,
        appBar: AppBar(title: const Text('Building')),
        body: const Center(
          child: Text('Building not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final tenants = ref.watch(tenantsProvider);
    final rentEntries = ref.watch(rentLedgerProvider);

    final currentMonthKey = DateFormatter.toMonthKey(DateTime.now());
    final propEntries = rentEntries.where((e) => e.propertyId == property.id && e.month == currentMonthKey).toList();
    final totalCollected = propEntries.fold(0, (sum, e) => sum + e.totalCollected);
    final totalExpected = propEntries.fold(0, (sum, e) => sum + e.totalPayable);
    final totalPending = (totalExpected - totalCollected).clamp(0, 99999999);

    final filteredUnits = property.units.where((u) {
      if (_statusFilter == null) return true;
      return u.status == _statusFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: Text(property.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF4ADE80)),
            tooltip: 'Add Tenant to this Building',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditTenantScreen(
                    initialPropertyId: property.id,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Edit Building',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditPropertyScreen(propertyToEdit: property),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.statusOverdue),
            tooltip: 'Delete Building',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.cardDark,
                  title: const Text('Delete Building?'),
                  content: Text(
                    'Are you sure you want to delete "${property.name}"? '
                    'All rooms and rent records for this building will be removed.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(propertiesProvider.notifier).deleteProperty(property.id);
                if (context.mounted) {
                  context.pop();
                }
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'property_detail_fab',
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditUnitScreen(propertyId: property.id),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Room (कमरा जोड़ें)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Building Overview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.apartment_rounded, color: Color(0xFF4ADE80), size: 22),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    property.type.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusPaidBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${property.occupiedRooms}/${property.totalRooms} Occupied',
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (property.address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${property.address}, ${property.city}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (property.notes != null && property.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      property.notes!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Financial Snapshot for this Building
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2433),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'Collected',
                      CurrencyFormatter.format(totalCollected),
                      const Color(0xFF4ADE80),
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.borderDark),
                  Expanded(
                    child: _buildStatColumn(
                      'Pending',
                      CurrencyFormatter.format(totalPending),
                      totalPending > 0 ? const Color(0xFFF59E0B) : Colors.white,
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.borderDark),
                  Expanded(
                    child: _buildStatColumn(
                      'Potential',
                      CurrencyFormatter.format(property.fullPotentialRent),
                      Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Filter Chips: All Rooms / Occupied / Vacant
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Rooms (${property.units.length} कमरे)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4ADE80),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditTenantScreen(
                              initialPropertyId: property.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 15),
                      label: const Text('Tenant', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditUnitScreen(propertyId: property.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 15),
                      label: const Text('Room', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${property.totalRooms})', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Occupied (${property.occupiedRooms})', UnitStatus.occupied),
                  const SizedBox(width: 8),
                  _buildFilterChip('Vacant (${property.vacantRooms})', UnitStatus.vacant),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. Rooms List
            if (filteredUnits.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(36),
                child: Column(
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      property.units.isEmpty
                          ? 'No rooms added to this building yet'
                          : 'No rooms match this filter',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap "+ Add Room" to add rooms and collect rent',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredUnits.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final room = filteredUnits[index];
                  final occupant = tenants
                      .where((t) => t.propertyId == property.id && t.unitId == room.id && t.isActive)
                      .firstOrNull;

                  final rentEntry = occupant != null
                      ? propEntries.where((e) => e.unitId == room.id && e.tenantId == occupant.id).firstOrNull
                      : null;

                  return _buildRoomCard(
                    context: context,
                    property: property,
                    room: room,
                    occupant: occupant,
                    rentEntry: rentEntry,
                    currentMonthKey: currentMonthKey,
                  );
                },
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, UnitStatus? status) {
    final isSelected = _statusFilter == status;
    return InkWell(
      onTap: () => setState(() => _statusFilter = status),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF133824) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF22C55E) : AppColors.borderDark,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4ADE80) : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard({
    required BuildContext context,
    required Property property,
    required PropertyUnit room,
    required dynamic occupant,
    required RentEntry? rentEntry,
    required String currentMonthKey,
  }) {
    final isOccupied = room.isOccupied && occupant != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOccupied ? AppColors.statusPaidBg : const Color(0xFF1E2838),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.meeting_room_rounded,
                        color: isOccupied ? const Color(0xFF4ADE80) : Colors.grey,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.roomDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${room.floor ?? "1st Floor"} • ${room.roomType ?? "Room"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Occupancy Status Badge & Menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOccupied ? AppColors.statusPaidBg : const Color(0xFF1E2838),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOccupied ? 'Occupied' : 'Vacant',
                      style: TextStyle(
                        color: isOccupied ? const Color(0xFF4ADE80) : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                    color: AppColors.cardDarkElevated,
                    onSelected: (val) async {
                      if (val == 'tenant_action') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditTenantScreen(
                              initialPropertyId: property.id,
                              initialUnitId: room.id,
                            ),
                          ),
                        );
                      } else if (val == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditUnitScreen(
                              propertyId: property.id,
                              unitToEdit: room,
                            ),
                          ),
                        );
                      } else if (val == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.cardDark,
                            title: const Text('Delete Room?'),
                            content: Text('Delete "${room.roomDisplayName}" from this building?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(propertiesProvider.notifier).deleteUnit(property.id, room.id);
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'tenant_action',
                        child: Text(
                          isOccupied ? 'Change / Reassign Tenant' : 'Add Tenant to Room',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Room Details', style: TextStyle(color: Colors.white)),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Room', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 12),

          // Room Details & Tenant Info
          if (isOccupied) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFC7EBD7),
                  child: Text(
                    occupant.name.isNotEmpty ? occupant.name[0].toUpperCase() : 'T',
                    style: const TextStyle(color: Color(0xFF0F5132), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occupant.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (occupant.phone.isNotEmpty)
                        Text(
                          occupant.phone,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (occupant.phone.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.call_outlined, color: Color(0xFF4ADE80), size: 18),
                    onPressed: () => WhatsAppService.makePhoneCall(occupant.phone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF22C55E), size: 18),
                    onPressed: () => WhatsAppService.sendWhatsAppReminder(phone: occupant.phone, message: ''),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Rent & Payment Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rent: ${CurrencyFormatter.format(room.monthlyRent)}/mo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (room.meterNumber != null && room.meterNumber!.isNotEmpty)
                        Text(
                          '⚡ Sub-meter: ${room.meterNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Rent Status Badge
                if (rentEntry != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rentEntry.status == RentStatus.paid
                          ? AppColors.statusPaidBg
                          : (rentEntry.status == RentStatus.partiallyPaid
                              ? AppColors.statusPartialBg
                              : AppColors.statusOverdueBg),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rentEntry.status == RentStatus.paid
                          ? '✓ Rent Paid'
                          : (rentEntry.status == RentStatus.partiallyPaid
                              ? 'Partial (Bal: ${CurrencyFormatter.format(rentEntry.balanceDue)})'
                              : 'Due: ${CurrencyFormatter.format(rentEntry.balanceDue)}'),
                      style: TextStyle(
                        color: rentEntry.status == RentStatus.paid
                            ? const Color(0xFF4ADE80)
                            : (rentEntry.status == RentStatus.partiallyPaid
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444)),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick "Collect Room Rent" Action
            if (isOccupied && (rentEntry == null || rentEntry.status != RentStatus.paid))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (rentEntry != null) {
                      AddPaymentDialog.show(context, rentEntry);
                    } else if (occupant != null) {
                      final newEntry = await ref
                          .read(rentLedgerProvider.notifier)
                          .addOrUpdateEntryForTenant(occupant, currentMonthKey);
                      if (context.mounted) {
                        AddPaymentDialog.show(context, newEntry);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(
                    rentEntry != null
                        ? 'Collect Rent for ${room.roomDisplayName} (${CurrencyFormatter.format(rentEntry.balanceDue)})'
                        : 'Collect Rent for ${room.roomDisplayName} (${CurrencyFormatter.format(room.monthlyRent)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
          ] else ...[
            // Vacant Room
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rent: ${CurrencyFormatter.format(room.monthlyRent)}/mo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Deposit: ${CurrencyFormatter.format(room.securityDeposit)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditTenantScreen(
                          initialPropertyId: property.id,
                          initialUnitId: room.id,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2433),
                    foregroundColor: const Color(0xFF4ADE80),
                    side: const BorderSide(color: Color(0xFF22C55E)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 15),
                  label: const Text('Add Tenant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
