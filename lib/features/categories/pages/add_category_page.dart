// add_category_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../blocs/category/category_bloc.dart';
import '../../../../core/utils/validators.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetMarginController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(child: Text('Please log in to add categories'));
          }

          final userId = authState.user.id;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Name Field
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

                  // Target Margin
                  TextFormField(
                    controller: _targetMarginController,
                    decoration: const InputDecoration(
                      labelText: 'Target Profit Margin % (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final num = double.tryParse(value);
                      if (num == null) return 'Enter a valid number';
                      if (num < 0 || num > 100) return 'Must be 0–100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save Button + Success Listener
                  BlocConsumer<CategoryBloc, CategoryState>(
                    listener: (context, state) {
                      // SUCCESS → Show message + Go back
                      if (state is CategoryOperationSuccess) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Category added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        Navigator.of(context).pop();
                      }

                      // FAILURE → Show error
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
                        onPressed: isLoading
                            ? null
                            : () => _saveCategory(userId),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Category'),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveCategory(String userId) {
    if (_formKey.currentState!.validate()) {
      final categoryData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'profitMarginTarget': _targetMarginController.text.trim().isEmpty
            ? null
            : double.tryParse(_targetMarginController.text.trim()),
      };

      context.read<CategoryBloc>().add(AddCategory(category: categoryData));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetMarginController.dispose();
    super.dispose();
  }
}
