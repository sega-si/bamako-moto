# Bamako Moto

Un jeu d'arcade mobile : tu descends une avenue en moto, tu esquives les
sotramas, les taxis et les nids-de-poule. Plus tu tiens, plus ça va vite.

Fait avec [Godot 4.7](https://godotengine.org), en GDScript.

## Lancer le jeu

Ouvre le dossier depuis le gestionnaire de projets de Godot, puis `F5`.

| | |
|---|---|
| Se déplacer | flèches gauche / droite, ou le doigt sur l'écran |
| Rejouer | espace |

## Comment c'est fait

Trois scripts, un rôle chacun :

- **`scripts/jeu.gd`** — la partie. Il fait défiler la route, décide quand
  un obstacle apparaît et sur quelle voie, tient le score et la vitesse.
  C'est le seul endroit où se règle la difficulté.
- **`scripts/moto.gd`** — la moto. Elle ne se déplace que latéralement :
  c'est la route qui défile sous elle, pas elle qui avance.
- **`scripts/obstacle.gd`** — un véhicule. Il descend, il se supprime en
  sortant de l'écran, il ne sait rien du reste.

La route ne bouge pas : c'est sa fenêtre de lecture qui se décale, ce qui
donne un défilement infini avec un seul nœud et sans raccord visible.

## Régler la difficulté

Tout est dans l'inspecteur du nœud `Jeu`, ou en haut de `scripts/jeu.gd` :

| Réglage | Effet |
|---|---|
| `vitesse_depart` | à quelle allure commence la partie |
| `acceleration` | ce que la vitesse gagne par seconde de survie |
| `vitesse_maximale` | le plafond |
| `intervalle_depart` | secondes entre deux véhicules, au début |
| `intervalle_minimal` | le plus serré possible, en fin de partie |

L'intervalle se resserre tout seul à mesure que la vitesse monte, sinon la
route se viderait au moment où elle devrait être la plus dense.

## Les images

Celles de `art/` sont provisoires, dessinées à la main en aplats. Elles
sont là pour que le jeu soit jouable, pas pour rester. Elles peuvent être
remplacées une par une : tant que les dimensions ne changent pas, rien
d'autre n'est à toucher.

## Choix techniques

**Rendu en « GL Compatibility »**, pas en « Forward+ ». C'est ce qui
permet au jeu de tourner sur les cartes graphiques intégrées et sur les
téléphones Android d'entrée de gamme, qui sont l'essentiel du parc en
Afrique de l'Ouest.

**Portrait 720 × 1280**, étiré en gardant la largeur : sur un téléphone
plus allongé, on voit simplement plus loin devant soi.

**Poids visé sous 20 Mo.** Les forfaits data se comptent en mégaoctets ;
un jeu lourd perd ses installations avant la fin du téléchargement.

## À faire

- [ ] Écran titre et meilleur score conservé entre deux parties
- [ ] Pièces à ramasser, et améliorations de la moto entre les parties
- [ ] Sons
- [ ] Export Android
- [ ] Multijoueur entre amis, partagé par WhatsApp

## Licence

Code et images : Sega SISSOKO.
