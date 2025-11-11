import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../blocs/product/product_bloc.dart';
import '../../../../blocs/sale/sale_bloc.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/models/user_model.dart';
import '../widgets/quick_actions.dart';
import '../widgets/stats_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: const Center(child: Text('Please log in to view dashboard')),
          );
        }

        final user = authState.user;

        return MultiBlocProvider(
          providers: [
            BlocProvider<ProductBloc>(
              create: (context) => ProductBloc()..add(LoadProducts()),
            ),
            BlocProvider<SaleBloc>(
              create: (context) => SaleBloc()..add(const LoadTodaySales()),
            ),
          ],
          child: Scaffold(
            appBar: AppBar(
              title: Text('${user.shopName} Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: BlocBuilder<SaleBloc, SaleState>(
                builder: (context, saleState) {
                  return BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, productState) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome Section
                                _buildWelcomeSection(user),
                                const SizedBox(height: 20),

                                // Stats Grid - Fixed height
                                SizedBox(
                                  height: 200,
                                  child: _buildStatsGrid(
                                    context,
                                    saleState,
                                    productState,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Quick Actions
                                const QuickActions(),
                                const SizedBox(height: 20),

                                // Recent Activity Section
                                _buildRecentActivitySection(
                                  context,
                                  saleState,
                                  constraints,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${user.name}!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s your shop overview',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
      BuildContext context,
      SaleState saleState,
      ProductState productState,
      ) {
    int totalProducts = 0;
    int lowStockCount = 0;
    double todaySales = 0.0;
    int todayTransactions = 0;

    // Calculate product statistics
    if (productState is ProductsLoadSuccess) {
      final products = productState.products;
      totalProducts = products.length;
      lowStockCount = products.where((product) {
        final currentStock = product['currentStock'] ?? 0;
        final minStockLevel = product['minStockLevel'] ?? 10;
        return currentStock <= minStockLevel;
      }).length;
    }

    // Calculate sales statistics
    if (saleState is SalesLoadSuccess) {
      final sales = saleState.sales;
      todayTransactions = sales.length;
      todaySales = sales.fold(0.0, (total, saleData) {
        return total + saleData.totalAmount;
      });
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        StatsCard(
          title: 'Today\'s Sales',
          value: '₹${todaySales.toStringAsFixed(2)}',
          icon: Icons.shopping_cart,
          color: Colors.blue,
          subtitle: '$todayTransactions transactions',
        ),
        StatsCard(
          title: 'Today\'s Profit',
          value: '₹${_calculateEstimatedProfit(todaySales).toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.green,
          subtitle: 'Estimated',
        ),
        StatsCard(
          title: 'Total Products',
          value: totalProducts.toString(),
          icon: Icons.inventory_2,
          color: Colors.orange,
          subtitle: '$lowStockCount low stock',
        ),
        StatsCard(
          title: 'Low Stock',
          value: lowStockCount.toString(),
          icon: Icons.warning,
          color: lowStockCount > 0 ? Colors.red : Colors.grey,
          subtitle: 'Need attention',
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
      BuildContext context,
      SaleState saleState,
      BoxConstraints constraints,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 400, // Fixed height for sales list
          child: _buildSalesList(context, saleState),
        ),
      ],
    );
  }

  Widget _buildSalesList(BuildContext context, SaleState saleState) {
    if (saleState is SalesLoadInProgress) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading sales...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (saleState is SalesLoadFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                'Failed to load sales',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                saleState.error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<SaleBloc>().add(const LoadTodaySales());
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (saleState is SalesLoadSuccess) {
      final sales = saleState.sales;

      if (sales.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No sales today',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Sales will appear here once you make transactions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Take only the last 5 sales for recent activity
      final recentSales = sales.take(5).toList();

      return ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: recentSales.length,
        itemBuilder: (context, index) {
          final sale = recentSales[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt,
                  color: Colors.blue[700],
                  size: 20,
                ),
              ),
              title: Text(
                sale.customerName ?? 'Walk-in Customer',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${sale.itemCount} item${sale.itemCount == 1 ? '' : 's'} • ${_formatPaymentMethod(sale.paymentMethod)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(sale.dateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${sale.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Profit: ₹${sale.totalProfit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateEstimatedProfit(double totalSales) {
    // Simple estimation: Assume 25% profit margin
    return totalSales * 0.25;
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'online':
        return 'Online';
      default:
        return method;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final saleDay = DateTime(date.year, date.month, date.day);

    if (saleDay == today) {
      return 'Today ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}