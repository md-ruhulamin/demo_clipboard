import 'package:flutter/material.dart';




class PremiumUpgradeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: const Color.fromRGBO(255, 255, 255, 1), // light blue background
     appBar:
      AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Upgrade Premium',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
     ,      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
              Image.asset(
                  'assets/audio.jpg',
                  height: 160,
                ),
              
             
                FeatureRow(icon: Icons.text_fields, text: 'Unlimited Access'),
                FeatureRow(icon: Icons.download, text: 'Offline Mode'),
    
                FeatureRow(icon: Icons.block, text: 'No Ads'),
                FeatureRow(icon: Icons.all_inclusive, text: 'No Limits'),
                SizedBox(height: 10),
                Text(
                  'SELECT PLAN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 5),
                PlanSelector(),
                Spacer(),
              
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class PlanSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        PlanCard(title: 'Weekly', price: '\$29', highlighted: false),
        PlanCard(title: 'Monthly', price: '\$59', highlighted: true),
        PlanCard(title: 'Yearly', price: '\$99', highlighted: false),
      ],
    );
  }
}

class PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final bool highlighted;

  const PlanCard({required this.title, required this.price, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? Colors.orange.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          if (highlighted)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Popular',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(price, style: TextStyle(fontSize: 14)),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            child: Text('BUY'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 32),
              padding: EdgeInsets.zero,
            ),
          )
        ],
      ),
    );
  }
}
