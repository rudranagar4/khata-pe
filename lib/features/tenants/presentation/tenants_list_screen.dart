import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/whatsapp_service.dart';
import '../data/tenant_repository.dart';
import '../../properties/data/property_repository.dart';
import '../../rent/data/rent_repository.dart';

class TenantsListScreen extends ConsumerStatefulWidget {
  const TenantsListScreen({super.key});

  @override
  ConsumerState<TenantsListScreen> createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends ConsumerState<TenantsListScreen> {
  final _searchController = TextEditingController();
  bool _showActiveOnly = true;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTenants = ref.watch(tenantsProvider);
    final properties = ref.watch(propertiesProvider);
    final rentEntries = ref.watch(currentMonthEntriesProvider);

    final filtered = allTenants.where((t) {
      if (_showActiveOnly && !t.isActive) return false;
      if (!_showActiveOnly && t.isActive) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = t.name.toLowerCase().contains(query);
        final matchesPhone = t.phone.contains(query);
        return matchesName || matchesPhone;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: const Text('Tenants (किरायेदार)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tenants_fab',
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => context.push('/add-tenant'),
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Add Tenant', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Active vs Past Filter Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: [
                _buildPillTab(
                  'Active Tenants (${allTenants.where((t) => t.isActive).length})',
                  _showActiveOnly,
                  () => setState(() => _showActiveOnly = true),
                ),
                const SizedBox(width: 10),
                _buildPillTab(
                  'Past / Moved Out (${allTenants.where((t) => !t.isActive).length})',
                  !_showActiveOnly,
                  () => setState(() => _showActiveOnly = false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No tenants found for "$_searchQuery"'
                              : (_showActiveOnly ? 'No active tenants' : 'No past tenants'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (_showActiveOnly && allTenants.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                            onPressed: () => context.push('/add-tenant'),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Tenant'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tenant = filtered[index];
                      final prop = properties.where((p) => p.id == tenant.propertyId).firstOrNull;
                      final unit = prop?.units.where((u) => u.id == tenant.unitId).firstOrNull;

                      final currentEntry = rentEntries.where((e) => e.tenantId == tenant.id).firstOrNull;
                      final balanceDue = currentEntry?.balanceDue ?? 0;
                      final isExpiringSoon = tenant.isAgreementExpiringWithin(30);

                      final avatarBg = index % 3 == 0
                          ? const Color(0xFFC7EBD7)
                          : (index % 3 == 1 ? const Color(0xFFFDE68A) : const Color(0xFFDBEAFE));
                      final avatarFg = index % 3 == 0
                          ? const Color(0xFF0F5132)
                          : (index % 3 == 1 ? const Color(0xFF92400E) : const Color(0xFF1E40AF));

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: InkWell(
                          onTap: () => context.push('/tenant-detail/${tenant.id}'),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: avatarBg,
                                      child: Text(
                                        tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : 'T',
                                        style: TextStyle(
                                          color: avatarFg,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tenant.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${prop?.name ?? ""} • ${unit?.roomDisplayName ?? ""}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${CurrencyFormatter.format(tenant.monthlyRent)}/mo',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (balanceDue > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Due: ${CurrencyFormatter.format(balanceDue)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          )
                                        else if (tenant.isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF16A34A),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Cleared',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),

                                if (isExpiringSoon) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38290E),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFF59E0B)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.alarm, size: 16, color: Color(0xFFFBBF24)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Rent Agreement Expiring Soon!',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFBBF24),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),
                                const Divider(color: AppColors.borderDark, height: 1),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Due Day: ${tenant.rentDueDay}th of month',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.call_outlined, color: Color(0xFF4ADE80), size: 20),
                                          onPressed: () => WhatsAppService.makePhoneCall(tenant.phone),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
                                          onPressed: () {
                                            WhatsAppService.sendWhatsAppReminder(
                                              phone: tenant.phone,
                                              message: 'Namaste ${tenant.name} ji',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF16A34A) : AppColors.cardDarkElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF16A34A) : AppColors.borderDark,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
