// features/category/pages/edit_category_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../blocs/category/category_bloc.dart';
import '../../../../data/models/category_model.dart';
import '../../../../core/utils/validators.dart';

class EditCategoryPage extends StatefulWidget {
  final Category category;

  const EditCategoryPage({super.key, required this.category});

  @override
  State<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.category.name,
  );
  late final _descriptionController = TextEditingController(
    text: widget.category.description ?? '',
  );
  late final _targetMarginController = TextEditingController(
    text: widget.category.profitMarginTarget != null
        ? widget.category.profitMarginTarget!.toStringAsFixed(1)
        : '',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveChanges,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Category Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Target Profit Margin
              TextFormField(
                controller: _targetMarginController,
                decoration: const InputDecoration(
                  labelText: 'Target Profit Margin % (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final num = double.tryParse(value);
                  if (num == null) return 'Enter a valid number';
                  if (num < 0 || num > 100) return 'Must be 0–100%';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button with Loading & Success Handling
              BlocConsumer<CategoryBloc, CategoryState>(
                listener: (context, state) {
                  if (state is CategoryOperationSuccess) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Category updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    Navigator.of(context).pop();
                  }

                  if (state is CategoryOperationFailure) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('Error: ${state.error}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is CategoryOperationInProgress;

                  return ElevatedButton(
                    onPressed: isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Update Category'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'id': widget.category.id,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'profitMarginTarget': _targetMarginController.text.trim().isEmpty
            ? null
            : double.tryParse(_targetMarginController.text.trim()),
      };

      context.read<CategoryBloc>().add(UpdateCategory(category: updatedData));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
