import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/property_repository.dart';
import '../../rent/data/rent_repository.dart';

class PropertiesListScreen extends ConsumerWidget {
  const PropertiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);
    final rentEntries = ref.watch(currentMonthEntriesProvider);

    final totalBuildings = properties.length;
    final totalRooms = properties.fold(0, (sum, p) => sum + p.totalRooms);
    final occupiedRooms = properties.fold(0, (sum, p) => sum + p.occupiedRooms);
    final vacantRooms = properties.fold(0, (sum, p) => sum + p.vacantRooms);

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: const Text('My Buildings (मेरी बिल्डिंग्स)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'properties_fab',
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => context.push('/add-property'),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Building', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: properties.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apartment_outlined, size: 64, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  const Text(
                    'No buildings added yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your rental buildings and rooms to begin tracking rent.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                    onPressed: () => context.push('/add-property'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Building'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Top Summary Card across all buildings
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2433),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Buildings', '$totalBuildings', Colors.white),
                      Container(width: 1, height: 32, color: AppColors.borderDark),
                      _buildSummaryItem('Total Rooms', '$totalRooms', const Color(0xFF4ADE80)),
                      Container(width: 1, height: 32, color: AppColors.borderDark),
                      _buildSummaryItem('Occupied', '$occupiedRooms', const Color(0xFF22C55E)),
                      Container(width: 1, height: 32, color: AppColors.borderDark),
                      _buildSummaryItem('Vacant', '$vacantRooms', AppColors.textSecondary),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Buildings List
                ...properties.map((prop) {
                  final propEntries = rentEntries.where((e) => e.propertyId == prop.id).toList();
                  final propExpected = propEntries.fold(0, (sum, e) => sum + e.totalPayable);
                  final propReceived = propEntries.fold(0, (sum, e) => sum + e.totalCollected);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderDark, width: 1),
                      ),
                      child: InkWell(
                        onTap: () => context.push('/property-detail/${prop.id}'),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.apartment_rounded,
                                      color: Color(0xFF4ADE80),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prop.name,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${prop.type.displayName} • ${prop.city.isNotEmpty ? prop.city : "India"}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(color: AppColors.borderDark, height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.statusPaidBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${prop.occupiedRooms}/${prop.totalRooms} Rooms Occupied',
                                            style: const TextStyle(
                                              color: Color(0xFF4ADE80),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        if (prop.vacantRooms > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E2838),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${prop.vacantRooms} Vacant',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rent: ${CurrencyFormatter.format(propExpected > 0 ? propExpected : prop.totalExpectedRent)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (propReceived > 0)
                                        Text(
                                          'Rec: ${CurrencyFormatter.format(propReceived)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF4ADE80),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
