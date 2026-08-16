# Bamako Moto

Un jeu d'arcade mobile : tu descends une avenue en moto, tu esquives les
sotramas, les taxis et les tas de sable. Plus tu tiens, plus ça va vite.

3D basse définition, faite avec [Godot 4.7](https://godotengine.org) en
GDScript.

## Lancer le jeu

Ouvre le dossier depuis le gestionnaire de projets de Godot, puis `F5`.

| | |
|---|---|
| Changer de voie | flèches gauche / droite, ou le doigt sur l'écran |
| Rejouer | espace |

## Comment c'est fait

**Aucun fichier d'image, aucun modèle 3D.** Toute la géométrie est
fabriquée au démarrage, en boîtes, par `scripts/fabrique.gd`. Pas de
logiciel de modélisation à apprendre, pas d'assets à acheter, et
l'application reste minuscule.

Quatre scripts, un rôle chacun :

- **`scripts/jeu.gd`** — la partie. Elle fait remonter l'avenue, décide
  quand un véhicule apparaît et sur quelle voie, anime la caméra, tient le
  score et le record. C'est le seul endroit où se règle la difficulté.
- **`scripts/troncon.gd`** — vingt mètres d'avenue : bitume, bas-côtés,
  bandes, décor. Douze exemplaires tournent en boucle.
- **`scripts/moto.gd`** — la moto. Elle n'avance pas : elle se décale, et
  c'est la route qui remonte vers elle.
- **`scripts/obstacle.gd`** — un véhicule. Il approche, il disparaît une
  fois passé, il ne sait rien du reste.

## Régler la difficulté

Dans l'inspecteur du nœud `Jeu`, ou en haut de `scripts/jeu.gd` :

| Réglage | Effet |
|---|---|
| `vitesse_depart` | allure de départ, en m/s (22 ≈ 80 km/h) |
| `acceleration` | ce que la vitesse gagne par seconde de survie |
| `vitesse_maximale` | le plafond |
| `espacement_depart` | mètres entre deux vagues, au début |
| `espacement_minimal` | le plus serré, en fin de partie |

L'espacement est exprimé **en distance et non en secondes** : la densité
de circulation reste donc la même quand on accélère, au lieu de devenir
infernale.

## Décisions qui ont une raison

**Rendu en « GL Compatibility »**, pas en « Forward+ ». C'est ce qui
décide si le jeu s'ouvre ou reste noir sur un téléphone d'entrée de gamme,
qui est l'essentiel du parc en Afrique de l'Ouest.

**Le bitume et les bandes ne projettent pas d'ombre.** Le calcul des
ombres est une seconde passe de rendu ; la couper sur ce qui est posé à
plat divise le coût sans qu'on voie la différence.

**Les huit bandes d'un tronçon sont un seul objet** (`MultiMesh`). Une par
objet coûtait une centaine d'appels de rendu pour l'avenue entière.

**Rien n'est créé pendant la partie**, sauf les véhicules : les douze
tronçons tournent en boucle, ce qui évite les à-coups.

**Les ombres ne sont calculées que sur les cinquante premiers mètres.**
Au-delà, la brume mange le décor : personne ne voit qu'il n'en projette
plus, mais tout ce qui sort de cette distance quitte la passe d'ombres.

### Matériel visé

Un téléphone de 2021 — Tecno Spark ou Camon, Samsung Galaxy A. C'est ce
qui décide du budget : environ 400 appels de rendu sont confortables, il
serait absurde d'appauvrir le décor pour des machines que plus personne
n'utilise.

Mesuré sur un portable de 2018 à carte graphique intégrée : **60 images
par seconde, 6 560 triangles, 387 appels de rendu.**

## Vérifier que ça marche

```
Godot_v4.7.1-stable_win64_console.exe --path . res://outils/test_collision.tscn
```

La moto se jette volontairement sur les véhicules et le test échoue si la
partie ne s'arrête pas. Une capture d'écran ne prouve pas qu'une collision
fonctionne ; ce test, oui. À rejouer après toute modification des gabarits
ou des couches de collision.

`res://outils/test_modes.tscn` essaie chaque entrée du catalogue et
vérifie que la sauvegarde fait l'aller-retour : une clé mal orthographiée
ne se verrait sinon qu'au moment où un joueur choisit cette moto-là.

`res://outils/apercu.tscn` et `res://outils/apercu_garage.tscn`
enregistrent une image et relèvent la vitesse d'affichage.

## Le garage

L'écran d'accueil. On y choisit sa moto, la couleur de son casque et son
mode, et on y dépense les pièces ramassées en jouant.

Tout ce qui se débloque est décrit dans `scripts/catalogue.gd`, et nulle
part ailleurs. Ajouter une moto, c'est ajouter une ligne : ni le garage ni
la partie n'ont à être touchés. Les noms sont inventés — aucune marque
réelle, jamais, un jeu qui affiche un nom de constructeur se fait retirer
de la boutique.

### Les motos

| | Prix | Ce qu'elle vaut |
|---|---|---|
| La Vaillante | gratuite | équilibrée, celle du départ |
| La Souple | 120 | tourne très bien, un peu lente |
| La Rapide | 260 | va vite, tourne mal |
| La Cuirassée | 420 | encaisse un choc |
| La Dorée | 900 | rapide, maniable, encaisse |

### Les modes

**Sans fin** — la course classique, ça accélère tout seul.
**Chrono** — quatre-vingt-dix secondes, et chaque pièce en rajoute deux.
C'est ce qui transforme la collecte en décision : aller chercher une pièce
coûte du risque mais rend du temps.
**Circulation folle** — départ à une fois et demie l'allure normale, vagues
resserrées d'un tiers.

Le mode et la moto se multiplient : une Rapide en Circulation folle démarre
à près du double de l'allure de base. C'est voulu — c'est la combinaison
que les joueurs cherchent une fois qu'ils maîtrisent.

## À faire

- [ ] **Recycler les véhicules et les pièces au lieu de les créer en cours
      de partie.** Une volée de pièces provoque encore un à-coup d'une
      image. Les tronçons tournent déjà en boucle ; il faut faire pareil
      pour le reste.
- [ ] Des quartiers qui se débloquent : le marché, le pont, la nuit
- [ ] Sons
- [ ] Export Android
- [ ] Multijoueur entre amis, partagé par WhatsApp

## Licence

Sega SISSOKO.
