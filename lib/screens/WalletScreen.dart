import 'package:flutter/material.dart';
import '../services/wallet_members_service.dart';
import '../services/wallet_service.dart';
import '../models/wallet_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _service = WalletService();
  List<Wallet> wallets = [];

  final List<String> types = ['personal', 'family', 'company'];

  @override
  void initState() {
    super.initState();
    loadWallets();
  }

  void openAddMemberDialog(String walletId) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Add Family Member"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: "User Email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;

              try {
                await WalletMembersService().addMember(
                    walletId,
                    emailController.text
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Member added successfully")),
                );

              } catch (e) {
                Navigator.pop(context);

                // Convert backend error to friendly message
                String errorMessage = "User not found. Please check the email";
                final errorStr = e.toString();

                if (errorStr.contains("User not found")) {
                  errorMessage = "User not found. Please check the email.";
                } else if (errorStr.contains("Wallet not found")) {
                  errorMessage = "Wallet not found.";
                } else if (errorStr.contains("User already in wallet")) {
                  errorMessage = "This user is already a member of this wallet.";
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }


  Future<void> loadWallets() async {
    wallets = await _service.getWallets();
    setState(() {});
  }

  Color getColor(String type) {
    switch (type) {
      case "personal":
        return const Color(0xFF2ECC71);
      case "family":
        return const Color(0xFF3498DB);
      case "company":
        return const Color(0xFFF39C12);
      default:
        return Colors.grey;
    }
  }

  IconData getIcon(String type) {
    switch (type) {
      case "personal":
        return Icons.person;
      case "family":
        return Icons.groups;
      case "company":
        return Icons.business;
      default:
        return Icons.account_balance_wallet;
    }
  }

  void openAddWallet() {
    String? selectedType;
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Add Wallet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              hint: const Text("Select Type"),
              items: types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                selectedType = value;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(
                labelText: "Balance",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedType == null ||
                  balanceController.text.isEmpty) return;

              bool exists =
              wallets.any((w) => w.type == selectedType);

              if (exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                    Text("This wallet type already exists"),
                  ),
                );
                return;
              }

              await _service.createWallet(
                name: "${selectedType![0].toUpperCase()}${selectedType!.substring(1)} Wallet",
                type: selectedType!,
                balance: double.parse(balanceController.text),
              );

              Navigator.pop(context);
              loadWallets();
            },
            child: const Text("Create"),
          )
        ],
      ),
    );
  }

  void updateBalance(Wallet wallet) {
    final controller =
    TextEditingController(text: wallet.balance.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Update ${wallet.type} wallet"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "New Balance",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _service.updateBalance(
                wallet.id,
                double.parse(controller.text),
              );
              Navigator.pop(context);
              loadWallets();
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  /// 🔴 NEW DELETE CONFIRMATION
  void confirmDeleteWallet(Wallet wallet) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Delete Wallet"),
          ],
        ),
        content: Text(
          "Are you sure you want to delete ${wallet.name}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await _service.deleteWallet(wallet.id);
              Navigator.pop(context);
              loadWallets();
            },
            icon: const Icon(Icons.delete),
            label: const Text("Delete"),
          ),
        ],
      ),
    );
  }
  void showMembersDialog(String walletId) async {
    try {
      final members = await WalletMembersService().getMembers(walletId);

      showDialog(
        context: context,
        builder: (_) => StatefulBuilder(  // Needed to refresh dialog after deletion
          builder: (context, setStateDialog) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Wallet Members"),
            content: SizedBox(
              width: double.maxFinite,
              child: members.isEmpty
                  ? const Text("No members in this wallet")
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(member['user']['name'] ?? member['user']['email']),
                    subtitle: Text(member['user']['email']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        try {
                          await WalletMembersService().removeMember(walletId, member['user']['id']);
                          setStateDialog(() {
                            members.removeAt(index);  // remove from local list
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Member removed successfully")),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error removing member: $e")),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching members: $e")),
      );
    }
  }



  Widget walletCard(Wallet wallet) {
    final color = getColor(wallet.type);

    return GestureDetector(
      onLongPress: () {
        if (wallet.type == 'family') {
          showMembersDialog(wallet.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                getIcon(wallet.type),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wallet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    "${wallet.balance.toStringAsFixed(2)} ${wallet.currency}",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (wallet.type == 'family')
              IconButton(
                icon: const Icon(Icons.person_add, size: 20),
                onPressed: () => openAddMemberDialog(wallet.id),
              ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => updateBalance(wallet),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => confirmDeleteWallet(wallet),
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Wallets"),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddWallet,
        child: const Icon(Icons.add),
      ),
      body: wallets.isEmpty
          ? const Center(
        child: Text(
          "No wallets yet",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: wallets.length,
        itemBuilder: (context, index) {
          return walletCard(wallets[index]);
        },
      ),
    );
  }
}
