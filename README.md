# Talaqqi (nom provisoire)

Application iOS personnelle, 100 % Swift et SwiftUI, pour mémoriser le Coran par shadowing : écouter un récitant morceau par morceau, répéter à voix haute dans le silence qui suit, puis ajouter le morceau suivant.

Version 1 : récitation d'Ali Al-Hudhaify, sourates 100 à 114 et Ayat al-Kursî (2:255), entièrement hors ligne.

## Structure

| Dossier | Contenu |
|---|---|
| `CLAUDE.md` | Règles permanentes du projet |
| `docs/PLAN.md` | Plan validé : architecture, modèle de données, moteur audio, étapes |
| `docs/BRIEF_CLAUDE_CODE.md` | Brief complet du projet |
| `docs/BRIEF_DESIGN.md` | Intentions de design et interdits |
| `docs/design/png/` | Les 5 maquettes validées (393 × 852 pt, exportées en 2×) |
| `docs/design/html/` | Les mêmes maquettes en HTML, pour les valeurs exactes (le runtime React d'affichage n'est pas inclus) |
| `docs/prototype/` | Prototype web, référence de comportement (`index.html` + `kursi.mp3`) |

À venir : `Talaqqi/` (application), `Packages/ShadowingCore/` (logique pure et tests), `tools/` (préparation du contenu).

## Installation sur l'iPhone

1. Xcode, Réglages, Comptes : ajouter son identifiant Apple.
2. Cible Talaqqi, Signing & Capabilities : choisir son équipe, laisser « Automatically manage signing ».
3. Sur l'iPhone : Réglages, Confidentialité et sécurité, Mode développeur, activer (l'iPhone redémarre).
4. Brancher l'iPhone, le choisir comme destination en haut de la fenêtre Xcode, puis Run (⌘R).
5. Au premier lancement : Réglages, Général, VPN et gestion de l'appareil, faire confiance au certificat de développeur.

Avec un identifiant Apple gratuit, l'application expire au bout de 7 jours et doit être relancée depuis Xcode. Avec l'Apple Developer Program, elle reste valide un an.

## Sources

Aucun contenu religieux n'est généré. Texte arabe, phonétique, traduction et fiches de sourate viennent de sources établies, recopiés à l'identique, avec la source. Le détail sera documenté dans `tools/README.md`.
