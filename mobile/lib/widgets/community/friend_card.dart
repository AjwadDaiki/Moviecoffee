import 'package:flutter/material.dart';
import '../../theme/coffee_colors.dart';

class FriendCard extends StatelessWidget {
  final String username;
  final String? bio;
  final int totalSeen;
  final int level;
  final bool isFriend;
  final bool isFollowing;
  final bool requestSent;
  final bool requestReceived;
  final VoidCallback? onTap;
  final VoidCallback? onAddFriend;
  final VoidCallback? onAcceptRequest;
  final VoidCallback? onFollow;

  const FriendCard({
    super.key,
    required this.username,
    this.bio,
    required this.totalSeen,
    required this.level,
    this.isFriend = false,
    this.isFollowing = false,
    this.requestSent = false,
    this.requestReceived = false,
    this.onTap,
    this.onAddFriend,
    this.onAcceptRequest,
    this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.96),
              const Color(0xFFF4EDE3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CoffeeColors.creamBorder.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: CoffeeColors.espresso.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [CoffeeColors.caramelBronze, CoffeeColors.terracotta],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username + Level
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CoffeeColors.espresso,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (level > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CoffeeColors.caramelBronze.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: CoffeeColors.caramelBronze,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Lvl $level',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: CoffeeColors.caramelBronze,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Bio ou stats
                  if (bio != null && bio!.isNotEmpty)
                    Text(
                      bio!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CoffeeColors.moka,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      '$totalSeen films vus',
                      style: const TextStyle(
                        fontSize: 13,
                        color: CoffeeColors.moka,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Bouton action
            if (requestReceived)
              // Demande à accepter
              GestureDetector(
                onTap: onAcceptRequest,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Accepter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else if (requestSent)
              // Demande envoyée
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CoffeeColors.steamMilk.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 14, color: CoffeeColors.moka),
                    const SizedBox(width: 4),
                    Text(
                      'En attente',
                      style: TextStyle(color: CoffeeColors.moka, fontSize: 12),
                    ),
                  ],
                ),
              )
            else if (isFriend)
              // Déjà ami
              Icon(Icons.check_circle, color: Colors.green.shade400, size: 24)
            else if (isFollowing)
              // Déjà suivi
              Icon(
                Icons.person_add_disabled,
                color: CoffeeColors.moka,
                size: 22,
              )
            else
              // Bouton ajouter
              GestureDetector(
                onTap: onAddFriend,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CoffeeColors.caramelBronze,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.person_add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Ajouter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Version compacte pour listes
class CompactFriendCard extends StatelessWidget {
  final String username;
  final int totalSeen;
  final VoidCallback? onTap;

  const CompactFriendCard({
    super.key,
    required this.username,
    required this.totalSeen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CoffeeColors.caramelBronze,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CoffeeColors.espresso,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$totalSeen films',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CoffeeColors.moka,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: CoffeeColors.steamMilk,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
