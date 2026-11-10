import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/property_repository.dart';
import '../domain/models/unit.dart';

class AddEditUnitScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final PropertyUnit? unitToEdit;

  const AddEditUnitScreen({
    super.key,
    required this.propertyId,
    this.unitToEdit,
  });

  @override
  ConsumerState<AddEditUnitScreen> createState() => _AddEditUnitScreenState();
}

class _AddEditUnitScreenState extends ConsumerState<AddEditUnitScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late final TextEditingController _areaController;
  late final TextEditingController _meterController;
  late final TextEditingController _notesController;

  String _selectedFloor = '1st Floor';
  String _selectedRoomType = 'Single Room (1RK)';
  UnitStatus _status = UnitStatus.vacant;
  bool _isSaving = false;

  final List<String> _floors = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
    '4th Floor',
    'Rooftop',
    'Basement',
  ];

  final List<String> _roomTypes = [
    'Single Room (1RK)',
    'Double Room / Sharing',
    'Room with Attached Bath',
    'Balcony Room',
    '1BHK Room Set',
    'Commercial Room / Shop',
  ];

  @override
  void initState() {
    super.initState();
    final unit = widget.unitToEdit;
    _nameController = TextEditingController(text: unit?.unitName ?? '');
    _rentController = TextEditingController(text: unit != null ? unit.monthlyRent.toString() : '8000');
    _depositController = TextEditingController(text: unit != null ? unit.securityDeposit.toString() : '16000');
    _areaController = TextEditingController(text: unit?.areaSqFt != null ? unit!.areaSqFt.toString() : '');
    _meterController = TextEditingController(text: unit?.meterNumber ?? '');
    _notesController = TextEditingController(text: unit?.notes ?? '');

    if (unit != null) {
      _status = unit.status;
      if (unit.floor != null && _floors.contains(unit.floor)) {
        _selectedFloor = unit.floor!;
      }
      if (unit.roomType != null && _roomTypes.contains(unit.roomType)) {
        _selectedRoomType = unit.roomType!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _areaController.dispose();
    _meterController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final monthlyRent = CurrencyFormatter.parse(_rentController.text);
      final deposit = CurrencyFormatter.parse(_depositController.text);
      final area = double.tryParse(_areaController.text.trim());
      final meter = _meterController.text.trim().isNotEmpty ? _meterController.text.trim() : null;
      final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

      if (widget.unitToEdit != null) {
        final updated = widget.unitToEdit!.copyWith(
          unitName: _nameController.text.trim(),
          monthlyRent: monthlyRent,
          securityDeposit: deposit,
          status: _status,
          areaSqFt: area,
          floor: _selectedFloor,
          roomType: _selectedRoomType,
          meterNumber: meter,
          notes: notes,
        );
        await ref.read(propertiesProvider.notifier).updateUnit(widget.propertyId, updated);
      } else {
        const uuid = Uuid();
        final newUnit = PropertyUnit(
          id: uuid.v4(),
          propertyId: widget.propertyId,
          unitName: _nameController.text.trim(),
          monthlyRent: monthlyRent,
          securityDeposit: deposit,
          status: _status,
          areaSqFt: area,
          floor: _selectedFloor,
          roomType: _selectedRoomType,
          meterNumber: meter,
          notes: notes,
        );
        await ref.read(propertiesProvider.notifier).addUnit(widget.propertyId, newUnit);
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
              widget.unitToEdit != null ? 'Room updated!' : 'Room added to building!',
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
    final isEditing = widget.unitToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Room (कमरा)' : 'Add Room (कमरा जोड़ें)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Number / Name
              const Text(
                'Room Number / Name (कमरा नंबर) *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Room 101, Room 102, Room 1',
                  prefixIcon: Icon(Icons.meeting_room_outlined, color: Color(0xFF4ADE80), size: 20),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter room number/name' : null,
              ),

              const SizedBox(height: 18),

              // Floor & Room Type Selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Floor (मंजिल) *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedFloor,
                          dropdownColor: AppColors.cardDark,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(),
                          items: _floors.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFloor = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Room Type *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedRoomType,
                          dropdownColor: AppColors.cardDark,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(),
                          items: _roomTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRoomType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Monthly Rent & Deposit
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Rent (₹) *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _rentController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(prefixText: '₹ '),
                          validator: (val) =>
                              CurrencyFormatter.parse(val ?? '') <= 0 ? 'Enter rent' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security Deposit (₹)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _depositController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(prefixText: '₹ '),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Electricity Sub-meter & Area
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sub-Meter No. (बिजली मीटर)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _meterController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'e.g. M-101',
                            prefixIcon: Icon(Icons.electric_meter_outlined, size: 18, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Room Area (sq ft)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _areaController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'e.g. 250',
                            suffixText: 'sq ft',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Status Toggle
              const Text(
                'Occupancy Status',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _status = UnitStatus.vacant),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _status == UnitStatus.vacant
                              ? const Color(0xFF1E2838)
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _status == UnitStatus.vacant
                                ? AppColors.textSecondary
                                : AppColors.borderDark,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Vacant (खाली है)',
                            style: TextStyle(
                              color: _status == UnitStatus.vacant ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _status = UnitStatus.occupied),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _status == UnitStatus.occupied
                              ? AppColors.statusPaidBg
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _status == UnitStatus.occupied
                                ? const Color(0xFF22C55E)
                                : AppColors.borderDark,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Occupied (किरायेदार है)',
                            style: TextStyle(
                              color: _status == UnitStatus.occupied ? const Color(0xFF4ADE80) : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Notes
              const Text(
                'Room Notes / Amenities',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Geyser, fan, window towards street, 1 bed',
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
                          isEditing ? 'Save Room Details' : '✓ Add Room (कमरा जोड़ें)',
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
