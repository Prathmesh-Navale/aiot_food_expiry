// lib/screens/inventory_screens.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/product.dart';

// --- STOCK ENTRY OPTIONS ---
class StockEntryOptionsScreen extends StatelessWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;
  final VoidCallback onProductAdded;

  const StockEntryOptionsScreen({super.key, required this.apiService, required this.refreshHome, required this.onProductAdded});

  void _startScan(BuildContext context) {
    // Replaced external import with direct navigation to internal mock
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerMock(
          onScanCompleted: (scannedData) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => InventoryEntryScreen(
                    apiService: apiService,
                    onProductAdded: onProductAdded,
                    initialData: scannedData,
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
            OptionButton(
              icon: Icons.qr_code_scanner,
              label: 'QR Code/Barcode Scan (IoT)',
              description: 'Instantly integrate stock data via camera scanner.',
              color: Theme.of(context).colorScheme.secondary,
              onPressed: () => _startScan(context),
            ),
            const SizedBox(height: 20),
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

class OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;
  const OptionButton({required this.icon, required this.label, required this.description, required this.color, required this.onPressed, super.key});
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

// --- MANUAL ENTRY SCREEN ---
class InventoryEntryScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onProductAdded;
  final Map<String, dynamic>? initialData;
  const InventoryEntryScreen({super.key, required this.apiService, required this.onProductAdded, this.initialData});
  @override
  State<InventoryEntryScreen> createState() => _InventoryEntryScreenState();
}

class _InventoryEntryScreenState extends State<InventoryEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _productSkuController;
  late TextEditingController _initialPriceController;
  late TextEditingController _quantityController;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 90));
  String _storageLocation = 'Shelf A';
  bool _isLoading = false;
  final List<String> locations = ['Shelf A', 'Fridge B', 'Freezer C', 'Warehouse D'];

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
      if (data['storageLocation'] != null) _storageLocation = data['storageLocation'];
      if (data['expiryDays'] != null) _expiryDate = DateTime.now().add(Duration(days: data['expiryDays'] as int));
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
      setState(() { _isLoading = true; });
      final newProduct = Product(
        productName: _productNameController.text.trim(),
        initialPrice: double.tryParse(_initialPriceController.text) ?? 0.0,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        expiryDate: _expiryDate,
        storageLocation: _storageLocation,
        productSku: _productSkuController.text.trim(),
        skuEncoded: 201, avgTemp: 22.0, isHoliday: 0,
      );
      try {
        await widget.apiService.addProduct(newProduct);
        widget.onProductAdded();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SUCCESS: Product ${newProduct.productName} stored in database.')));
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          String errorDetail = e.toString().contains(':') ? e.toString().split(':')[1].trim() : 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database Error: Failed to add product ($errorDetail)')));
        }
      } finally {
        if (mounted) setState(() { _isLoading = false; });
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
                      if (newValue != null) setState(() { _storageLocation = newValue; });
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

// --- ALERTS SCREEN ---
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No inventory items found.'));

        final alertProducts = snapshot.data!
            .where((p) => p.daysToExpiry > 0 && p.daysToExpiry <= firstAlertDays && p.status != 'Donated')
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() { _productsFuture = _fetchProductsAndCheckAlerts(); });
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'First Alert: Dynamic Discounting',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const Divider(),
              if (alertProducts.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('No active alerts.', style: TextStyle(color: Colors.grey)))),
              ...alertProducts.map((product) {
                final isDonationAlert = product.daysToExpiry <= secondAlertDays;
                return DiscountAlertCard(key: ValueKey(product.id), product: product, isDonationAlert: isDonationAlert, apiService: widget.apiService);
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
    setState(() { _isLoadingRecipe = true; });
    try {
      final recipe = await widget.apiService.getRecipeSuggestion(widget.product.productName);
      if(mounted) setState(() { _recipeSuggestion = recipe; });
    } catch (e) {
      if(mounted) setState(() { _recipeSuggestion = 'Error fetching recipe'; });
    } finally {
      if(mounted) setState(() { _isLoadingRecipe = false; });
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
                Expanded(child: Text(widget.product.productName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                Chip(
                  label: Text('${widget.product.daysToExpiry} days left', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  backgroundColor: widget.isDonationAlert ? Colors.red : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Qty: ${widget.product.quantity} | Loc: ${widget.product.storageLocation}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                Text('\$${widget.product.initialPrice.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough)),
                Text('\$${widget.product.finalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightGreen, fontSize: 16)),
                Text('(${widget.product.discountPercentage.toStringAsFixed(0)}% OFF)', style: const TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Customer Preview (QR)', style: TextStyle(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_recipeSuggestion, style: const TextStyle(fontStyle: FontStyle.italic)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- DONATION SCREEN ---
class DonationScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;
  const DonationScreen({super.key, required this.apiService, required this.refreshHome});
  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  late Future<List<Product>> _productsFuture;
  final int donationThresholdDays = 4;
  @override
  void initState() {
    super.initState();
    _productsFuture = widget.apiService.fetchProducts();
  }

  Future<void> _markAsDonated(String id, String productName) async {
    try {
      await widget.apiService.deleteProduct(id);
      widget.refreshHome();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Donation logged: $productName')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to log donation')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final donationCandidates = snapshot.data!
            .where((p) => p.daysToExpiry > 0 && p.daysToExpiry <= donationThresholdDays && p.status != 'Donated')
            .toList();

        if (donationCandidates.isEmpty) return const Center(child: Text("No Donations Needed"));

        return RefreshIndicator(
          onRefresh: () async { setState(() { _productsFuture = widget.apiService.fetchProducts(); }); },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donationCandidates.length,
            itemBuilder: (ctx, i) {
              final product = donationCandidates[i];
              return Card(
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: Icon(Icons.warning, color: Colors.red.shade400),
                  title: Text(product.productName, style: TextStyle(color: Colors.red.shade200)),
                  subtitle: Text('Expires in ${product.daysToExpiry} days'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: product.id == null ? null : () => _markAsDonated(product.id!, product.productName),
                    child: const Text("Log Donation", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- BARCODE SCANNER MOCK ---
class BarcodeScannerMock extends StatelessWidget {
  final Function(Map<String, dynamic>) onScanCompleted;
  const BarcodeScannerMock({super.key, required this.onScanCompleted});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Simulating Camera Scan...", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => onScanCompleted({
                'productName': 'Scanned Item',
                'productSku': 'SCAN-1234',
                'initialPrice': 3.50,
                'quantity': 5,
                'expiryDays': 60
              }),
              child: const Text("Capture"),
            )
          ],
        ),
      ),
    );
  }
}