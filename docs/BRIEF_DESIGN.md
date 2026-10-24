# Brief de design : application iOS de shadowing coranique

Ce fichier contient trois parties :
- **Partie A** : le brief complet, à donner tel quel à Claude Design.
- **Partie B** : le même brief découpé en courts prompts successifs pour Google Stitch, qui perd des éléments au-delà d'environ 5 000 caractères.
- **Partie C** : une grille pour comparer les deux résultats.

---

# PARTIE A : brief complet (Claude Design)

## 1. Le produit en une phrase

Une application iPhone personnelle pour mémoriser le Coran par shadowing : on écoute un récitant morceau par morceau, on répète à voix haute dans le silence qui suit, et on ajoute le morceau suivant quand le précédent est acquis. La traduction française est là pour comprendre ce que l'on récite.

Un seul utilisateur pour l'instant : moi. Usage quotidien, souvent avec des écouteurs, parfois écran éteint, parfois en lisant le texte en même temps.

## 2. Ce que j'attends de toi

Des maquettes haute fidélité de **5 écrans iPhone** (format iPhone 16, 393 × 852 pt), avec le vrai contenu fourni en section 7. Rien d'autre : pas de page d'accueil marketing, pas d'onboarding, pas d'écran de connexion, pas de profil.

L'application sera développée ensuite en **SwiftUI natif**. Tout ce que tu dessines doit pouvoir être construit avec les composants iOS standards, plus deux éléments sur mesure au maximum (le repère de sélection et la frise de lecture, décrits plus bas).

## 3. Direction : « la feuille de récitation »

L'écran de pratique doit se lire comme une page de texte, pas comme un tableau de bord. Pense aux **paroles synchronisées d'Apple Music** (la ligne en cours en pleine encre, les autres estompées), à la sobriété d'**Apple Books**, et à la mise en page d'un **mushaf imprimé** : de larges marges, le texte au centre de tout, les marqueurs de fin de verset (﴿١﴾, ﴿٢﴾...) comme seuls ornements.

L'interface s'efface derrière le texte. Les contrôles sont discrets, regroupés en bas, à portée de pouce.

**Une seule audace, la couleur d'accent : l'encre rouge des manuscrits.** Dans les corans manuscrits, l'encre rouge servait aux voyelles et aux marqueurs de versets. On la reprend avec parcimonie pour ce qui est vivant : le morceau en lecture, sa barre de progression, le bouton lecture, le repère de sélection.
- Mode clair : rouge garance sombre, environ `#A3352B`.
- Mode sombre : la même teinte éclaircie pour rester lisible, environ `#E2897D`.
- Tout le reste est neutre : fond système (blanc pur en clair, noir pur en sombre), texte en encre noire ou blanche, gris système pour le secondaire.
- Pas d'autre couleur, sauf le doré du compte à rebours « À toi » (voir écran 3), discret.

## 4. Règles visuelles

**Typographie** (trois rôles, pas plus)
- Interface : **SF Pro**, la police système d'iOS.
- Phonétique et traduction : **New York**, la serif système d'Apple, pour que le texte lu se distingue des contrôles.
- Arabe : une police coranique en naskh ottoman, **KFGQPC Uthmanic Script Hafs** ou à défaut **Amiri Quran**, nettement plus grande que le reste (environ 28 pt), alignée à droite.
- Deux ou trois tailles par écran maximum, la hiérarchie se fait par le poids et la couleur.

**Icônes**
- **SF Symbols uniquement**, monochromes, un seul poids (regular), taille système.
- Seulement là où une icône est plus claire qu'un mot : lecture (`play.fill`), pause (`pause.fill`), arrêt (`stop.fill`), ajouter (`plus`), retirer (`minus`), réglages (`slider.horizontal.3`), à propos de la sourate (`info.circle`).
- Jamais d'icône dans un carré ou un cercle coloré, jamais d'émoji.

**Formes et surfaces**
- **Aucune carte sur l'écran de pratique.** Les morceaux sont des blocs de texte séparés par de l'espace et un filet fin, comme des paragraphes.
- Arrondis : ceux du système uniquement (listes groupées, feuilles, boutons). Pas de grand arrondi uniforme sur tout.
- Pas d'ombre décorative, pas de flou décoratif. Les matériaux translucides d'iOS 26 (Liquid Glass) seulement là où le système les met lui-même : barre de navigation, barre d'outils du bas, feuilles.
- Espacements sur une grille de 8 pt. Les éléments liés sont serrés, les groupes différents nettement séparés.

**Mouvement** (à décrire en note, pas à animer)
- La barre de progression avance sous le morceau en cours. Le défilement suit le morceau en lecture.
- Rien qui pulse, clignote, rebondit ou brille.

## 5. Interdits absolus

Ces éléments trahissent immédiatement une interface générée par IA ou un clone d'application. Aucun ne doit apparaître :

- dégradés de toute sorte, surtout violet vers bleu, texte en dégradé, halos ou lueurs en fond ;
- cartes partout, cartes imbriquées, liseré coloré épais sur le côté d'une carte, ombre + bordure + fond teinté sur le même élément ;
- grilles de cartes identiques (icône, titre, texte) et tuiles de statistiques (« 12 jours », « 87 % ») ;
- gamification : séries, flammes, points, badges, niveaux, anneaux de progression, confettis ;
- en-tête « Salam, Amadou 👋 », avatar en haut à droite, cloche de notifications ;
- pastilles « Nouveau » ou points colorés qui pulsent sans raison ;
- étiquettes en majuscules espacées au-dessus de chaque titre, numérotation décorative 01 / 02 / 03 ;
- **clichés des applications islamiques** : silhouettes de mosquée, croissants de lune, lanternes, motifs géométriques ou arabesques en fond, palette vert et or ;
- polices Inter, Poppins, Plus Jakarta Sans, Geist ; icônes Material, Lucide ou Heroicons ;
- textes marketing (« Transforme ta mémorisation », « Commence ton voyage ») ; les libellés disent simplement ce qui se passe ;
- tirets cadratins dans les textes de l'interface ;
- contenu inventé : n'utilise que les textes de la section 7, ne crée ni traduction, ni phonétique, ni description de sourate.

## 6. Les 5 écrans

### Écran 1 : Accueil (mode clair)
- Grand titre natif iOS : « Sourates ».
- **Historique d'écoute** sous le titre : une rangée qui défile horizontalement, faite de simples entrées texte (pas de cartes illustrées), chacune sur deux lignes : le nom et la sélection, puis le temps écoulé en gris. Contenu en section 7. Un appui reprend cette sélection.
- **Liste des contenus**, liste native groupée : pour chaque ligne, le numéro de sourate en gris, le nom en phonétique, le nombre de versets en gris, et le nom arabe aligné à droite dans la police coranique. Ayat al-Kursî en tête, dans sa propre section « Versets », puis la section « Juz ‘Amma » avec les sourates 100 à 114.
- Pas de barre d'onglets : l'application n'a qu'une seule section.

### Écran 2 : Pratique, en lecture (mode clair)
Ayat al-Kursî, affichage Phonétique + Arabe + Français activés.
- **Barre de navigation** native : retour « Sourates », titre « Ayat al-Kursî » et dessous « Al-Baqara · 255 » en petit, à droite un bouton `info.circle` pour la fiche de sourate (désactivé ici, pas de fiche pour un verset seul).
- **Bascules d'affichage** sous la barre : trois boutons texte compacts « Phonétique », « Arabe », « Français », plus « Mémoire ». Un état actif sobre (texte en encre, fond gris léger), pas de pastilles colorées.
- **Les morceaux 0 à 8** en colonne (voir section 7). Pour chaque morceau : un petit numéro en gris dans la marge, la phonétique en serif, l'arabe aligné à droite, la traduction en gris plus petit. Le marqueur de fin de verset ﴿٢٥٥﴾ apparaît après le dernier morceau du verset.
- **Sélection : morceaux 2 à 4.** Elle est montrée par un **repère de reprise dans la marge gauche**, inspiré des barres de reprise en musique : un trait vertical fin (1,5 pt) couleur d'accent qui court du morceau 2 au morceau 4, avec « ×3 » en tout petit en haut du trait. Les morceaux hors sélection sont estompés (environ 35 % d'opacité) et n'affichent que la phonétique.
- **Le morceau 3 est en lecture** : texte en pleine encre, et une fine barre de progression couleur d'accent sous le morceau, remplie aux deux tiers.
- **Lecteur en bas** (barre d'outils native, à portée de pouce) :
  - ligne 1 : « Morceaux 2 → 4 » à gauche, « 0:09 / 0:16 » à droite en chiffres tabulaires ;
  - ligne 2 : la **frise** : trois segments côte à côte, de largeur proportionnelle à la durée de chaque morceau (5,7 s, 3,9 s, 6,4 s), numérotés 2, 3, 4, le segment 3 partiellement rempli en accent ;
  - ligne 3 : « Répétition 2 sur 3 » à gauche ;
  - ligne 4, les commandes : `slider.horizontal.3` et `minus` à gauche, gros bouton rond lecture / pause au centre (fond accent, icône blanche), `plus` et `stop.fill` à droite.

### Écran 3 : Pratique, « À toi » (mode sombre)
Même écran, en mode sombre, pendant le silence entre deux répétitions, quand c'est à moi de répéter.
- Aucun morceau n'est en lecture, la sélection 2 à 4 reste visible.
- Dans le lecteur, la ligne « Répétition 2 sur 3 » devient **« À toi · 0,6 s »** en doré discret, avec une fine barre de compte à rebours dorée qui se vide.
- La frise est estompée pendant ce temps.

### Écran 4 : Réglages (feuille native à mi-hauteur, sur l'écran 2)
Liste groupée native :
- **Répétitions** : contrôle segmenté 1 · 2 · 3 · 5 · ∞ (3 sélectionné).
- **Temps pour répéter** : stepper, « 1 s », de 0 à 5 s par pas de 0,5 s ; dessous, un interrupteur **Écho** avec l'explication en gris : « Un silence aussi long que le passage. »
- **Vitesse** : contrôle segmenté 0,75× · 0,9× · 1×.

### Écran 5 : À propos de la sourate (feuille native, sur l'écran de pratique d'Al-Ikhlâs)
- En arrière-plan, estompé par la feuille : l'écran de pratique d'Al-Ikhlâs avec les bascules Arabe et Français actives (texte en section 7).
- Dans la feuille : le nom « Al-Ikhlâs », le nom arabe « الإخلاص », « 4 versets », puis le paragraphe « Parmi les objectifs de la sourate » recopié tel quel (section 7), et en bas, en petit et en gris, la source.
- Pas d'illustration, pas d'icône décorative.

## 7. Contenu réel (à utiliser tel quel)

**Historique d'écoute (écran 1)**
- Ayat al-Kursî · Morceaux 2 → 4 · il y a 6 h
- Al-Ikhlâs · Sourate entière · hier
- An-Nâs · Morceau 3 · il y a 3 j

**Liste (écran 1)** : numéro, nom, nombre de versets, nom arabe
- Versets : Ayat al-Kursî · Al-Baqara 255 · آية الكرسي
- Juz ‘Amma :
  - 100 · Al-‘Âdiyât · 11 · العاديات
  - 101 · Al-Qâri‘a · 11 · القارعة
  - 102 · At-Takâthur · 8 · التكاثر
  - 103 · Al-‘Asr · 3 · العصر
  - 104 · Al-Humaza · 9 · الهمزة
  - 105 · Al-Fîl · 5 · الفيل
  - 106 · Quraysh · 4 · قريش
  - 107 · Al-Mâ‘ûn · 7 · الماعون
  - 108 · Al-Kawthar · 3 · الكوثر
  - 109 · Al-Kâfirûn · 6 · الكافرون
  - 110 · An-Nasr · 3 · النصر
  - 111 · Al-Masad · 5 · المسد
  - 112 · Al-Ikhlâs · 4 · الإخلاص
  - 113 · Al-Falaq · 5 · الفلق
  - 114 · An-Nâs · 6 · الناس

**Ayat al-Kursî, découpée en 9 morceaux (écrans 2 à 4)** : numéro, durée, phonétique, arabe, traduction

0. Basmala · 5,0 s · Bismi Allāhi Ar-Raĥmāni Ar-Raĥīm · بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ · Au nom d’Allâh, le Tout Miséricordieux, le Très Miséricordieux.
1. 7,6 s · Allāhu Lā ‘Ilāha ‘Illā Huwa Al-Ĥayyu Al-Qayyūmu · اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ · Allâh ! Point de divinité à part Lui, le Vivant, Celui qui subsiste par lui-même « Al-Qayyoûm ».
2. 5,7 s · Lā Ta’khudhuhu Sinatun Wa Lā Nawm · لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ · Ni somnolence ni sommeil ne Le saisissent.
3. 3,9 s · Lahu Mā Fī As-Samāwāti Wa Mā Fī Al-‘Arđ · لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ · À Lui appartient tout ce qui est dans les cieux et sur la terre.
4. 6,4 s · Man Dhā Al-Ladhī Yashfa`u `Indahu ‘Illā Bi’idhnih · مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ · Qui peut intercéder auprès de Lui sans Sa permission ?
5. 4,6 s · Ya`lamu Mā Bayna ‘Aydīhim Wa Mā Khalfahum · يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ · Il connaît leur passé et leur futur.
6. 8,7 s · Wa Lā Yuĥīţūna Bishay’in Min `Ilmihi ‘Illā Bimā Shā’a · وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ · Et, de Sa science, ils n’embrassent que ce qu’Il veut.
7. 7,2 s · Wasi`a Kursīyuhu As-Samāwāti Wa Al-‘Arđa Wa Lā Ya’ūduhu Ĥifžuhumā · وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ وَلَا يَئُودُهُ حِفْظُهُمَا · Son Trône « Kursî » déborde les cieux et la terre, dont la garde ne Lui coûte aucune peine.
8. 3,4 s · Wa Huwa Al-`Alīyu Al-`Ažīm · وَهُوَ الْعَلِيُّ الْعَظِيمُ · Et Il est le Très Haut, le Très Grand.

Les durées sont indicatives (elles viennent du prototype, récité par Al-Ghamidi). Dans les écrans 2 et 3, la sélection 2 → 4 dure donc 16 s au total.

**Al-Ikhlâs (écran 5, en arrière-plan)** : arabe et traduction de Hamidullah (source : QuranEnc)
1. قُلۡ هُوَ ٱللَّهُ أَحَدٌ · Dis : « Il est Allah, Unique.
2. ٱللَّهُ ٱلصَّمَدُ · Allah, Le Seul à être imploré pour ce que nous désirons.
3. لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ · Il n’a jamais engendré, n’a pas été engendré non plus.
4. وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ · Et nul n’est égal à Lui. »

**Fiche Al-Ikhlâs (écran 5)**
- Titre du paragraphe : Parmi les objectifs de la sourate
- Texte : Elle établit qu’Allah est l’exclusif détenteur de la perfection et de la divinité et exclut pour Sa part toute déficience.
- Source : Al-Mukhtasar fi Tafsir al-Qur’an, Markaz Tafsir · QuranEnc

---

# PARTIE B : prompts pour Google Stitch

Mode d'emploi : crée un projet en mode **App** (mobile). Colle le prompt 1, attends le résultat, puis colle les suivants un par un. Un seul changement par prompt. Fais une capture après chaque étape réussie, Stitch oublie parfois les décisions précédentes.

### Prompt 1 : direction et écran d'accueil

```
iPhone app (iOS 26, native SwiftUI look), French UI. Personal app to memorize the Quran by shadowing: listen to a reciter piece by piece, repeat aloud, add the next piece.

Visual direction: "recitation sheet". Looks like a printed mushaf page or Apple Music synced lyrics, not a dashboard. Pure white background, black ink text, system gray for secondary text. ONE accent color only, used sparingly: dark madder red #A3352B (the red ink of Quran manuscripts).
Fonts: SF Pro for UI, New York serif for reading text, a Quranic naskh font (Amiri Quran) for Arabic, right-aligned, large.
Icons: SF Symbols style only, thin, monochrome, single weight. Never inside colored circles or tiles. No emoji.

STRICTLY AVOID: gradients, glows, cards, nested cards, colored side borders, drop shadows, stat tiles, streaks, badges, progress rings, greeting header, avatar, notification bell, tab bar, mosque or crescent illustrations, geometric/arabesque patterns, green and gold palette, Inter/Poppins fonts, Material icons, marketing copy, uppercase spaced labels.

Screen: Home.
- Native iOS large title "Sourates".
- Under it, a horizontally scrolling row of plain text entries (no cards, no images), two lines each:
  "Ayat al-Kursî · Morceaux 2 → 4" / "il y a 6 h"
  "Al-Ikhlâs · Sourate entière" / "hier"
  "An-Nâs · Morceau 3" / "il y a 3 j"
- Native inset grouped list. Section "Versets": "Ayat al-Kursî", subtitle "Al-Baqara 255", Arabic name right "آية الكرسي".
- Section "Juz ‘Amma", one row per surah: gray number, name, gray verse count, Arabic name right-aligned:
100 Al-‘Âdiyât 11 العاديات / 101 Al-Qâri‘a 11 القارعة / 102 At-Takâthur 8 التكاثر / 103 Al-‘Asr 3 العصر / 104 Al-Humaza 9 الهمزة / 105 Al-Fîl 5 الفيل / 106 Quraysh 4 قريش / 107 Al-Mâ‘ûn 7 الماعون / 108 Al-Kawthar 3 الكوثر / 109 Al-Kâfirûn 6 الكافرون / 110 An-Nasr 3 النصر / 111 Al-Masad 5 المسد / 112 Al-Ikhlâs 4 الإخلاص / 113 Al-Falaq 5 الفلق / 114 An-Nâs 6 الناس
```

### Prompt 2 : écran de pratique

```
New screen: Practice, same style. Native nav bar: back "Sourates", title "Ayat al-Kursî", small subtitle "Al-Baqara · 255", right an info.circle icon.
Below: four compact text toggles "Phonétique" "Arabe" "Français" "Mémoire" (first three active: ink text on light gray, no colors).

Then pieces in one column, NO cards, separated by space and a hairline. Each piece: small gray number in the left margin, transliteration in serif, Arabic right-aligned large, French in smaller gray.
0 Bismi Allāhi Ar-Raĥmāni Ar-Raĥīm
1 Allāhu Lā ‘Ilāha ‘Illā Huwa Al-Ĥayyu Al-Qayyūmu
2 Lā Ta’khudhuhu Sinatun Wa Lā Nawm / لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ / Ni somnolence ni sommeil ne Le saisissent.
3 Lahu Mā Fī As-Samāwāti Wa Mā Fī Al-‘Arđ / لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ / À Lui appartient tout ce qui est dans les cieux et sur la terre.
4 Man Dhā Al-Ladhī Yashfa`u `Indahu ‘Illā Bi’idhnih / مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ / Qui peut intercéder auprès de Lui sans Sa permission ?
5 Ya`lamu Mā Bayna ‘Aydīhim Wa Mā Khalfahum

Selection = pieces 2 to 4: shown by a thin 1.5pt vertical line in the accent color in the LEFT MARGIN spanning pieces 2 to 4, like a musical repeat bar, with a tiny "×3" at its top. Pieces outside the selection are faded to 35% and show transliteration only.
Piece 3 is playing: full ink, thin accent progress line under it, two-thirds filled.

Bottom player in a native toolbar:
row 1: "Morceaux 2 → 4" left, "0:09 / 0:16" right (tabular digits)
row 2: a timeline of 3 adjacent segments, widths proportional to 5.7s, 3.9s, 6.4s, labeled 2, 3, 4; segment 3 partly filled in accent
row 3: "Répétition 2 sur 3"
row 4: left slider.horizontal.3 and minus icons, center a large round play/pause button (accent fill, white icon), right plus and stop icons.
```

### Prompt 3 : état « À toi » en mode sombre

```
Duplicate the Practice screen in dark mode: pure black background, white ink, accent lightened to #E2897D. State: silence between two repetitions, the user repeats aloud. No piece is playing (no progress line), selection 2 to 4 still visible. In the player, replace "Répétition 2 sur 3" with "À toi · 0,6 s" in a subtle muted gold, with a thin gold countdown bar under it, half empty. The timeline is faded. Nothing else changes.
```

### Prompt 4 : réglages

```
New screen: native iOS half-height sheet "Réglages" over the light Practice screen. Inset grouped list:
- "Répétitions": segmented control 1 · 2 · 3 · 5 · ∞ (3 selected)
- "Temps pour répéter": native stepper showing "1 s"; below, a native switch "Écho" with gray footnote "Un silence aussi long que le passage."
- "Vitesse": segmented control 0,75× · 0,9× · 1× (1× selected)
Native controls only, accent color only on selected states.
```

### Prompt 5 : fiche de sourate

```
New screen: native iOS sheet over a faded Practice screen for Al-Ikhlâs (background shows Arabic + French only:
قُلۡ هُوَ ٱللَّهُ أَحَدٌ · Dis : « Il est Allah, Unique.
ٱللَّهُ ٱلصَّمَدُ · Allah, Le Seul à être imploré pour ce que nous désirons.)
Sheet content: title "Al-Ikhlâs", Arabic "الإخلاص" right, gray "4 versets". Then a short heading "Parmi les objectifs de la sourate" and this exact paragraph in New York serif: "Elle établit qu’Allah est l’exclusif détenteur de la perfection et de la divinité et exclut pour Sa part toute déficience." At the bottom, small gray: "Source : Al-Mukhtasar fi Tafsir al-Qur’an, Markaz Tafsir · QuranEnc". No illustration, no icon.
```

---

# PARTIE C : grille de comparaison

Pour chaque outil, coche ce qui est vrai. Le meilleur résultat est celui qui a le plus de « oui » à gauche et le moins à droite.

| Ce qu'on veut | Oui ? | Ce qui trahit l'IA | Présent ? |
|---|---|---|---|
| On dirait une app Apple, pas un site web | | Dégradé, lueur, halo | |
| Le texte est le héros de l'écran de pratique | | Cartes, ou cartes dans des cartes | |
| On voit d'un coup d'œil ce qui sera répété | | Icônes dans des cercles colorés, émojis | |
| On voit d'un coup d'œil ce qui est en lecture | | Tuiles de stats, séries, badges | |
| Une seule couleur d'accent, utilisée avec retenue | | Mosquée, croissant, motifs, vert et or | |
| L'arabe est beau et bien lisible | | Même grand arrondi partout | |
| Les commandes sont à portée de pouce | | Texte inventé ou modifié | |
| Le mode sombre est soigné, pas juste inversé | | Libellés marketing ou en majuscules espacées | |

Le test final : montre l'écran 2 à quelqu'un sans rien dire. S'il pense que c'est une app d'Apple ou d'un petit studio soigneux, c'est gagné.
