import 'package:flutter/material.dart';
import 'package:smart_wallet_app/services/wallet_service.dart';
import 'package:smart_wallet_app/services/RecurringTransactionService.dart';
import 'package:smart_wallet_app/services/AlertService.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';
import 'package:smart_wallet_app/models/RecurringTransaction.dart';
import 'package:smart_wallet_app/models/AlertModel.dart';
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
  final RecurringTransactionService _recurringService = RecurringTransactionService();
  final AlertService _alertService = AlertService();
  final _addMemberController = TextEditingController();
  int _unreadAlertsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadAlerts();
    // Check and auto-generate recurring transactions when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndGenerateRecurring();
    });
  }

  @override
  void dispose() {
    _addMemberController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadAlerts() async {
    try {
      final alerts = await _alertService.getUserAlerts(widget.userId);
      final unreadCount = alerts.where((a) => !a.isRead).length;

      if (mounted) {
        setState(() {
          _unreadAlertsCount = unreadCount;
        });
      }
    } catch (e) {
      print('Error loading alerts: $e');
    }
  }

  Future<void> _checkAndGenerateRecurring() async {
    try {
      // Get all recurring transactions for this wallet
      final recurring = await _recurringService.getWalletRecurring(widget.walletId);

      // Count overdue ones
      final overdueList = recurring.where((r) => r.isOverdue).toList();
      final overdueCount = overdueList.length;

      if (overdueCount > 0) {
        // Show confirmation popup
        if (!mounted) return;

        final shouldGenerate = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.repeat, color: Colors.orange[700]),
                const SizedBox(width: 12),
                const Text('Recurring Transactions'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have $overdueCount pending recurring transaction${overdueCount > 1 ? 's' : ''}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...overdueList.take(3).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: r.type == 'income' ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${r.description ?? 'Transaction'} (\$${r.amount.toStringAsFixed(2)})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
                if (overdueCount > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'and ${overdueCount - 3} more...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Generate them now?',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Generate Now'),
              ),
            ],
          ),
        );

        if (shouldGenerate == true && mounted) {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            // Generate all due transactions
            final result = await _recurringService.generateAllUserTransactions(widget.userId);
            final generatedCount = result['totalGenerated'] ?? 0;

            if (!mounted) return;

            // Close loading
            Navigator.pop(context);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Generated $generatedCount transaction(s)!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Refresh the screen
            setState(() {});
          } catch (e) {
            if (!mounted) return;

            // Close loading
            Navigator.pop(context);

            // Show error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error generating transactions: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking recurring transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Details'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          // Alerts Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => _showAlertsBottomSheet(),
              ),
              if (_unreadAlertsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadAlertsCount > 9 ? '9+' : '$_unreadAlertsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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

  void _showAlertsBottomSheet() async {
    final alerts = await _alertService.getUserAlerts(widget.userId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget Alerts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (alerts.any((a) => !a.isRead))
                    TextButton(
                      onPressed: () async {
                        // Mark all as read
                        for (var alert in alerts.where((a) => !a.isRead)) {
                          await _alertService.markAsRead(alert.id);
                        }
                        Navigator.pop(context);
                        _loadUnreadAlerts();
                        setState(() {});
                      },
                      child: const Text('Mark All Read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Alerts List
            Expanded(
              child: alerts.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No alerts',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                controller: scrollController,
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _buildAlertCard(alert);
                },
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Refresh alert count when bottom sheet closes
      _loadUnreadAlerts();
    });
  }

  Widget _buildAlertCard(AlertModel alert) {
    Color color;
    IconData icon;

    switch (alert.alertType) {
      case 'danger':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info;
    }

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await _alertService.deleteAlert(alert.id);
        _loadUnreadAlerts();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: alert.isRead ? Colors.white : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.isRead ? Colors.grey[300]! : color.withOpacity(0.3),
          ),
        ),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            alert.message,
            style: TextStyle(
              fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            _formatAlertDate(alert.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: alert.isRead
              ? null
              : Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          onTap: () async {
            if (!alert.isRead) {
              await _alertService.markAsRead(alert.id);
              _loadUnreadAlerts();
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  String _formatAlertDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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