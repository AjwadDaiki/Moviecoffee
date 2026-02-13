# 🎬 MoovieCoffee - Product Vision & Roadmap

## 🎯 Vision Produit
**"Tinder pour les films, mais en mieux"** - Une app de découverte de films sociale, ludique et émotionnelle pour couples et amis.

---

## ✅ PHASE 1 COMPLÉTÉE : "WOW EFFECT" (v2.1)

### 🎉 Système de Match Explosif ✅
**Implémenté !**
- ✅ Endpoint backend `/action/check-match` : Détecte si un LIKE crée un match avec le partenaire
- ✅ Dialog animé `MatchAnimationDialog` avec :
  - Confettis animés (CustomPainter)
  - Animation d'échelle élastique (elasticOut curve)
  - Design "IT'S A MATCH!" premium
  - Affichage du film matché avec infos
- ✅ Intégration dans `FeedScreen` : Check automatique à chaque LIKE
- ✅ Feedback haptique :
  - `HapticFeedback.heavyImpact()` sur match
  - `HapticFeedback.lightImpact()` sur like normal
  - `HapticFeedback.mediumImpact()` sur "Déjà vu"

**Résultat :** L'utilisateur ressent un **moment de joie intense** quand il matche avec son partenaire !

---

### 🎨 Collection Screen Premium Design ✅
**Implémenté !**
- ✅ **Cards enrichies avec gradient overlay** :
  - Étoiles visuelles (★★★★☆) au lieu d'un simple badge
  - Extrait du commentaire affiché (2 lignes max, italique)
  - Ombre portée pour profondeur
- ✅ **Affordance améliorée pour films non notés** :
  - Overlay sombre avec icône edit centrée + badge orange
  - Texte "Tap to rate" explicite
  - Plus de confusion sur "comment noter un film"
- ✅ **Icône "touch" sur films notés** :
  - Petit badge en haut à droite pour indiquer qu'on peut rééditer
  - Design minimaliste, ne perturbe pas l'affiche

**Résultat :** L'historique est maintenant **visuellement riche** et **intuitif** !

---

## 🚀 PHASE 2 : GAMIFICATION & ENGAGEMENT (À venir)

### 🏆 Système de Badges/Achievements
**Statut : Design complet, implémentation prête**

#### Structure de données (à ajouter dans `User` model) :
```python
class Achievement(BaseModel):
    id: str  # "novice", "cinephile", "critic", etc.
    unlocked_at: Optional[datetime] = None
    progress: int = 0  # Pour les badges progressifs

class User(Document):
    ...
    achievements: List[Achievement] = []
    xp: int = 0
    level: int = 1
```

#### Badges proposés :
| Badge | Condition | XP | Icône |
|-------|-----------|-----|-------|
| 🍿 **Novice** | 5 films notés | 50 | `Icons.movie_filter` |
| 🎬 **Cinéphile** | 25 films notés | 150 | `Icons.movie` |
| 👑 **Master** | 100 films notés | 500 | `Icons.emoji_events` |
| ✍️ **Critique** | 15 commentaires écrits | 100 | `Icons.edit_note` |
| 💑 **Soul Mates** | 10 matchs avec partenaire | 200 | `Icons.favorite` |
| 🔥 **Binge Watcher** | 10 films en 7 jours | 80 | `Icons.whatshot` |
| 🌟 **Perfectionniste** | 20 films notés 5/5 | 120 | `Icons.star` |
| 🎭 **Éclectique** | Noté films de 10 genres différents | 150 | `Icons.palette` |

#### Écran d'affichage :
- **Tab "Profil" redesigné** avec section "Mes Achievements"
- **Grid de badges** : Débloqueés (couleur) vs Verrouillés (gris + cadenas)
- **Barre de progression XP** avec animation au level-up
- **Animation "Badge Unlocked!"** (similaire au Match) quand on débloque

---

### 📊 Stats Visuelles Enrichies
**Statut : Spec complète**

#### Widgets à créer :
1. **Graphique en Donut** (répartition des genres) :
   - Package : `fl_chart`
   - Couleurs custom par genre (Action=rouge, Comédie=jaune, etc.)
   - Tap sur une section → Filtre l'historique par ce genre

2. **Timeline** (films vus par mois) :
   - Mini bar chart des 6 derniers mois
   - Montre la régularité de visionnage

3. **Compatibilité avec partenaire** :
   - **% de matchs** : (matchs / total_vus) * 100
   - Jauge visuelle type "Love Meter"
   - Message contextuel : "Vous êtes sur la même longueur d'onde !"

4. **Podium Top 3** :
   - Les 3 films les mieux notés par l'utilisateur
   - Affiches + notes + médailles (🥇🥈🥉)

#### Endpoint backend à créer :
```python
@app.get("/stats/advanced")
async def get_advanced_stats(user: User = Depends(get_current_user)):
    # Calculs :
    # - Répartition genres (Counter avec %)
    # - Timeline mensuelle
    # - % compatibilité avec partenaire
    # - Top 3 films
    return {...}
```

---

### 🎭 Filtres par Humeur (Innovation)
**Statut : Concept validé**

#### UI proposée :
- **Bouton flottant** en haut du Feed : "🎭 Mood Filter"
- **Modal avec 5 choix** :
  - 😢 **Pleurer** → Drame, Romance
  - 😂 **Rire** → Comédie
  - 😱 **Avoir peur** → Horreur, Thriller
  - 🤔 **Réfléchir** → Documentaire, Sci-Fi
  - 🚀 **M'évader** → Action, Aventure, Fantasy

#### Backend :
- Ajouter un paramètre `?mood=laugh` au `/feed`
- Filtrer les films par genres associés
- **Cache intelligent** : Garder 20 films par mood en mémoire

---

## 🎨 PHASE 3 : POLISH & MICRO-ANIMATIONS

### Animations à ajouter :
1. **Bounce sur tap** :
   - Boutons du Feed (LIKE/DISLIKE)
   - Étoiles dans la modal de notation
   - Package : `flutter_animate`

2. **Shimmer loading** :
   - Placeholders des affiches pendant le chargement
   - Package : `shimmer`

3. **Hero transitions** :
   - Affiche du Feed → Modal détails
   - Collection → Modal d'édition

4. **Swipe feedback visuel** :
   - Overlay vert/rouge qui apparaît selon la direction
   - Indicateur de "distance" pour valider le swipe

---

## 📱 QUICK WINS (Faciles à implémenter, gros impact)

### 1. Empty States améliorés ✅ (Déjà fait !)
- Illustrations sympas au lieu de texte brut

### 2. Pull-to-Refresh ✅ (Déjà fait !)
- Collection screen

### 3. Search Bar (30 min)
- Dans la Collection : Rechercher un film par titre
- Filtrer localement la liste

### 4. Dark Mode (1h)
- Toggle dans les Settings
- Nouvelle palette de couleurs

### 5. Onboarding (2h)
- 3 écrans d'intro pour les nouveaux users
- Expliquer le concept de "Match"

---

## 🔮 PHASE 4 : FONCTIONNALITÉS AVANCÉES

### 1. Intégration Plateformes Streaming
**Complexité : Moyenne**
- API JustWatch pour récupérer disponibilité Netflix/Prime/Disney+
- Badge "Disponible sur..." sur l'affiche
- Filtre "Disponible sur ma plateforme"

### 2. Recommandations IA
**Complexité : Élevée**
- Algorithme ML basé sur les films aimés
- Suggestions personnalisées en priorité dans le Feed

### 3. Mode "Soirée Film"
**Complexité : Faible**
- Swiper en mode "simultané" avec le partenaire en temps réel
- Socket.io pour synchronisation
- Si les deux swipent Right en même temps → SUPER MATCH

### 4. Partage Social
**Complexité : Faible**
- Partager son Top 3 sur Instagram/Twitter
- Template graphique auto-généré

---

## 📈 MÉTRIQUES DE SUCCÈS

### KPIs à tracker :
1. **Engagement** :
   - DAU/MAU ratio > 40%
   - Session duration > 5 min
   - Films swipés/session > 10

2. **Rétention** :
   - Day 1 retention > 60%
   - Day 7 retention > 30%
   - Day 30 retention > 15%

3. **Social** :
   - % d'users avec partenaire lié > 50%
   - Matchs/user/semaine > 2
   - Commentaires écrits/user > 5

4. **Monétisation (future)** :
   - Premium subscribers (unlock +features)
   - ARPU > 2€/mois

---

## 🛠️ STACK TECHNIQUE

### Frontend (Flutter)
- **State Management** : Provider (actuel) → Riverpod (migration recommandée)
- **Animations** : flutter_animate, shimmer, lottie
- **Charts** : fl_chart
- **Networking** : Dio + retry logic
- **Cache** : flutter_cache_manager

### Backend (FastAPI)
- **Database** : MongoDB avec indexation optimisée
- **Cache** : Redis pour les stats/feed
- **Queue** : Celery pour calculs asynchrones (stats, recommandations)
- **Monitoring** : Sentry pour error tracking

### DevOps
- **Backend** : Docker + Kubernetes
- **Database** : MongoDB Atlas (scalabilité automatique)
- **CDN** : Cloudflare pour les images TMDB

---

## 🎯 PROCHAINES ÉTAPES IMMÉDIATES

### Sprint 1 (Cette semaine) :
1. ✅ Système de Match → **FAIT !**
2. ✅ Cards premium Collection → **FAIT !**
3. ✅ Haptic feedback → **FAIT !**
4. 🔄 Corriger les warnings `withOpacity` (remplacer par `.withValues()`)
5. 🔄 Ajouter Search Bar dans Collection
6. 🔄 Tests utilisateurs : Valider l'UX du Match

### Sprint 2 (Semaine prochaine) :
1. Système de Badges complet
2. Stats avancées avec graphiques
3. Filtres par Humeur
4. Micro-animations (bounce, shimmer)

### Sprint 3 (Dans 2 semaines) :
1. Dark Mode
2. Onboarding
3. Mode "Soirée Film" (temps réel)

---

## 💎 CONCLUSION

**MoovieCoffee v2.1** est maintenant une application qui **émeut** et **engage** :
- ✅ Les matchs créent des moments magiques
- ✅ L'UI est premium et intuitive
- ✅ Les interactions sont fluides et satisfaisantes

**Prochaine étape :** Transformer l'engagement en **habitude** grâce à la gamification et aux stats visuelles.

**Objectif final :** Une app dans le **Top 100 Lifestyle** de l'App Store d'ici 3 mois.

---

_Dernière mise à jour : 22/01/2026_
_Version actuelle : 2.1.0 "WOW Effect"_
