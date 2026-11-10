import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/property_repository.dart';
import '../domain/models/property.dart';

class AddEditPropertyScreen extends ConsumerStatefulWidget {
  final Property? propertyToEdit;

  const AddEditPropertyScreen({super.key, this.propertyToEdit});

  @override
  ConsumerState<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends ConsumerState<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _notesController;

  // Room generation for buildings
  bool _autoCreateRooms = true;
  late final TextEditingController _roomCountController;
  late final TextEditingController _defaultRentController;
  late final TextEditingController _defaultDepositController;
  late final TextEditingController _startingRoomNumController;

  PropertyType _selectedType = PropertyType.building;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prop = widget.propertyToEdit;
    _nameController = TextEditingController(text: prop?.name ?? '');
    _addressController = TextEditingController(text: prop?.address ?? '');
    _cityController = TextEditingController(text: prop?.city ?? '');
    _notesController = TextEditingController(text: prop?.notes ?? '');

    _roomCountController = TextEditingController(text: '4');
    _defaultRentController = TextEditingController(text: '8000');
    _defaultDepositController = TextEditingController(text: '16000');
    _startingRoomNumController = TextEditingController(text: '101');

    if (prop != null) {
      _selectedType = prop.type;
      _autoCreateRooms = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    _roomCountController.dispose();
    _defaultRentController.dispose();
    _defaultDepositController.dispose();
    _startingRoomNumController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.propertyToEdit != null) {
        final updated = widget.propertyToEdit!.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
        await ref.read(propertiesProvider.notifier).updateProperty(updated);
      } else {
        final roomCount = _autoCreateRooms ? (int.tryParse(_roomCountController.text.trim()) ?? 0) : 0;
        final defaultRent = _autoCreateRooms ? CurrencyFormatter.parse(_defaultRentController.text) : 0;
        final defaultDeposit = _autoCreateRooms ? CurrencyFormatter.parse(_defaultDepositController.text) : 0;
        final startNum = _autoCreateRooms ? (int.tryParse(_startingRoomNumController.text.trim()) ?? 101) : 101;

        await ref.read(propertiesProvider.notifier).addProperty(
              name: _nameController.text.trim(),
              type: _selectedType,
              address: _addressController.text.trim(),
              city: _cityController.text.trim(),
              notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
              initialRoomCount: roomCount,
              defaultRoomRent: defaultRent,
              defaultRoomDeposit: defaultDeposit,
              startingRoomNumber: startNum,
            );
      }

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(
              widget.propertyToEdit != null
                  ? 'Building updated successfully!'
                  : (_autoCreateRooms
                      ? 'Building & ${_roomCountController.text} rooms created!'
                      : 'Building added successfully!'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.propertyToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Building (बिल्डिंग)' : 'Add Building (नई बिल्डिंग जोड़ें)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Building Name
              const Text(
                'Building Name (बिल्डिंग का नाम) *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Sharma Niwas, Building No. 1, Krishna Bhawan',
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter building name' : null,
              ),

              const SizedBox(height: 18),

              // Property Type Dropdown
              const Text(
                'Building / Property Type *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<PropertyType>(
                initialValue: _selectedType,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(),
                items: PropertyType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),

              const SizedBox(height: 18),

              // Address & City
              const Text(
                'Address / Landmark',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Plot 45, Sector 15, Near Main Market',
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'City',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cityController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Noida, Delhi, Mumbai, Lucknow',
                ),
              ),

              const SizedBox(height: 22),

              // Setup Rooms Section (When creating new building)
              if (!isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2433),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.meeting_room_rounded, color: Color(0xFF4ADE80), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Setup Rooms (कमरों का सेटअप)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _autoCreateRooms,
                            activeColor: const Color(0xFF22C55E),
                            onChanged: (val) => setState(() => _autoCreateRooms = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _autoCreateRooms
                            ? 'Auto-creates rooms with sequential numbers & default rent'
                            : 'Create empty building; add rooms one by one later',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),

                      if (_autoCreateRooms) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Rooms *',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _roomCountController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(hintText: 'e.g. 6'),
                                    validator: (val) {
                                      if (!_autoCreateRooms) return null;
                                      final count = int.tryParse(val ?? '');
                                      if (count == null || count <= 0) return 'Min 1';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Room #',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _startingRoomNumController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(hintText: 'e.g. 101'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rent / Room (₹) *',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _defaultRentController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(prefixText: '₹ '),
                                    validator: (val) {
                                      if (!_autoCreateRooms) return null;
                                      return CurrencyFormatter.parse(val ?? '') <= 0 ? 'Enter rent' : null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Deposit / Room (₹)',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _defaultDepositController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(prefixText: '₹ '),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Notes
              const Text(
                'Notes / Building Details',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. 3 floors, water tank on roof, electric sub-meters installed',
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing
                              ? 'Save Building Changes'
                              : (_autoCreateRooms
                                  ? '✓ Create Building & Generate Rooms'
                                  : '✓ Create Building'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
