import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shop_management/core/utils/barcode_scanner.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../blocs/category/category_bloc.dart';
import '../../../../blocs/product/product_bloc.dart';
import '../../../../core/utils/validators.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController(text: '10');

  String? _selectedCategoryId;
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  void _loadCategories() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CategoryBloc>().add(const LoadCategories());
    }
  }

  void _scanBarcode() async {
    try {
      final barcode = await BarcodeScannerUtil.scanBarcode();
      if (barcode != null) {
        setState(() {
          _barcodeController.text = barcode;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned barcode: $barcode'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode scan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _scanBarcode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.qr_code_scanner),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buyingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Buying Price *',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                        prefixIcon: Icon(Icons.shopping_cart),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.validatePrice,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price *',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                        prefixIcon: Icon(Icons.sell),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.validatePrice,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Initial Stock *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.validateStock,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'Min Stock Level',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildProfitPreview(),
              const SizedBox(height: 32),
              BlocConsumer<ProductBloc, ProductState>(
                listener: (context, state) {
                  if (state is ProductOperationFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${state.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is ProductsLoadSuccess) {
                    // Product was added successfully and products reloaded
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is ProductOperationInProgress
                        ? null
                        : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: state is ProductOperationInProgress
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Save Product'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoadInProgress) {
          return const LinearProgressIndicator();
        }

        if (state is CategoriesLoadFailure) {
          return Column(
            children: [
              Text(
                'Error loading categories: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadCategories,
                child: const Text('Retry'),
              ),
            ],
          );
        }

        if (state is CategoriesLoadSuccess) {
          _categories = state.categories;

          if (_categories.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No categories available',
                  style: TextStyle(color: Colors.orange),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to add category page
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => AddCategoryPage()));
                  },
                  child: const Text('Add Category First'),
                ),
              ],
            );
          }

          return DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Category *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: _categories.map((category) {
              final categoryId = category is Map<String, dynamic>
                  ? category['id'] ?? category['_id']
                  : category.id;
              final categoryName = category is Map<String, dynamic>
                  ? category['name']
                  : category.name;

              return DropdownMenuItem<String>(
                value: categoryId?.toString(),
                child: Text(categoryName?.toString() ?? 'Unknown Category'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
          );
        }

        return const Text('Load categories to continue');
      },
    );
  }

  Widget _buildProfitPreview() {
    final buyingPrice = double.tryParse(_buyingPriceController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
    final profit = sellingPrice - buyingPrice;
    final margin = sellingPrice > 0 ? (profit / sellingPrice) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profit Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profit per unit:'),
                Text(
                  '₹${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: profit >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profit margin:'),
                Text(
                  '${margin.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: margin >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final productData = {
        'name': _nameController.text.trim(),
        'barcode': _barcodeController.text.isEmpty
            ? null
            : _barcodeController.text.trim(),
        'categoryId': _selectedCategoryId!,
        'buyingPrice': double.parse(_buyingPriceController.text),
        'sellingPrice': double.parse(_sellingPriceController.text),
        'currentStock': int.parse(_stockController.text),
        'minStockLevel': int.parse(_minStockController.text),
      };

      context.read<ProductBloc>().add(AddProduct(product: productData));
    } else if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }
}
