import 'package:flutter/material.dart';

class ManagerMenuScreen extends StatelessWidget {
  const ManagerMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('STORE OPERATIONS'),
                    const SizedBox(height: 10),
                    _buildMenuGrid([
                      _MenuItem(
                        label: 'Inventory\nManagement',
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFF2196F3),
                        bgColor: const Color(0xFFE3F2FD),
                      ),
                      _MenuItem(
                        label: 'Product\nManagement',
                        icon: Icons.local_grocery_store_rounded,
                        color: const Color(0xFF4CAF50),
                        bgColor: const Color(0xFFE8F5E9),
                      ),
                      _MenuItem(
                        label: 'Order\nManagement',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFFFF9800),
                        bgColor: const Color(0xFFFFF3E0),
                      ),
                      _MenuItem(
                        label: 'Import\nGoods',
                        icon: Icons.move_to_inbox_rounded,
                        color: const Color(0xFF9C27B0),
                        bgColor: const Color(0xFFF3E5F5),
                      ),
                    ]),

                    const SizedBox(height: 20),
                    _buildSectionTitle('STAFF MANAGEMENT'),
                    const SizedBox(height: 10),
                    _buildMenuGrid([
                      _MenuItem(
                        label: 'Staff\nList',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF00BCD4),
                        bgColor: const Color(0xFFE0F7FA),
                      ),
                      _MenuItem(
                        label: 'Work\nSchedule',
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFF3F51B5),
                        bgColor: const Color(0xFFE8EAF6),
                      ),
                      _MenuItem(
                        label: 'Attendance\n& Shift',
                        icon: Icons.access_time_filled_rounded,
                        color: const Color(0xFFFF5722),
                        bgColor: const Color(0xFFFBE9E7),
                      ),
                      _MenuItem(
                        label: 'Salary &\nPayroll',
                        icon: Icons.payments_rounded,
                        color: const Color(0xFF009688),
                        bgColor: const Color(0xFFE0F2F1),
                      ),
                    ]),

                    const SizedBox(height: 20),
                    _buildSectionTitle('REPORTS & ANALYTICS'),
                    const SizedBox(height: 10),
                    _buildMenuGrid([
                      _MenuItem(
                        label: 'Sales\nReport',
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFFF44336),
                        bgColor: const Color(0xFFFFEBEE),
                      ),
                      _MenuItem(
                        label: 'Revenue\nSummary',
                        icon: Icons.attach_money_rounded,
                        color: const Color(0xFF8BC34A),
                        bgColor: const Color(0xFFF1F8E9),
                      ),
                    ]),

                    const SizedBox(height: 20),
                    _buildSectionTitle('STORE SETTINGS'),
                    const SizedBox(height: 10),
                    _buildMenuGrid([
                      _MenuItem(
                        label: 'Promotion &\nDiscount',
                        icon: Icons.local_offer_rounded,
                        color: const Color(0xFFE91E63),
                        bgColor: const Color(0xFFFCE4EC),
                      ),
                      _MenuItem(
                        label: 'Supplier\nManagement',
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFF795548),
                        bgColor: const Color(0xFFEFEBE9),
                      ),
                      _MenuItem(
                        label: 'Store\nProfile',
                        icon: Icons.store_rounded,
                        color: const Color(0xFF607D8B),
                        bgColor: const Color(0xFFECEFF1),
                      ),
                      _MenuItem(
                        label: 'Notifications',
                        icon: Icons.notifications_rounded,
                        color: const Color(0xFFFF9800),
                        bgColor: const Color(0xFFFFF8E1),
                      ),
                    ]),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.manage_accounts_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manager Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Convenient Store Chain Management',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5C6BC0),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildMenuGrid(List<_MenuItem> items) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) => _buildMenuCard(item)).toList(),
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
