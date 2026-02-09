// lib/screens/inventory_screens.dart

import 'package:flutter/material.dart';
import 'package:aiot_ui/services/api_service.dart';
import 'package:aiot_ui/models/product.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// --- UTILITY WIDGETS ---

// Reusable button widget for options screen
class OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const OptionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 8,
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

// --- 6. STOCK ENTRY OPTIONS SCREEN (QR/Manual) ---
class StockEntryOptionsScreen extends StatelessWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;
  final VoidCallback onProductAdded;

  const StockEntryOptionsScreen({super.key, required this.apiService, required this.refreshHome, required this.onProductAdded});

  // --- Function to handle navigation after scanning ---
  void _startScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onScanCompleted: (scannedData) {
            // Navigate to the Inventory Entry Screen, pre-filling data
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => InventoryEntryScreen(
                    apiService: apiService,
                    onProductAdded: onProductAdded,
                    initialData: scannedData, // Pass the scanned data
                  )
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Entry Options')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Initial Data Capture and Inventory Setup (AIoT)',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            // QR Code Scan Button (REAL SCANNER LOGIC)
            OptionButton(
              icon: Icons.qr_code_scanner,
              label: 'QR Code/Barcode Scan (IoT)',
              description: 'Instantly integrate stock data via camera scanner.',
              color: Theme.of(context).colorScheme.secondary,
              onPressed: () => _startScan(context), // Uses the real scanner screen
            ),
            const SizedBox(height: 20),

            // Manual Entry Button
            OptionButton(
              icon: Icons.edit_note,
              label: 'Manual Data Entry',
              description: 'Manually input all necessary product and expiry details.',
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InventoryEntryScreen(apiService: apiService, onProductAdded: onProductAdded)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- 7. MANUAL INVENTORY ENTRY SCREEN (UPDATED TO RECEIVE DATA) ---
class InventoryEntryScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onProductAdded;
  final Map<String, dynamic>? initialData; // NEW: Optional data passed from scanner

  const InventoryEntryScreen({super.key, required this.apiService, required this.onProductAdded, this.initialData});

  @override
  State<InventoryEntryScreen> createState() => _InventoryEntryScreenState();
}

class _InventoryEntryScreenState extends State<InventoryEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Text Controllers for pre-filling ---
  late TextEditingController _productNameController;
  late TextEditingController _productSkuController;
  late TextEditingController _initialPriceController;
  late TextEditingController _quantityController;

  // --- Form State Variables ---
  // Default expiry set to a reasonable future date for any new item
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 90));
  String _storageLocation = 'Shelf A';
  bool _isLoading = false;

  final List<String> locations = ['Shelf A', 'Fridge B', 'Freezer C', 'Warehouse D'];

  // --- HARDCODED/SIMULATED AI INPUTS (for consistency) ---
  static const int simulatedSkuEncoded = 201;
  static const double simulatedAvgTemp = 22.0;
  static const int simulatedIsHoliday = 0;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    if (data == null) {
      _productNameController = TextEditingController(text: '');
      _productSkuController = TextEditingController(text: '');
      _initialPriceController = TextEditingController(text: '');
      _quantityController = TextEditingController(text: '1');
      _expiryDate = DateTime.now().add(const Duration(days: 90));
      _storageLocation = 'Shelf A';
    } else {
      _productNameController = TextEditingController(text: data['productName'] ?? '');
      _productSkuController = TextEditingController(text: data['productSku'] ?? '');
      _initialPriceController = TextEditingController(text: data['initialPrice']?.toStringAsFixed(2) ?? '');
      _quantityController = TextEditingController(text: data['quantity']?.toString() ?? '1');

      if (data['storageLocation'] != null) {
        _storageLocation = data['storageLocation'];
      }

      if (data['expiryDays'] != null) {
        _expiryDate = DateTime.now().add(Duration(days: data['expiryDays'] as int));
      } else {
        _expiryDate = DateTime.now().add(const Duration(days: 90));
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productSkuController.dispose();
    _initialPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _productNameController.clear();
    _productSkuController.clear();
    _initialPriceController.clear();
    _quantityController.text = '1';
    setState(() {
      _storageLocation = 'Shelf A';
      _expiryDate = DateTime.now().add(const Duration(days: 90));
      _formKey.currentState?.reset();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final newProduct = Product(
        productName: _productNameController.text.trim(),
        initialPrice: double.tryParse(_initialPriceController.text) ?? 0.0,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        expiryDate: _expiryDate,
        storageLocation: _storageLocation,
        productSku: _productSkuController.text.trim(),
        skuEncoded: simulatedSkuEncoded,
        avgTemp: simulatedAvgTemp,
        isHoliday: simulatedIsHoliday,
      );

      try {
        await widget.apiService.addProduct(newProduct);
        widget.onProductAdded();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SUCCESS: Product ${newProduct.productName} stored in database.')),
          );
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          String errorDetail = e.toString().contains(':') ? e.toString().split(':')[1].trim() : 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Database Error: Failed to add product ($errorDetail)')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Stock Entry')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Database Integration: Food Item Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const Divider(height: 20),
                  TextFormField(
                    controller: _productNameController,
                    decoration: const InputDecoration(labelText: 'Food Item Name', prefixIcon: Icon(Icons.fastfood)),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter the item name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _productSkuController,
                    decoration: const InputDecoration(labelText: 'SKU / Barcode (e.g., COLA-330-001)', prefixIcon: Icon(Icons.qr_code)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _initialPriceController,
                    decoration: const InputDecoration(labelText: 'Initial Price (\$) / Unit', prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (value) {
                      final price = double.tryParse(value ?? '');
                      return price == null || price <= 0 ? 'Enter a valid price' : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity (Units)', prefixIcon: Icon(Icons.format_list_numbered)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final qty = int.tryParse(value ?? '');
                      return qty == null || qty <= 0 ? 'Enter a valid quantity' : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Storage Location', prefixIcon: Icon(Icons.location_on)),
                    value: _storageLocation,
                    items: locations.map((String location) {
                      return DropdownMenuItem<String>(value: location, child: Text(location));
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) setState(() => _storageLocation = newValue);
                    },
                    dropdownColor: Theme.of(context).cardColor,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text('Expiry Date: ${DateFormat('yyyy-MM-dd').format(_expiryDate)}', style: Theme.of(context).textTheme.bodyMedium),
                    trailing: TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text('Select Date', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'AI Context: Temp=${simulatedAvgTemp}°C, Holiday=${simulatedIsHoliday == 1 ? 'Yes' : 'No'}, Encoded SKU=${simulatedSkuEncoded}',
                      style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  ),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Stock to Database', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 8. ALERTS & DISCOUNTS SCREEN (First Alert) ---
class AlertsDiscountsScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;

  const AlertsDiscountsScreen({super.key, required this.apiService, required this.refreshHome});

  @override
  State<AlertsDiscountsScreen> createState() => _AlertsDiscountsScreenState();
}

class _AlertsDiscountsScreenState extends State<AlertsDiscountsScreen> {
  late Future<List<Product>> _productsFuture;
  final int firstAlertDays = 10;
  final int secondAlertDays = 4;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsAndCheckAlerts();
  }

  Future<List<Product>> _fetchProductsAndCheckAlerts() async {
    List<Product> products = await widget.apiService.fetchProducts();
    List<Product> processedProducts = [];
    for (var product in products) {
      if (product.daysToExpiry > 0 && product.daysToExpiry <= firstAlertDays && product.status == 'For Sale') {
        try {
          final result = await widget.apiService.calculateDiscount(product);
          processedProducts.add(product.copyProductWith(
            discountPercentage: result['discount_percentage'] ?? 0.0,
            finalPrice: result['final_price'] ?? product.initialPrice,
            status: 'Discount Active',
          ));
        } catch (e) {
          processedProducts.add(product);
          print('Error calculating discount for ${product.productName}: $e');
        }
      } else {
        processedProducts.add(product);
      }
    }
    return processedProducts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Connection Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No inventory items found. Add stock via Stock Entry.'));

        final alertProducts = snapshot.data!
            .where((p) => p.daysToExpiry > 0 && p.daysToExpiry <= firstAlertDays && p.status != 'Donated')
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _productsFuture = _fetchProductsAndCheckAlerts();
            });
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'First Alert: Dynamic Discounting for Revenue Recovery',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Items approaching expiry (10 days or less). AI determines the optimal discount to drive sales.'),
              ),
              const Divider(),
              if (alertProducts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('No items currently triggering the 10-day discount alert.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                ),
              ...alertProducts.map((product) {
                final isDonationAlert = product.daysToExpiry <= secondAlertDays;
                return DiscountAlertCard(
                  key: ValueKey(product.id),
                  product: product,
                  isDonationAlert: isDonationAlert,
                  apiService: widget.apiService,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class DiscountAlertCard extends StatefulWidget {
  final Product product;
  final bool isDonationAlert;
  final ApiService apiService;

  const DiscountAlertCard({super.key, required this.product, required this.isDonationAlert, required this.apiService});

  @override
  State<DiscountAlertCard> createState() => _DiscountAlertCardState();
}

class _DiscountAlertCardState extends State<DiscountAlertCard> {
  String _recipeSuggestion = 'Fetching AI Recipe...';
  bool _isLoadingRecipe = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipe();
  }

  Future<void> _fetchRecipe() async {
    setState(() { _isLoadingRecipe = true; _recipeSuggestion = 'Fetching AI Recipe...'; });
    try {
      final recipe = await widget.apiService.getRecipeSuggestion(widget.product.productName);
      setState(() => _recipeSuggestion = recipe);
    } catch (e) {
      setState(() => _recipeSuggestion = 'Error fetching recipe');
    } finally {
      setState(() => _isLoadingRecipe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: widget.isDonationAlert ? Colors.red.shade700 : Theme.of(context).colorScheme.primary, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(widget.product.productName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                Chip(label: Text('${widget.product.daysToExpiry} days left', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: widget.isDonationAlert ? Colors.red : Colors.orange),
              ],
            ),
            const Divider(height: 10),
            Text('Location: ${widget.product.storageLocation} | Qty: ${widget.product.quantity}'),
            const SizedBox(height: 8),
            Text('AI Dynamic Pricing', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Text('Original: \$${widget.product.initialPrice.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough)),
                Text('AI Price: \$${widget.product.finalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightGreen, fontSize: 16)),
                Text('(${widget.product.discountPercentage.toStringAsFixed(0)}% OFF)', style: const TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Real-Time Customer Interface Preview (LCD/QR)', style: TextStyle(fontWeight: FontWeight.w600)),
              collapsedBackgroundColor: Theme.of(context).cardColor,
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LCD Display: ${widget.product.productName} - ${widget.product.discountPercentage.toStringAsFixed(0)}% OFF!', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                      const SizedBox(height: 8),
                      const Text('QR Code Recipe: "This food is expiring soon—make this recipe for tonight\'s dinner!"', style: TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      _isLoadingRecipe ? const LinearProgressIndicator() : Text(_recipeSuggestion, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.isDonationAlert) Padding(padding: const EdgeInsets.only(top: 12.0), child: Text('Action Required: Item is within 4 days of expiry and should be moved to the Donation Dashboard.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[400]))),
          ],
        ),
      ),
    );
  }
}

// --- MISSING CLASS: BarcodeScannerScreen (Added here to fix error) ---
class BarcodeScannerScreen extends StatelessWidget {
  final Function(Map<String, dynamic>) onScanCompleted;
  const BarcodeScannerScreen({super.key, required this.onScanCompleted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Simulate Scanner')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Simulating Scan...", style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => onScanCompleted({
                'productName': 'Scanned Soda',
                'productSku': 'SODA-123',
                'initialPrice': 2.50,
                'quantity': 10,
                'expiryDays': 60,
                'storageLocation': 'Fridge B'
              }),
              child: const Text("Capture 'Soda'"),
            )
          ],
        ),
      ),
    );
  }
}