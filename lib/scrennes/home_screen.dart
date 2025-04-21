import 'package:flutter/material.dart';
import 'package:gstock/scrennes/components_screen.dart';
import 'package:gstock/scrennes/members_screen.dart';
import 'package:gstock/scrennes/borrowings_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GStock Dashboard'),
        backgroundColor: Colors.indigo,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          _buildFeatureCard(
            context,
            'Components',
            Icons.computer,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ComponentsScreen()),
            ),
          ),
          _buildFeatureCard(
            context,
            'Members',
            Icons.people,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MembersScreen()),
            ),
          ),
          _buildFeatureCard(
            context,
            'Borrowings',
            Icons.inventory,
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BorrowingsScreen()),
            ),
          ),
          _buildFeatureCard(
            context,
            'Reports',
            Icons.assessment,
            Colors.purple,
            () {
              // TODO: Implement reports screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reports feature coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
} 