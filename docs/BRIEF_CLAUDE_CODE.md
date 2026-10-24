# Brief projet : application iOS d'apprentissage du Coran par shadowing

> À lire en entier avant toute action. Les documents de référence sont dans `docs/` :
>
> | Fichier | Rôle |
> |---|---|
> | `docs/design/png/*.png` | **Référence visuelle validée** : les 5 écrans à reproduire (iPhone, 393 × 852 pt, exportés en 2×). |
> | `docs/design/html/*/*.dc.html` | Les mêmes maquettes en HTML : les valeurs exactes (couleurs, tailles, espacements, opacités, arrondis) sont dans les attributs `style`. Lire le `README.md` de chaque dossier. Ce n'est pas du code à copier. |
> | `docs/BRIEF_DESIGN.md` | Le brief qui a produit ces maquettes : intentions, règles visuelles, liste des interdits (section 5) et contenu sourcé. |
> | `docs/prototype/index.html` | Prototype web fonctionnel (avec `kursi.mp3`) : **référence de comportement** pour la sélection, les répétitions et les pauses. Son apparence est dépassée, suivre les maquettes. |
>
> En cas de contradiction : les maquettes priment pour l'apparence, ce brief prime pour le fonctionnement.

## Comment travailler avec moi

- Je suis le premier et, pour l'instant, le seul utilisateur. L'application doit d'abord me satisfaire moi.
- **Ne commence pas à coder tout de suite.** Lis ce brief, regarde les maquettes et le prototype, puis propose-moi un plan : architecture, arborescence du projet, modèle de données, étapes de développement. Attends ma validation avant d'écrire du code.
- Quand une décision n'est pas couverte ici, pose-moi la question plutôt que de supposer.
- Le code est 100 % Swift. Le projet sera versionné sur un dépôt GitHub que je crée moi-même.
- Pas d'émojis ni de tirets cadratins dans les textes de l'interface.

## 1. Contexte : d'où vient ce projet

J'ai voulu apprendre Ayat al-Kursî (sourate 2, verset 255) par shadowing : écouter un morceau, le répéter à voix haute, puis ajouter le morceau suivant quand le précédent est acquis. À partir de l'audio d'un site (récitation de Saad Al-Ghamidi, 55 secondes), nous avons construit un prototype web en plusieurs itérations :

1. **Découpage** : l'audio a été découpé en 9 morceaux (Basmala + 8 phrases) en détectant les silences du récitant, puis chaque morceau a été vérifié par transcription automatique pour s'assurer qu'il contient exactement la bonne phrase.
2. **Constat important** : ces 8 coupes tombent exactement sur les signes de pause (waqf) du texte arabe ottoman (ۚ ۖ ۗ). Ce sont les points de découpe naturels des versets longs.
3. **Version 1** : mode progressif (1, puis 1+2, puis 1+2+3...). Problèmes remontés : on ne voyait pas clairement ce qui était en lecture ni ce qui allait être répété, la pause de 2 s n'était pas réglable, et on entendait le début du morceau suivant à la fin d'un morceau.
4. **Version 2 (le prototype joint)** : sélection d'une plage continue de morceaux, cadre visible autour de la sélection, panneau « En lecture » avec frise des morceaux, pastilles de répétition et compte à rebours de la pause, pause réglable, coupes resserrées sur la voix avec fondus.
5. **Problème découvert sur iPhone** : aucun son sur le haut-parleur quand le mode silencieux est activé (le moteur Web Audio est traité comme un son d'ambiance par iOS). Avec des écouteurs, ça marchait. En natif, ce problème disparaît avec la bonne catégorie de session audio (voir section 5).

L'objectif est maintenant de faire la même chose pour tout le Coran, dans une vraie application iOS, en commençant par un périmètre réduit.

## 2. Objectif de l'application

Écouter les versets à mon rythme pour les **répéter** (shadowing) et **comprendre ce qui est dit** grâce à la traduction. C'est un outil d'apprentissage et de mémorisation. Ce n'est **pas** un outil d'exégèse : pas d'explications détaillées de chaque verset ou de chaque mot.

## 3. Périmètre de la version 1

- **Récitateur** : Ali Al-Hudhaify (un seul récitateur).
- **Contenu** : sourates 100 à 114, plus Ayat al-Kursî (2:255) comme entrée à part.
- **Usage** : personnel, installé uniquement sur mon iPhone, pas de publication sur l'App Store.
- **Hors ligne** : tout le contenu de la version 1 doit fonctionner sans connexion.

### Explicitement hors de la version 1

Ne pas développer, même partiellement : révision espacée, indices progressifs (premières lettres), chaînage à l'envers, alertes sur les versets qui se ressemblent, traduction mot à mot, surlignage mot par mot en temps réel, enregistrement de sa propre voix, suivi détaillé de progression, comptes utilisateur, synchronisation cloud.

## 4. Hiérarchie du contenu et logique de sélection

**Livre → Sourate → Verset → Morceau.** On pratique toujours des morceaux.

- Un verset court = un seul morceau.
- Un verset long = plusieurs morceaux, découpés aux signes de pause du récitant (en pratique, les signes waqf du texte ottoman, à confirmer à l'écoute de chaque récitateur).
- La Basmala est le morceau 0 de chaque sourate (sauf la sourate 9). Pour Ayat al-Kursî, garder la Basmala en morceau 0 comme dans le prototype.
- **La sélection est toujours une plage continue de morceaux**, lue enchaînée, dans l'ordre, puis répétée. Elle peut traverser la frontière entre deux versets.
- Interaction (identique au prototype) : toucher un morceau le sélectionne seul ; toucher un autre morceau étend la sélection jusqu'à lui ; toucher un morceau quand plusieurs sont sélectionnés repart sur ce seul morceau. Boutons **+** et **−** pour ajouter ou retirer un morceau en fin de sélection (méthode progressive). Bouton « Toute la sourate ».

Les sourates et les versets servent à naviguer, les morceaux servent à pratiquer. La même interface doit fonctionner pour une sourate de 3 versets comme pour un verset long découpé en 8 morceaux.

## 5. Exigences audio (la priorité absolue)

1. **Mode silencieux** : le son doit sortir sur le haut-parleur même quand l'iPhone est en mode silencieux. Utiliser `AVAudioSession` avec la catégorie `.playback`.
2. **Écoute en arrière-plan, en boucle** : la lecture et les répétitions doivent continuer quand je passe sur une autre application ou que l'écran est éteint. Activer le mode d'arrière-plan `audio` (`UIBackgroundModes`).
   - Attention : en arrière-plan, les minuteurs ne sont pas fiables. **Les pauses entre répétitions doivent être de vrais silences audio planifiés dans le flux de lecture**, pas des minuteurs. Sinon l'application peut être suspendue pendant la pause et la boucle s'arrête.
   - Piste recommandée : `AVAudioEngine` + `AVAudioPlayerNode`, en planifiant des segments de fichiers à l'échantillon près (`scheduleSegment`) et des buffers de silence pour les pauses, avec `AVAudioUnitTimePitch` pour la vitesse. Propose une autre approche si tu as de meilleures raisons.
3. **Coupes nettes** : aucun débordement sur le morceau suivant. Chaque morceau s'arrête juste après la fin de la voix, avec un fondu de sortie d'environ 30 ms et un fondu d'entrée d'environ 10 ms.
4. **Enchaînement fluide** quand la sélection traverse plusieurs versets (et donc plusieurs fichiers audio) : pas de trou ni de clic, garder une respiration naturelle d'environ 0,3 s entre deux morceaux.
5. **Vitesse** : 0,75×, 0,9×, 1× **sans changer la hauteur de la voix**.
6. **Écran de verrouillage et Centre de contrôle** : `MPNowPlayingInfoCenter` (titre du type « Ayat al-Kursî · Morceaux 2 → 4 », récitateur) et `MPRemoteCommandCenter` (lecture, pause).
7. **Interruptions** : gérer les appels, les autres applications audio, et mettre en pause quand les écouteurs sont débranchés.

## 6. Interface (suivre les maquettes)

Les maquettes de `docs/design/` sont la référence visuelle validée. Direction : **« la feuille de récitation »**. L'écran de pratique se lit comme une page de mushaf ou les paroles synchronisées d'Apple Music, sans cartes, le texte au premier plan, les contrôles regroupés en bas. Respecter la liste des interdits de `docs/BRIEF_DESIGN.md` (section 5) : pas de dégradés, pas de cartes, pas de gamification, pas de clichés d'applications islamiques, etc.

**Système visuel (valeurs relevées dans les maquettes)**

| Élément | Clair | Sombre |
|---|---|---|
| Fond | `#FFFFFF` | `#000000` |
| Texte principal | `#000000` | `#FFFFFF` |
| Texte secondaire | `#6E6E73` | `#98989F` |
| Filets séparateurs | `#EBEBF0` | `#262628` |
| Accent (encre rouge des manuscrits) | `#A3352B` | `#E2897D` |
| Piste sous l'accent | accent à 16 % | équivalent sombre |
| Doré du « À toi » | | `#D4B06A` (et à 20 % pour la piste) |
| Fonds neutres des boutons | `rgba(120,120,128,0.12)` | `rgba(120,120,128,0.24)` |

- En mode sombre, l'icône du bouton lecture / pause est **noire** sur l'accent éclairci (le blanc manquait de contraste).
- Utiliser les couleurs système d'iOS quand elles correspondent (`systemBackground`, `secondaryLabel`, `separator`...) et définir l'accent et le doré comme couleurs de l'Asset Catalog avec variantes claire et sombre.
- Typographie :
  - phonétique : **New York** 17 pt, interligne 24 ;
  - arabe : **KFGQPC Uthmanic Script Hafs** (à embarquer, Amiri Quran en secours) **26 pt**, interligne 44, aligné à droite ;
  - traduction : New York 15 pt, interligne 20, couleur secondaire ;
  - interface : SF Pro 13, 15 et 17 pt ; numéros et durées en chiffres tabulaires.
- Icônes : SF Symbols uniquement, monochromes. Cibles tactiles de 44 pt minimum.
- Matériaux translucides : utiliser ceux du système iOS 26 (Liquid Glass) pour la barre de navigation, le lecteur et les feuilles, plutôt que de reproduire les flous CSS des maquettes.

**Écran de pratique** (maquettes 02 et 03)
- Barre de navigation : retour « Sourates », titre + sous-titre (« Al-Baqara · 255 »), bouton `info.circle` pour la fiche de sourate (désactivé quand il n'y a pas de fiche, par exemple pour un verset seul).
- Sous la barre, quatre bascules texte : Phonétique, Arabe, Français, Mémoire.
- Morceaux en colonne, **sans cartes**, séparés par un filet fin. Numéro du morceau en petit dans la marge gauche.
- **Trois niveaux d'encre** :
  - hors sélection : opacité 35 %, **phonétique seule** ;
  - dans la sélection, pas en lecture : opacité 60 %, avec les textes activés ;
  - en lecture : pleine encre, **numéro en accent semi-gras**, et **barre de progression de 2 pt en accent sous le morceau**, qui avance en temps réel. Pas de surlignage mot par mot.
- **Repère de reprise** pour montrer la sélection (remplace le cadre bleu du prototype) : un trait vertical de 1,5 pt en accent dans la marge gauche, qui court sur toute la sélection, avec « ×3 » (le nombre de répétitions, ou « ∞ ») en 13 pt semi-gras accent au-dessus.
- Marqueur de fin de verset du mushaf (﴿٢٥٥﴾) après le dernier morceau de chaque verset.
- Défilement automatique vers le morceau en lecture.
- **Lecteur flottant en bas** (panneau translucide aux coins arrondis, marges de 8 pt) :
  - ligne 1 : « Morceaux 2 → 4 » en semi-gras, temps « 0:09 / 0:16 » à droite ;
  - ligne 2 : **la frise**, un segment par morceau sélectionné, de largeur proportionnelle à sa durée, 4 pt de haut, 3 pt d'écart, numéro sous chaque segment (le segment en cours se remplit en accent, son numéro passe en accent) ;
  - ligne 3 : « Répétition 2 sur 3 », ou pendant la pause **« À toi · 0,6 s » en doré** avec une fine barre de compte à rebours dorée qui se vide en continu, la frise étant alors estompée ;
  - ligne 4 : réglages et **−** à gauche, bouton lecture / pause rond de 64 pt en accent au centre, **+** et arrêt à droite.
- Le bouton « Toute la sourate » du prototype n'apparaît pas dans les maquettes : propose-moi un emplacement discret.
- **Réglages** (maquette 04, feuille native à mi-hauteur) :
  - répétitions : 1, 2, 3, 5, infini ;
  - temps pour répéter : de 0 à 5 s par pas de 0,5 s, **1 s par défaut**, plus une option **Écho** (silence égal à la durée du passage) ;
  - vitesse : 0,75×, 0,9×, 1×.
- **Affichage des textes** : trois bascules indépendantes, Phonétique, Arabe, Français.
- **Mode mémoire** : floute les morceaux déjà acquis de la sélection (tous sauf le dernier), un bouton « Voir » sur chacun pour vérifier.
- Mémoriser localement la dernière sélection et les réglages pour chaque sourate.

**Accueil** (maquette 01)
- Grand titre natif « Sourates », pas de barre d'onglets.
- « Récemment » : le bandeau d'historique (section 8), en entrées texte sur deux lignes, sans cartes.
- Liste groupée native : section « Versets » (Ayat al-Kursî), puis section « Juz ‘Amma » (sourates 100 à 114). Chaque ligne : numéro en gris, nom en phonétique, nombre de versets en gris, nom arabe aligné à droite.

**Fiche de sourate** (maquette 05) : feuille native avec le nom, le nom arabe, le nombre de versets, le paragraphe « Parmi les objectifs de la sourate » recopié tel quel, et la source en petit en bas. Bouton « OK » pour fermer.

**Thèmes** : clair et sombre, le sombre étant conçu et non simplement inversé (voir le tableau ci-dessus et la maquette 03).

## 7. Contenu et sources

Règle absolue : **aucun contenu religieux ne doit être généré par une IA.** Texte arabe, phonétique, traduction et fiches de sourate viennent uniquement de sources établies, recopiées à l'identique, avec la source affichée. Si une donnée n'existe pas dans une source fiable, on ne l'affiche pas.

| Donnée | Source proposée | Remarques |
|---|---|---|
| Audio Al-Hudhaify | everyayah.com, un fichier par verset : `https://everyayah.com/data/Hudhaify_128kbps/SSSAAA.mp3` (ex. `002255.mp3`, `114001.mp3`, vérifiés) | Vérifier comment la Basmala est fournie (habituellement via `001001.mp3`). |
| Texte arabe ottoman avec signes de pause | QuranEnc (champ `arabic_text`) ou Tanzil / QUL (qul.tarteel.ai) | Doit contenir les signes waqf, utilisés pour la découpe. |
| Traduction française | QuranEnc, `french_hameedullah` : `https://quranenc.com/api/v1/translation/sura/french_hameedullah/{sourate}` (vérifié) | Autres options françaises sur QuranEnc : `french_rashid`, `french_montada`. Je choisirai, Hamidullah par défaut. |
| Phonétique | QUL ou Tanzil (translittérations existantes) | Ne pas en générer. Me proposer les options disponibles. |
| Fiche de sourate | « Objectifs de la sourate » d'Al-Mukhtasar fi Tafsir al-Quran (Markaz Tafsir), version française sur QuranEnc (`french_mokhtasar`) | Recopier à l'identique avec la mention de la source. Si l'objectif n'est pas disponible pour une sourate, ne rien afficher. |

Les timings par mot de QUL ne couvrent pas Al-Hudhaify (vérifié). Les frontières de versets sont données gratuitement par les fichiers verset par verset. Seuls les versets longs demandent un découpage interne.

**Découpage des versets longs** (en version 1, seulement Ayat al-Kursî) : écrire un script dans un dossier `tools/` (Python accepté pour cet outil hors application) qui :
1. détecte les silences du récitant (par exemple `ffmpeg silencedetect`, seuil autour de -25 dB, durée minimale 0,25 s) ;
2. place les coupes dans les silences correspondant aux signes waqf ;
3. resserre le début et la fin de chaque morceau sur la voix (profil de volume par tranches de 10 ms) ;
4. vérifie chaque morceau par transcription automatique (par exemple faster-whisper, modèle `small`, langue arabe), pour confirmer que le texte entendu correspond au texte attendu et ne déborde pas ;
5. exporte un fichier JSON de données embarqué dans l'application.

Ce travail a déjà été fait pour la récitation d'Al-Ghamidi dans le prototype (timings dans le bloc `LESSON` du fichier HTML). Le cas difficile : entre « ḥifẓuhumā » et « wa huwa al-‘aliyyu », il n'y a pas de vraie pause, la coupe doit être faite avec soin.

**Phonétique et morceaux** : quand un verset est découpé en plusieurs morceaux, la phonétique et la traduction doivent être réparties sur les morceaux. Pour l'arabe et la phonétique, la découpe suit les mots. Pour la traduction, qui ne se découpe pas mot à mot, me proposer une solution (par exemple afficher la traduction complète du verset sur le premier morceau, ou au niveau du verset).

Tout le contenu de la version 1 (audio, textes, découpage) est préparé par les scripts de `tools/` et **embarqué dans l'application**, pour un fonctionnement entièrement hors ligne.

**Droits** : usage strictement personnel pour l'instant. Si l'application devait un jour être publiée, il faudrait vérifier les conditions d'utilisation des enregistrements et des traductions.

## 8. Historique d'écoute (bandeau)

Un bandeau simple en haut de l'écran d'accueil, défilant horizontalement, qui montre **ce qui a été écouté récemment**, sans suivi détaillé de progression :
- « Al-Ikhlâs · Morceaux 0 → 2 · il y a 6 h »
- « Ayat al-Kursî · Morceau 4 · il y a 3 j »
- Un appui ouvre la sourate avec cette sélection.
- Une écoute est enregistrée quand une sélection a été lue en entier au moins une fois.
- Stockage local (SwiftData ou équivalent).

Je fournirai une capture d'un exemple de bandeau qui me plaît. Attends-la avant de finaliser le design de ce bandeau.

## 9. Contraintes techniques

- 100 % Swift, SwiftUI, aucune dépendance tierce sauf nécessité justifiée.
- Cible : iPhone, version d'iOS récente (propose une version minimale et justifie-la).
- Architecture claire, séparant le moteur audio, les données et l'interface, pour pouvoir ensuite ajouter d'autres récitateurs et d'autres sourates sans tout refaire.
- Tests unitaires sur la logique pure : sélection de plage, calcul des timings, planification des répétitions et des pauses.
- **Environnement** : je développe sur mon Mac.
- **Installation sur mon iPhone** : explique-moi les étapes avec Xcode. À noter : avec un identifiant Apple gratuit, l'application installée expire au bout de 7 jours et doit être réinstallée depuis Xcode ; avec l'Apple Developer Program (payant), elle reste valide un an.

## 10. Plus tard (ne pas développer maintenant)

Nom de l'application et logo (à définir ensemble), autres récitateurs, autres sourates puis le livre entier, éventuellement l'enregistrement de sa propre voix.

## Ce que j'attends de ta première réponse

1. Tes questions éventuelles sur ce brief.
2. Un plan : architecture, arborescence du projet, modèle de données, approche du moteur audio, étapes de développement dans l'ordre.
3. Les choix qu'il me reste à faire (traduction, phonétique, version d'iOS minimale).

Puis attends ma validation avant d'écrire du code.
