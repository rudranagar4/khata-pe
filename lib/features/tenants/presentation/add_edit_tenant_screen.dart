import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/tenant_repository.dart';
import '../domain/models/tenant.dart';
import '../../properties/data/property_repository.dart';
import '../../properties/domain/models/unit.dart';
import '../../rent/data/rent_repository.dart';

class AddEditTenantScreen extends ConsumerStatefulWidget {
  final Tenant? tenantToEdit;
  final String? initialPropertyId;
  final String? initialUnitId;

  const AddEditTenantScreen({
    super.key,
    this.tenantToEdit,
    this.initialPropertyId,
    this.initialUnitId,
  });

  @override
  ConsumerState<AddEditTenantScreen> createState() => _AddEditTenantScreenState();
}

class _AddEditTenantScreenState extends ConsumerState<AddEditTenantScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _altPhoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _notesController;

  String? _selectedPropertyId;
  String? _selectedUnitId;
  String _selectedIdType = 'Aadhaar Card';

  DateTime _moveInDate = DateTime.now();
  DateTime? _agreementEndDate;
  bool _isSaving = false;

  final List<String> _idProofTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Voter ID Card',
    'Driving License',
    'Passport',
    'Other ID',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.tenantToEdit;
    _nameController = TextEditingController(text: t?.name ?? '');
    _phoneController = TextEditingController(text: t?.phone ?? '');
    _altPhoneController = TextEditingController(text: t?.altPhone ?? '');
    _emailController = TextEditingController(text: t?.email ?? '');
    _idNumberController = TextEditingController(text: t?.idProofNumber ?? '');
    _rentController = TextEditingController(text: t != null ? t.monthlyRent.toString() : '');
    _depositController = TextEditingController(text: t != null ? t.securityDeposit.toString() : '0');
    _dueDayController = TextEditingController(text: t != null ? t.rentDueDay.toString() : '5');
    _notesController = TextEditingController(text: t?.notes ?? '');

    if (t != null) {
      _selectedPropertyId = t.propertyId;
      _selectedUnitId = t.unitId;
      _selectedIdType = t.idProofType ?? 'Aadhaar Card';
      _moveInDate = t.moveInDate;
      _agreementEndDate = t.agreementEndDate;
    } else {
      _selectedPropertyId = widget.initialPropertyId;
      _selectedUnitId = widget.initialUnitId;
      if (widget.initialPropertyId != null && widget.initialUnitId != null) {
        final props = ref.read(propertiesProvider);
        final prop = props.where((p) => p.id == widget.initialPropertyId).firstOrNull;
        final unit = prop?.units.where((u) => u.id == widget.initialUnitId).firstOrNull;
        if (unit != null) {
          _rentController.text = unit.monthlyRent.toString();
          _depositController.text = unit.securityDeposit.toString();
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPropertyId == null || _selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select building and room for the tenant')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final monthlyRent = CurrencyFormatter.parse(_rentController.text);
      final deposit = CurrencyFormatter.parse(_depositController.text);
      final dueDay = int.tryParse(_dueDayController.text.trim())?.clamp(1, 31) ?? 5;

      if (widget.tenantToEdit != null) {
        final updated = widget.tenantToEdit!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          altPhone: _altPhoneController.text.trim().isNotEmpty ? _altPhoneController.text.trim() : null,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          propertyId: _selectedPropertyId!,
          unitId: _selectedUnitId!,
          idProofType: _selectedIdType,
          idProofNumber: _idNumberController.text.trim().isNotEmpty ? _idNumberController.text.trim() : null,
          moveInDate: _moveInDate,
          agreementEndDate: _agreementEndDate,
          monthlyRent: monthlyRent,
          securityDeposit: deposit,
          rentDueDay: dueDay,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
        await ref.read(tenantsProvider.notifier).updateTenant(updated);
      } else {
        const uuid = Uuid();
        final newTenant = Tenant(
          id: uuid.v4(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          altPhone: _altPhoneController.text.trim().isNotEmpty ? _altPhoneController.text.trim() : null,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          propertyId: _selectedPropertyId!,
          unitId: _selectedUnitId!,
          idProofType: _selectedIdType,
          idProofNumber: _idNumberController.text.trim().isNotEmpty ? _idNumberController.text.trim() : null,
          moveInDate: _moveInDate,
          agreementEndDate: _agreementEndDate,
          monthlyRent: monthlyRent,
          securityDeposit: deposit,
          rentDueDay: dueDay,
          isActive: true,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
        await ref.read(tenantsProvider.notifier).addTenant(newTenant);

        final currentMonth = ref.read(selectedMonthProvider);
        ref.read(rentLedgerProvider.notifier).ensureMonthEntries(currentMonth);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(widget.tenantToEdit != null ? 'Tenant updated!' : 'Tenant added successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error saving tenant: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final isEditing = widget.tenantToEdit != null;

    final selectedProp = properties.where((p) => p.id == _selectedPropertyId).firstOrNull;

    final availableUnits = selectedProp?.units.where((u) {
      if (u.status == UnitStatus.vacant) return true;
      if (widget.tenantToEdit != null && widget.tenantToEdit!.unitId == u.id) return true;
      if (widget.initialUnitId != null && widget.initialUnitId == u.id) return true;
      if (_selectedUnitId != null && _selectedUnitId == u.id) return true;
      return false;
    }).toList() ?? [];

    final validPropertyId = properties.any((p) => p.id == _selectedPropertyId) ? _selectedPropertyId : null;
    final validUnitId = availableUnits.any((u) => u.id == _selectedUnitId) ? _selectedUnitId : null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Tenant' : 'Add Tenant (किरायेदार जोड़ें)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tenant Name
              const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Ramesh Kumar',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter tenant name' : null,
              ),

              const SizedBox(height: 18),

              // Phone & Alt Phone
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mobile Number *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: '9876543210',
                            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                          ),
                          validator: (val) => (val == null || val.trim().length < 10) ? 'Enter 10 digits' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alternate Phone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _altPhoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: 'Optional',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Building & Room Dropdowns
              const Text('Building (बिल्डिंग) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: validPropertyId,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                hint: const Text('Select Building', style: TextStyle(color: AppColors.textSecondary)),
                decoration: const InputDecoration(),
                items: properties.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPropertyId = val;
                    _selectedUnitId = null;
                  });
                },
                validator: (val) => val == null ? 'Please select a building' : null,
              ),

              const SizedBox(height: 18),

              const Text('Room (कमरा) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: validUnitId,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                hint: Text(
                  _selectedPropertyId == null ? 'First select building' : 'Select Room in this Building',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                decoration: const InputDecoration(),
                items: availableUnits.map((u) {
                  return DropdownMenuItem(
                    value: u.id,
                    child: Text('${u.roomDisplayName} • ${u.floor ?? "1st Floor"} (₹${u.monthlyRent}/mo)'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedUnitId = val;
                    final unit = availableUnits.where((u) => u.id == val).firstOrNull;
                    if (unit != null) {
                      _rentController.text = unit.monthlyRent.toString();
                      _depositController.text = unit.securityDeposit.toString();
                    }
                  });
                },
                validator: (val) => val == null ? 'Please select a room' : null,
              ),

              const SizedBox(height: 18),

              // Rent, Deposit, Due Day
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Room Monthly Rent (₹) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _rentController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(prefixText: '₹ '),
                          validator: (val) => CurrencyFormatter.parse(val ?? '') <= 0 ? 'Enter rent' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Security Deposit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
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
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Day', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _dueDayController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: '1-31'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Move-in Date & Agreement End Date Pickers
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Move-in Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _moveInDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _moveInDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF182230),
                              border: Border.all(color: const Color(0xFF263345)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(DateFormatter.formatDate(_moveInDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        const Text('Agreement Expiry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _agreementEndDate ?? _moveInDate.add(const Duration(days: 365)),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            );
                            if (picked != null) setState(() => _agreementEndDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF182230),
                              border: Border.all(color: const Color(0xFF263345)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _agreementEndDate != null
                                  ? DateFormatter.formatDate(_agreementEndDate!)
                                  : 'Not set',
                              style: TextStyle(
                                color: _agreementEndDate != null ? Colors.white : AppColors.textSecondary,
                                fontWeight: _agreementEndDate != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ID Proof Details
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ID Proof Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedIdType,
                          dropdownColor: AppColors.cardDark,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(),
                          items: _idProofTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedIdType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ID Proof Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _idNumberController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'e.g. 4532 8901 1234'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Notes
              const Text('Notes / Remarks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Family members, occupation, vehicles etc.'),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Add Tenant (किरायेदार जोड़ें)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
