import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shop_management/features/categories/pages/edit_category_page.dart';
import '../../../../blocs/category/category_bloc.dart';
import '../../../../data/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.category, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      category.description!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                  if (category.profitMarginTarget != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Target Margin: ${category.profitMarginTarget!.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            // Inside CategoryCard → edit button onPressed
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                // In your CategoryCard widget's edit button:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<CategoryBloc>(),
                      child: EditCategoryPage(category: category),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () {
                _showDeleteDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete ${category.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CategoryBloc>().add(
                DeleteCategory(categoryId: category.id!),
              );
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
