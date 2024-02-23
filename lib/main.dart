import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ProductListPage(),
    );
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late TextEditingController _productNameController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _searchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Products',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  // Perform search or filter operation based on value
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('product').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<DocumentSnapshot> products = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final data = product.data() as Map<String, dynamic>;

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        // border: Border.all(color: Colors.black),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Image.network(
                              data['image'],
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['Name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '${data['Discount']}% off',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${data['OriginalPrice'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₹${data['DiscountedPrice'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.yellow),
                                    Text('${data['AverageRating']}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProductDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }


  void _showAddProductDialog(BuildContext context) {
    double originalPrice = 0.0;
    int discount = 0;
    double discountedPrice = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter Product Name',
                ),
              ),
              TextField(
                onChanged: (value) => originalPrice = double.tryParse(value) ?? 0.0,
                decoration: const InputDecoration(
                  hintText: 'Enter Original Price',
                ),
              ),
              TextField(
                onChanged: (value) => discount = int.tryParse(value) ?? 0,
                decoration: const InputDecoration(
                  hintText: 'Enter Discount',
                ),
              ),
              TextField(
                onChanged: (value) => discountedPrice = double.tryParse(value) ?? 0.0,
                decoration: const InputDecoration(
                  hintText: 'Enter Discounted Price',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addProductToDatabase(_productNameController.text, originalPrice, discount, discountedPrice);
                Navigator.of(context).pop();
                _productNameController.clear();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }


  void _addProductToDatabase(String productName, double originalPrice, int discount, double discountedPrice) async {
    try {
      // Reference to the product document with the product name as document name
      DocumentReference productRef = FirebaseFirestore.instance.collection('product').doc(productName);

      // Create the product document if it does not exist
      if (!(await productRef.get()).exists) {
        await productRef.set({
          'Name': productName,
          'OriginalPrice': originalPrice,
          'Discount': discount,
          'DiscountedPrice': discountedPrice,
          'AverageRating': 0.0, // Default value for AverageRating
          'image': 'https://5.imimg.com/data5/SELLER/Default/2021/6/SF/ID/NM/16526614/allopathic-medicine-500x500.jpg', // Default image URL
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding product: $e');
      }
      // Handle error
    }
  }


  @override
  void dispose() {
    _productNameController.dispose();
    super.dispose();
  }
}
