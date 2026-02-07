import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/product.dart';

// ==========================================
// 1. STOCK ENTRY OPTIONS & SCANNER
// ==========================================

class StockEntryOptionsScreen extends StatelessWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;
  final VoidCallback onProductAdded;

  const StockEntryOptionsScreen({
    super.key, 
    required this.apiService, 
    required this.refreshHome, 
    required this.onProductAdded
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                'Inventory Ingestion',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Select a method to add stock to the AIoT Database'),
              const SizedBox(height: 40),

              // Scanner Option
              _buildOptionCard(
                context,
                icon: Icons.qr_code_scanner,
                title: 'Scan Barcode (IoT)',
                subtitle: 'Use camera to scan product SKU',
                color: Theme.of(context).colorScheme.secondary,
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarcodeScannerMock(
                        onScan: (data) {
                          // Navigate to Form with Pre-filled Data
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => InventoryEntryScreen(
                              apiService: apiService, 
                              onProductAdded: onProductAdded,
                              initialData: data,
                            )),
                          );
                        }
                      )
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              
              // Manual Option
              _buildOptionCard(
                context,
                icon: Icons.edit_note,
                title: 'Manual Entry',
                subtitle: 'Type product details manually',
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InventoryEntryScreen(
                      apiService: apiService, 
                      onProductAdded: onProductAdded
                    )),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. MANUAL INVENTORY FORM
// ==========================================

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
  late TextEditingController _nameCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 90));
  String _location = 'Shelf A';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _nameCtrl = TextEditingController(text: data['productName'] ?? '');
    _skuCtrl = TextEditingController(text: data['productSku'] ?? '');
    _priceCtrl = TextEditingController(text: data['initialPrice']?.toString() ?? '');
    _qtyCtrl = TextEditingController(text: data['quantity']?.toString() ?? '1');
    if (data['expiryDays'] != null) {
      _expiryDate = DateTime.now().add(Duration(days: data['expiryDays']));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _skuCtrl.dispose(); _priceCtrl.dispose(); _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final newProduct = Product(
        productName: _nameCtrl.text.trim(),
        initialPrice: double.tryParse(_priceCtrl.text) ?? 0.0,
        quantity: int.tryParse(_qtyCtrl.text) ?? 0,
        expiryDate: _expiryDate,
        storageLocation: _location,
        productSku: _skuCtrl.text.trim(),
        // Hardcoded AI Simulation Data
        skuEncoded: 201, avgTemp: 22.0, isHoliday: 0,
      );

      await widget.apiService.addProduct(newProduct);
      widget.onProductAdded();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Success: Product added to AIoT Cloud'), 
          backgroundColor: Colors.green
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Item Specification', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  _buildInput(_nameCtrl, 'Product Name', Icons.fastfood, false),
                  const SizedBox(height: 16),
                  _buildInput(_skuCtrl, 'SKU / Barcode', Icons.qr_code, false),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInput(_priceCtrl, 'Price (\u0024)', Icons.attach_money, true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInput(_qtyCtrl, 'Quantity', Icons.numbers, true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _location,
                    items: ['Shelf A', 'Fridge B', 'Freezer C', 'Warehouse D']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() => _location = v!),
                    decoration: _inputDeco('Storage Location', Icons.place),
                    dropdownColor: const Color(0xFF2C2C2C),
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Expiry: ${DateFormat('yyyy-MM-dd').format(_expiryDate)}', style: const TextStyle(color: Colors.white70)),
                    trailing: TextButton(
                      child: const Text('Change'),
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                        if(d != null) setState(() => _expiryDate = d);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('SAVE TO DATABASE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, bool isNum) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      validator: (v) => v!.isEmpty ? 'Required' : null,
      decoration: _inputDeco(label, icon),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor)),
    );
  }
}

// ==========================================
// 3. ALERTS & DISCOUNTS
// ==========================================

class AlertsDiscountsScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;
  const AlertsDiscountsScreen({super.key, required this.apiService, required this.refreshHome});

  @override
  State<AlertsDiscountsScreen> createState() => _AlertsDiscountsScreenState();
}

class _AlertsDiscountsScreenState extends State<AlertsDiscountsScreen> {
  // Keeping your exact logic 10 day alert
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: widget.apiService.fetchProducts(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Logic: Expiry <= 10 days
        final alerts = snapshot.data!.where((p) => p.daysToExpiry > 0 && p.daysToExpiry <= 10).toList();
        
        if (alerts.isEmpty) return const Center(child: Text("No Discounts Active", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (ctx, i) => _DiscountCard(product: alerts[i], apiService: widget.apiService),
        );
      },
    );
  }
}

class _DiscountCard extends StatelessWidget {
  final Product product;
  final ApiService apiService;
  const _DiscountCard({required this.product, required this.apiService});

  @override
  Widget build(BuildContext context) {
    // Calculating dynamic discount locally for display
    final discount = (10 - product.daysToExpiry) * 5.0; // Simulated logic
    final finalPrice = product.initialPrice * (1 - (discount/100));

    return Card(
      color: const Color(0xFF252525),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.orange.withOpacity(0.5))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(product.productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                  child: Text('${product.daysToExpiry} Days Left', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('\$${product.initialPrice}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                const SizedBox(width: 10),
                Text('\$${finalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20)),
                const Spacer(),
                Text('${discount.toStringAsFixed(0)}% OFF', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            FutureBuilder<String>(
              future: apiService.getRecipeSuggestion(product.productName),
              builder: (ctx, snap) => Text(
                snap.data ?? 'Loading AI Recipe...',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. DONATION SCREEN
// ==========================================

class DonationScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback refreshHome;
  const DonationScreen({super.key, required this.apiService, required this.refreshHome});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: widget.apiService.fetchProducts(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Logic: Expiry <= 4 days
        final donations = snapshot.data!.where((p) => p.daysToExpiry <= 4 && p.daysToExpiry > 0).toList();

        if (donations.isEmpty) return const Center(child: Text("No Donations Needed", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (ctx, i) {
            final p = donations[i];
            return Card(
              color: const Color(0xFF2A1515),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.withOpacity(0.5))),
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                title: Text(p.productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Expires in ${p.daysToExpiry} days', style: const TextStyle(color: Colors.redAccent)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Log Donation'),
                  onPressed: () async {
                    await widget.apiService.deleteProduct(p.id ?? '');
                    setState((){}); // Refresh local
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Donation Logged")));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 5. MOCK WIDGET: BARCODE SCANNER
// ==========================================

class BarcodeScannerMock extends StatelessWidget {
  final Function(Map<String, dynamic>) onScan;
  const BarcodeScannerMock({super.key, required this.onScan});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Simulating Scan...", style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => onScan({
                'productName': 'Scanned Soda',
                'productSku': 'SODA-123',
                'initialPrice': 2.50,
                'quantity': 10,
                'expiryDays': 60
              }),
              child: const Text("Capture 'Soda'"),
            )
          ],
        ),
      ),
    );
  }
}