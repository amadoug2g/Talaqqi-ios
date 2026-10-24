# Shadowing coranique (nom provisoire)

Application iOS personnelle, 100 % Swift et SwiftUI, pour mémoriser le Coran par shadowing : écouter un récitant morceau par morceau, répéter à voix haute dans le silence qui suit, ajouter le morceau suivant quand le précédent est acquis, et comprendre ce que l'on récite grâce à la traduction.

## À lire en premier

- `docs/BRIEF_CLAUDE_CODE.md` : le brief complet du projet (fonctionnement, audio, contenu, sources, périmètre de la version 1).
- `docs/design/` : les maquettes validées (PNG pour le visuel, HTML pour les valeurs exactes).
- `docs/BRIEF_DESIGN.md` : les intentions de design et la liste des interdits.
- `docs/prototype/` : le prototype web, référence de comportement.

## Règles permanentes

- Toujours proposer un plan et attendre ma validation avant d'écrire ou de modifier du code. Poser la question plutôt que supposer.
- **Aucun contenu religieux généré par IA** : texte arabe, phonétique, traduction et fiches de sourate viennent uniquement des sources listées dans le brief, recopiés à l'identique, avec la source. Si une donnée manque, ne rien afficher.
- L'audio est la priorité : lecture en mode silencieux, en arrière-plan et écran éteint, coupes nettes sans débordement.
- Respecter les maquettes : pas de dégradés, pas de cartes, pas de gamification, SF Symbols uniquement, une seule couleur d'accent.
- Pas d'émojis ni de tirets cadratins dans les textes de l'interface.
- Je développe sur mon Mac et j'installe l'application sur mon iPhone via Xcode.
