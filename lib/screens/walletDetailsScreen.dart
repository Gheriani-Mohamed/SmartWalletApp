import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/wallet_service.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:smart_wallet_app/screens/editWalletScreen.dart';
import 'package:smart_wallet_app/screens/transactionListScreen.dart';
import 'package:smart_wallet_app/screens/budgetListScreen.dart';
import 'package:smart_wallet_app/screens/reccuringListScreen.dart';

class WalletDetailsScreen extends StatefulWidget {
  final String walletId;
  final String userId;

  const WalletDetailsScreen({
    super.key,
    required this.walletId,
    required this.userId,
  });

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen> {
  final WalletService _walletService = WalletService();
  final _addMemberController = TextEditingController();

  @override
  void dispose() {
    _addMemberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Details'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: FutureBuilder<WalletModel>(
        future: _loadWallet(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final wallet = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  _buildBalanceCard(wallet),
                  const SizedBox(height: 16),

                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionListScreen(
                                  walletId: wallet.id,
                                  userId: widget.userId,
                                ),
                              ),
                            );

                            if (result == true || result == null) {
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Transactions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BudgetListScreen(
                                  walletId: wallet.id,
                                  userId: widget.userId,
                                ),
                              ),
                            );

                            if (result == true || result == null) {
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.pie_chart),
                          label: const Text('Budgets'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Recurring button (full width)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecurringListScreen(
                              walletId: wallet.id,
                              userId: widget.userId,
                            ),
                          ),
                        );

                        if (result == true || result == null) {
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.repeat),
                      label: const Text('Recurring Transactions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wallet Info
                  _buildInfoCard(wallet),
                  const SizedBox(height: 24),

                  // Members Section
                  _buildMembersSection(wallet),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<WalletModel> _loadWallet() async {
    return await _walletService.getWalletById(widget.walletId);
  }

  Widget _buildBalanceCard(WalletModel wallet) {
    Color walletColor;
    IconData walletIcon;

    switch (wallet.type) {
      case 'family':
        walletColor = AppConstants.familyColor;
        walletIcon = Icons.family_restroom;
        break;
      case 'company':
        walletColor = AppConstants.companyColor;
        walletIcon = Icons.business;
        break;
      default:
        walletColor = AppConstants.personalColor;
        walletIcon = Icons.person;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [walletColor, walletColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: walletColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(walletIcon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wallet.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            wallet.type.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${wallet.currency} ${wallet.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(WalletModel wallet) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Created',
              _formatDate(wallet.createdAt),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.update,
              'Last Updated',
              _formatDate(wallet.updatedAt),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.people,
              'Members',
              '${wallet.memberCount} ${wallet.memberCount == 1 ? 'member' : 'members'}',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.monetization_on,
              'Currency',
              wallet.currency,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(WalletModel wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddMemberDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (wallet.members.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No members yet'),
            ),
          )
        else
          ...wallet.members.map((member) => _buildMemberCard(member, wallet)),
      ],
    );
  }

  Widget _buildMemberCard(WalletMember member, WalletModel wallet) {
    final isCurrentUser = member.userId == widget.userId;
    final canRemove = wallet.memberCount > 1 && !isCurrentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.primaryGreen,
          child: Text(
            member.user.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.user.email),
            const SizedBox(height: 4),
            Text(
              'Joined ${_formatDate(member.joinedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: canRemove
            ? IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _confirmRemoveMember(member),
        )
            : null,
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email address of the person you want to add:'),
            const SizedBox(height: 16),
            TextField(
              controller: _addMemberController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'example@email.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addMemberController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _addMember();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMember() async {
    final email = _addMemberController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter an email', Colors.red);
      return;
    }

    try {
      await _walletService.addMember(widget.walletId, email);

      if (!mounted) return;

      _addMemberController.clear();
      _showSnackBar('Member added successfully!', Colors.green);
      setState(() {}); // Refresh
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _confirmRemoveMember(WalletMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.user.name} from this wallet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeMember(member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(WalletMember member) async {
    try {
      await _walletService.removeMember(widget.walletId, member.userId);

      if (!mounted) return;

      _showSnackBar('Member removed', Colors.green);
      setState(() {}); // Refresh
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showEditDialog() async {
    // Load current wallet data
    final wallet = await _loadWallet();

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditWalletScreen(wallet: wallet),
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh wallet details
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: const Text(
          'Are you sure you want to delete this wallet? This will also delete all associated budgets and transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteWallet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWallet() async {
    try {
      await _walletService.deleteWallet(widget.walletId);

      if (!mounted) return;

      _showSnackBar('Wallet deleted', Colors.green);
      Navigator.pop(context, true); // Return to list
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}