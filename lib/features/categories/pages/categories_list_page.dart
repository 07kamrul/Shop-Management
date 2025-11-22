import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../blocs/category/category_bloc.dart';
import '../../../../data/models/category_model.dart';
import '../widgets/category_card.dart';
import 'add_category_page.dart';

class CategoriesListPage extends StatefulWidget {
  const CategoriesListPage({super.key});
  @override
  State<CategoriesListPage> createState() => _CategoriesListPageState();
}

class _CategoriesListPageState extends State<CategoriesListPage>
    with AutomaticKeepAliveClientMixin, RouteAware {
  late final CategoryBloc _categoryBloc;

  @override
  void initState() {
    super.initState();
    _categoryBloc = CategoryBloc()..add(const LoadCategories());
  }

  @override
  void dispose() {
    _categoryBloc.close();
    super.dispose();
  }

  // Reload categories whenever this page becomes visible
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force reload when page becomes visible
    _reloadCategories();
  }

  void _reloadCategories() {
    _categoryBloc.add(const LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('Categories')),
            body: const Center(child: Text('Please log in to view categories')),
          );
        }

        final user = authState.user;

        return BlocProvider.value(
          value: _categoryBloc,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Categories'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _reloadCategories,
                  tooltip: 'Refresh',
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: _categoryBloc,
                          child: const AddCategoryPage(),
                        ),
                      ),
                    );
                    // Reload after returning from add page
                    _reloadCategories();
                  },
                ),
              ],
            ),
            body: BlocConsumer<CategoryBloc, CategoryState>(
              listener: (context, state) {
                // Handle operation failures
                if (state is CategoryOperationFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${state.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is CategoriesLoadInProgress ||
                    state is CategoryOperationInProgress) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CategoriesLoadFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load categories',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _reloadCategories,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CategoriesLoadSuccess) {
                  final categories = state.categories;

                  // Convert dynamic list to Category list
                  final categoryList = categories.map((data) {
                    if (data is Category) {
                      return data;
                    } else if (data is Map<String, dynamic>) {
                      return Category.fromJson(data);
                    } else {
                      // Handle unexpected data type
                      return Category.create(
                        name: 'Unknown Category',
                        createdBy: user.id,
                      );
                    }
                  }).toList();

                  return categoryList.isEmpty
                      ? _buildEmptyState()
                      : _buildCategoriesList(categoryList);
                }

                return const Center(
                  child: Text('Load categories to get started'),
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: _categoryBloc,
                      child: const AddCategoryPage(),
                    ),
                  ),
                );
                // Reload after returning from add page
                _reloadCategories();
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Categories Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first category to organize products',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(List<Category> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(category: category);
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
