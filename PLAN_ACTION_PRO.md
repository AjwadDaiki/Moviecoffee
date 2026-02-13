# PLAN D'ACTION - MoovieCoffee v4.0 PRO

## VISION
Transformer MoovieCoffee en LA référence des apps sociales cinéma en France, combinant le meilleur de **Letterboxd** (stats) + **Tinder** (découverte) + **BeReal** (social authentique).

---

## PHASE 1 : FONDATIONS (1-2 semaines)
> Objectif : App stable, sécurisée, prête pour des utilisateurs réels

### 1.1 SÉCURITÉ CRITIQUE
| Tâche | Fichier | Priorité |
|-------|---------|----------|
| Restreindre CORS aux domaines autorisés | `main.py` | URGENT |
| Ajouter rate limiting (5 req/min login) | `main.py` | URGENT |
| Valider tous les inputs (regex, longueur) | `routes_*.py` | URGENT |
| Échapper les regex MongoDB | `routes_social.py` | URGENT |
| Forcer HTTPS en production | `api_service.dart` | URGENT |

### 1.2 BUGS CRITIQUES
| Bug | Fichier | Fix |
|-----|---------|-----|
| Streaks reset mal géré | `routes_stats.py` | Update longest_streak avant reset |
| Chat sans pagination | `routes_social.py` | Ajouter ?page=1&limit=50 |
| N+1 queries friends | `routes_social.py` | Bulk query avec $in |
| Orphan friend IDs | `routes_social.py` | Vérifier existence avant ajout |

### 1.3 AUTH COMPLET
- [ ] Email de vérification à l'inscription
- [ ] Endpoint `/auth/forgot-password`
- [ ] Endpoint `/auth/reset-password`
- [ ] Token de reset avec TTL 15min
- [ ] UI Flutter pour reset mot de passe

---

## PHASE 2 : PERFORMANCE (1 semaine)
> Objectif : App fluide même avec 10k+ utilisateurs

### 2.1 BACKEND
| Optimisation | Impact |
|--------------|--------|
| Redis cache pour `/stats/me` (TTL 5min) | -80% latence |
| Aggregation pipelines pour stats | -60% mémoire |
| Bulk queries pour listes amis | -90% requêtes |
| Indexes MongoDB optimisés | -70% temps query |
| Pagination sur tous les endpoints | Scalabilité |

### 2.2 FRONTEND
| Optimisation | Impact |
|--------------|--------|
| Pagination infinie (infinite_scroll) | UX fluide |
| Shimmer loading placeholders | UX perçue |
| Image caching agressif | -50% data |
| Lazy loading collections | -30% RAM |

---

## PHASE 3 : UX PREMIUM (2 semaines)
> Objectif : App "wow" qui donne envie de partager

### 3.1 ONBOARDING
```
Écran 1: "Bienvenue sur MoovieCoffee ☕"
         - Animation logo café
         - "Découvrez des films. Partagez vos émotions."

Écran 2: "Swipez pour découvrir"
         - Animation swipe gauche/droite
         - "Like = À voir, Dislike = Pas intéressé"

Écran 3: "Notez vos films vus"
         - Animation étoiles
         - "Swipe vers le haut pour les films déjà vus"

Écran 4: "Matchs avec vos amis"
         - Animation cœur
         - "Quand vous et un ami aimez le même film = Match!"

Écran 5: "Prêt? Commencez!"
         - Bouton "C'est parti"
```

### 3.2 ANIMATIONS
| Animation | Où | Package |
|-----------|-----|---------|
| Bounce buttons | Tous les boutons | flutter_animate |
| Hero transitions | Film card → Detail | Hero widget |
| Confetti match | Nouveau match | confetti |
| Pulse notification | Badge notification | AnimatedContainer |
| Parallax cards | Feed swipe | Transform |

### 3.3 DARK MODE
- Toggle dans Settings
- Palette CoffeeColors.dark
- Persist dans SharedPreferences
- Suivre système si "Auto"

### 3.4 PROFIL UTILISATEUR AMÉLIORÉ
```
┌─────────────────────────────────────┐
│  [Photo de profil]                  │
│  @username                          │
│  "Ma bio personnalisée"             │
│                                     │
│  ┌─────┐ ┌─────┐ ┌─────┐           │
│  │ 127 │ │ 4.2 │ │ Nv8 │           │
│  │Films│ │ ★   │ │     │           │
│  └─────┘ └─────┘ └─────┘           │
│                                     │
│  Genres préférés: Action, Thriller  │
│                                     │
│  🏆 Badges (5/11)                   │
│  [🍿] [🎬] [✍️] [🔥] [📅]           │
│                                     │
│  📊 Partager mes stats              │
│  ✏️ Modifier profil                 │
└─────────────────────────────────────┘
```

---

## PHASE 4 : SOCIAL++ (2 semaines)
> Objectif : Engagement viral et rétention

### 4.1 NOTIFICATIONS PUSH
| Event | Notification |
|-------|--------------|
| Nouveau match | "🎬 Nouveau match avec @user sur Film!" |
| Demande d'ami | "👋 @user veut être ton ami" |
| Message reçu | "💬 @user t'a envoyé un message" |
| Badge débloqué | "🏆 Tu as débloqué le badge Cinéphile!" |
| Streak reminder | "🔥 Continue ta série! 7 jours d'affilée" |

### 4.2 WEBSOCKET CHAT
- Real-time messages (pas de refresh)
- Typing indicators ("@user écrit...")
- Message read receipts (✓✓)
- Online status (point vert)

### 4.3 STORIES TEMPORAIRES
- Post story 24h (film du moment)
- Visible par tous les amis
- Réactions rapides (❤️ 😂 🔥)
- Compteur de vues

### 4.4 CHALLENGES HEBDO
| Challenge | Récompense |
|-----------|------------|
| "Regarde 5 films cette semaine" | +50 XP |
| "Note un film chaque jour" | +30 XP |
| "Découvre un nouveau genre" | Badge spécial |
| "Fais 3 matchs" | +20 XP |

---

## PHASE 5 : MONÉTISATION (2-3 semaines)
> Objectif : Revenus sans gâcher l'expérience

### 5.1 MODÈLE FREEMIUM

| Feature | Free | Premium (4.99€/mois) |
|---------|------|---------------------|
| Swipe films | ✅ 50/jour | ✅ Illimité |
| Stats basiques | ✅ | ✅ |
| Stats avancées | ❌ | ✅ |
| Thèmes custom | 1 seul | ✅ 10+ thèmes |
| Badges exclusifs | ❌ | ✅ 5 badges |
| Export HD stats | ❌ | ✅ |
| Pas de pubs | ❌ | ✅ |
| Support prioritaire | ❌ | ✅ |

### 5.2 ACHATS IN-APP
| Item | Prix | Description |
|------|------|-------------|
| Pack 100 swipes | 0.99€ | Pour les gros consommateurs |
| Thème "Neon Cinema" | 1.99€ | Thème néon exclusif |
| Badge "Fondateur" | 2.99€ | Badge permanent |
| Boost profil 24h | 0.99€ | Apparaître en premier dans recherche |

### 5.3 PUBS NON-INTRUSIVES
- Bannière en bas de l'écran Collection (pas Feed)
- Interstitiel après 20 swipes (skippable 5s)
- Rewarded video : +10 swipes bonus

---

## PHASE 6 : GROWTH (Continu)
> Objectif : Acquisition et rétention utilisateurs

### 6.1 ANALYTICS
| Métrique | Outil | Objectif |
|----------|-------|----------|
| DAU/MAU | Mixpanel | >40% |
| Retention D1/D7/D30 | Amplitude | 50/30/15% |
| Sessions/jour | Firebase | >2 |
| Temps/session | Firebase | >5min |
| Conversion premium | RevenueCat | >5% |

### 6.2 ASO (App Store Optimization)
```
Titre: MoovieCoffee - Films & Friends
Sous-titre: Swipe, note et partage tes films
Mots-clés: film, cinema, notation, social, match, recommendation

Screenshots:
1. Swipe de films avec "Découvre des films"
2. Stats visuelles avec "Tes stats"
3. Match notification avec "Partage avec tes amis"
4. Collection avec "Ta filmothèque"
```

### 6.3 REFERRAL PROGRAM
```
"Invite un ami → +50 swipes gratuits pour toi ET lui"

Paliers:
- 5 amis invités → Badge "Ambassadeur"
- 10 amis → 1 mois Premium gratuit
- 25 amis → Premium à vie
```

### 6.4 SOCIAL PROOF
- Reviews Store 4.5+ étoiles
- Témoignages utilisateurs dans l'app
- Compteur "500k+ films notés"
- Partenariats influenceurs ciné

---

## PHASE 7 : INFRASTRUCTURE (Continu)
> Objectif : Scalabilité et fiabilité

### 7.1 ARCHITECTURE CLOUD
```
┌────────────────────────────────────────────────────┐
│                   CLOUDFLARE                        │
│                   (CDN + DDoS)                      │
└────────────────────────────────────────────────────┘
                         │
┌────────────────────────────────────────────────────┐
│                   LOAD BALANCER                     │
│                   (AWS ALB)                         │
└────────────────────────────────────────────────────┘
         │                              │
┌─────────────────┐          ┌─────────────────┐
│   API Server 1  │          │   API Server 2  │
│   (FastAPI)     │          │   (FastAPI)     │
└─────────────────┘          └─────────────────┘
         │                              │
         └──────────┬───────────────────┘
                    │
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐             │
│  │ MongoDB │  │  Redis  │  │   S3    │             │
│  │ Atlas   │  │ Cache   │  │ Images  │             │
│  └─────────┘  └─────────┘  └─────────┘             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 7.2 MONITORING
| Outil | Usage |
|-------|-------|
| Sentry | Error tracking |
| DataDog | APM & logs |
| MongoDB Atlas | DB monitoring |
| UptimeRobot | Uptime alerts |
| PagerDuty | On-call alerts |

### 7.3 CI/CD
```yaml
# GitHub Actions
on:
  push:
    branches: [main]

jobs:
  test:
    - pytest backend/
    - flutter test

  deploy-staging:
    - Build Docker image
    - Push to ECR
    - Deploy to ECS staging

  deploy-prod:
    - Manual approval
    - Blue-green deployment
```

---

## TIMELINE GLOBALE

```
SEMAINE 1-2   │ PHASE 1: Fondations (Sécurité + Bugs)
              │
SEMAINE 3     │ PHASE 2: Performance (Cache + Pagination)
              │
SEMAINE 4-5   │ PHASE 3: UX Premium (Onboarding + Animations)
              │
SEMAINE 6-7   │ PHASE 4: Social++ (Push + WebSocket)
              │
SEMAINE 8-9   │ PHASE 5: Monétisation (Premium + Ads)
              │
SEMAINE 10+   │ PHASE 6-7: Growth + Infrastructure
              │
              ▼
         LAUNCH BETA (Semaine 10)
              │
              ▼
         LAUNCH PROD (Semaine 14)
```

---

## CHECKLIST PRÉ-LAUNCH

### BACKEND
- [ ] CORS restreint
- [ ] Rate limiting actif
- [ ] Input validation
- [ ] Password reset fonctionnel
- [ ] Email verification
- [ ] Redis cache
- [ ] Sentry configuré
- [ ] Logs centralisés
- [ ] Backup automatique
- [ ] Health check endpoint

### MOBILE
- [ ] Onboarding complet
- [ ] Dark mode
- [ ] Animations fluides
- [ ] Push notifications
- [ ] Deep links
- [ ] APK signé
- [ ] IPA signé
- [ ] Crashlytics
- [ ] Analytics

### LÉGAL
- [ ] Politique de confidentialité
- [ ] CGU
- [ ] Conformité RGPD
- [ ] Suppression compte
- [ ] Export données utilisateur

### MARKETING
- [ ] Landing page
- [ ] Screenshots Store
- [ ] Vidéo promo
- [ ] Compte Twitter/Instagram
- [ ] Press kit

---

## KPIs OBJECTIFS

| Métrique | M1 | M3 | M6 | M12 |
|----------|-----|-----|-----|------|
| Utilisateurs | 1k | 10k | 50k | 200k |
| DAU | 200 | 2k | 10k | 50k |
| Films notés | 5k | 100k | 500k | 2M |
| Premium | 0 | 500 | 5k | 20k |
| Revenue | 0€ | 2.5k€ | 25k€ | 100k€ |

---

## BUDGET ESTIMÉ

| Poste | Mensuel |
|-------|---------|
| MongoDB Atlas (M10) | 60€ |
| Redis Cloud | 30€ |
| AWS (ECS + ALB + S3) | 150€ |
| Sentry | 30€ |
| Apple Developer | 8€ |
| Google Play | 2€ |
| Cloudflare Pro | 20€ |
| **TOTAL** | **~300€/mois** |

---

## CONCLUSION

MoovieCoffee a tous les ingrédients pour devenir une app de référence :
- ✅ Concept original (Tinder + Letterboxd)
- ✅ Architecture solide
- ✅ Design premium
- ✅ Gamification engageante

**Prochaine étape immédiate** : Phase 1 - Sécurité & Bugs critiques.

Commençons maintenant ! 🚀
