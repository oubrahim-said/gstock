import 'package:flutter/material.dart';
import 'package:gstock/scrennes/databaseHelper.dart';

class BorrowingsScreen extends StatefulWidget {
  @override
  _BorrowingsScreenState createState() => _BorrowingsScreenState();
}

class _BorrowingsScreenState extends State<BorrowingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  List<Map<String, dynamic>> _components = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _borrowings = [];
  List<Map<String, dynamic>> _filteredBorrowings = [];
  int? _selectedComponentId;
  int? _selectedMemberId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final components = await DatabaseHelper().getComponents();
    final members = await DatabaseHelper().getMembers();
    final borrowings = await DatabaseHelper().getPendingBorrowings();
    setState(() {
      _components = components;
      _members = members;
      _borrowings = borrowings;
      _filteredBorrowings = borrowings;
      _isLoading = false;
    });
  }

  Future<void> _addBorrowing() async {
    if (_formKey.currentState!.validate() &&
        _selectedComponentId != null &&
        _selectedMemberId != null) {
      await DatabaseHelper().insertBorrowing({
        'component_id': _selectedComponentId,
        'member_id': _selectedMemberId,
        'quantity': int.parse(_quantityController.text),
        'status': 'pending',
      });

      _quantityController.clear();
      setState(() {
        _selectedComponentId = null;
        _selectedMemberId = null;
      });

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Borrowing recorded successfully')),
        );
      }
    }
  }

  Future<void> _returnComponent(int borrowingId, String status) async {
    await DatabaseHelper().updateBorrowingStatus(borrowingId, status);
    await _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Component returned successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Borrowings Management'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Pending Borrowings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredBorrowings.length,
                    itemBuilder: (context, index) {
                      final borrowing = _filteredBorrowings[index];
                      final component = _components.firstWhere(
                        (c) => c['id'] == borrowing['component_id'],
                        orElse: () => {'name': 'Unknown'},
                      );
                      final member = _members.firstWhere(
                        (m) => m['id'] == borrowing['member_id'],
                        orElse: () => {
                          'first_name': 'Unknown',
                          'last_name': 'Member',
                        },
                      );

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(component['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Borrowed by: ${member['first_name']} ${member['last_name']}'),
                              Text('Quantity: ${borrowing['quantity']}'),
                              Text(
                                  'Date: ${borrowing['borrow_date'].toString().split('T')[0]}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (status) =>
                                _returnComponent(borrowing['id'], status),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'returned',
                                child: Text('Returned (Intact)'),
                              ),
                              PopupMenuItem(
                                value: 'damaged',
                                child: Text('Returned (Damaged)'),
                              ),
                              PopupMenuItem(
                                value: 'severely_damaged',
                                child: Text('Returned (Severely Damaged)'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('New Borrowing'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedComponentId,
                      decoration: InputDecoration(labelText: 'Component'),
                      items: _components.map((component) {
                        return DropdownMenuItem<int>(
                          value: component['id'],
                          child: Text(component['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedComponentId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a component';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10,),

                    DropdownButtonFormField<int>(
                      value: _selectedMemberId,
                      decoration: InputDecoration(labelText: 'Member'),
                      items: _members.map((member) {
                        return DropdownMenuItem<int>(
                          value: member['id'],
                          child: Text(
                              '${member['first_name']} ${member['last_name']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedMemberId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a member';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10,),

                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _addBorrowing();
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text('Add'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
} 