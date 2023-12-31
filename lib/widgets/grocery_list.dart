import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'chandra-chat-app-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');

    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later!';
        });
      }

      // handle the case when we get empty response, which means there are no data in firebase
      if (response.body == 'null') {
        setState(() {
          // if is is not set false, it will show the loading screen all the time when there is no data
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadItems = [];
      for (final item in listData.entries) {
        // here firstWhere would return the first matching entry of type <key, val> , for accessing the category, we have to use .value at end
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }

      setState(() {
        _groceryItems = loadItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again later!';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
        context,
        MaterialPageRoute(
          builder: (context) => const NewItem(),
        ));

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
        'chandra-chat-app-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // if the delete request is not successful, then we want to add the item back to the list
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // fallback content when the list is empty
    Widget content = const Center(
      child: Text('No items added yet.'),
    );

    // show some spinner screen in case it is loading
    if (_isLoading == true) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    // show error message if there is some issue
    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index]
              .id), // the key should be uniquety identifiable
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
