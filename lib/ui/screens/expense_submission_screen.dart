import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource;
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/sqlite_service.dart';
import '../../services/sync_service.dart';
import '../theme/app_theme.dart';

class ExpenseSubmissionScreen extends StatefulWidget {
  final String? preSelectedProjectId;

  const ExpenseSubmissionScreen({super.key, this.preSelectedProjectId});

  @override
  State<ExpenseSubmissionScreen> createState() =>
      _ExpenseSubmissionScreenState();
}

class _ExpenseSubmissionScreenState extends State<ExpenseSubmissionScreen> {
  final _locationController = TextEditingController();
  final _claimantController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedCurrency = 'USD';
  String _selectedPaymentMethod = 'Cash';
  String _selectedPaymentStatus = 'Pending';

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  Project? _selectedProject;
  ExpenseCategory _selectedCategory = ExpenseCategory.miscellaneous;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  bool _isProjectLocked = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentAccount;
    _claimantController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _claimantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<AppProvider>().projects;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Submit Expense',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProjectDropdown(projects),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildAmountField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCurrencyDropdown()),
                ],
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildPaymentMethodDropdown(),
              const SizedBox(height: 16),
              _buildPaymentStatusSelector(),
              const SizedBox(height: 16),
              _buildClaimantField(),
              const SizedBox(height: 16),
              _buildLocationField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectDropdown(List<Project> projects) {
    if (_isProjectLocked && _selectedProject != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text(
              'Project: ',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            Text(
              _selectedProject!.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Project>(
      value: _selectedProject,
      decoration: InputDecoration(
        labelText: 'Select Project',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: projects.map((project) {
        return DropdownMenuItem(value: project, child: Text(project.name));
      }).toList(),
      onChanged: _isProjectLocked
          ? null
          : (project) {
              setState(() {
                _selectedProject = project;
              });
            },
      validator: (project) {
        if (project == null) {
          return 'Please select a project';
        }
        return null;
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Expense Title',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixText: '\$ ',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description',
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  }
                },
                selectedColor: AppTheme.primaryCyan.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryCyan
                      : AppTheme.textSecondary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Date',
              style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
            ),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusSelector() {
    final statuses = ['Pending', 'Paid', 'Reimbursed'];
    return DropdownButtonFormField<String>(
      value: _selectedPaymentStatus,
      decoration: InputDecoration(
        labelText: 'Payment Status',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: statuses
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) => setState(() => _selectedPaymentStatus = v!),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitExpense,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryCyan,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Submit Expense',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      decoration: InputDecoration(
        labelText: 'Currency',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        'USD',
        'EUR',
        'VND',
        'GBP',
      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _selectedCurrency = v!),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    final methods = ['Cash', 'Credit Card', 'Bank Transfer', 'Cheque'];
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: InputDecoration(
        labelText: 'Payment Method',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: methods
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
    );
  }

  Widget _buildClaimantField() {
    return TextFormField(
      controller: _claimantController,
      decoration: InputDecoration(
        labelText: 'Claimant (Name/Email)',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Claimant is required' : null,
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Location (Optional)',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Receipt Image (Optional)',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Text('Change'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selectedImage = null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProject == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!);
        if (imageUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Saving without receipt.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final expense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: _selectedProject!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: _selectedPaymentStatus,
        claimant: _claimantController.text.trim(),
        location: _locationController.text.trim(),
        imageUrl: imageUrl,
        date: _selectedDate,
      );

      await SqliteService.instance.insertExpenseAndQueue(expense);

      await SyncService.instance.processSyncQueue();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
