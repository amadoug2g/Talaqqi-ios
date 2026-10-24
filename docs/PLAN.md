# Plan : application iOS de shadowing coranique (version 1)

## Contexte

Le dépôt `amadoug2g/Talaqqi-ios` est vide. Amadou a fourni le brief projet, le brief design, les 5 maquettes validées (PNG + HTML) et le prototype web (`index.html` + `kursi.mp3`, récitation d'Al-Ghamidi). Objectif de la version 1 : une application iPhone personnelle, 100 % Swift / SwiftUI, hors ligne, pour mémoriser par shadowing les sourates 100 à 114 et Ayat al-Kursî avec la récitation d'Ali Al-Hudhaify. L'audio est la priorité absolue (mode silencieux, arrière-plan, écran éteint, coupes nettes). Aucun contenu religieux n'est généré : tout vient de sources établies, recopié à l'identique, avec la source.

Ce plan répond aux trois attentes du brief : questions, plan (architecture, arborescence, modèle de données, moteur audio, étapes), choix restants. Aucun code n'est écrit avant validation.

## Décisions prises avec Amadou

| Sujet | Décision |
|---|---|
| iOS minimum | **iOS 26** (Liquid Glass natif ; iPhone 11 ou plus récent, Xcode 26 ou plus) |
| Phonétique | **QUL « English Transliteration (Tajweed) »** (ressource 469), choisie après vérification : le style exact des maquettes n'est disponible depuis aucune source vérifiée accessible. Ses arrêts tombent sur les signes de pause de l'arabe, ce qui rend la découpe mécanique |
| Traduction | **Hamidullah** (`french_hameedullah`) ; pour 2:255, **coupée aux phrases**, sans changer un mot, validée par Amadou ; repli « traduction au niveau du verset » si un futur verset ne se coupe pas proprement |
| Appels de note | Les renvois `[n]` de la traduction QuranEnc sont retirés, sans la note ; aucun autre changement |
| « Toute la sourate » | **Menu natif sur le titre « Morceaux 2 → 4 » du lecteur** |
| Réseau | Amadou **autorise les domaines** des sources dans l'environnement ; les scripts de `tools/` tournent ici et le résultat est committé |
| Projet Xcode | **Amadou le crée dans Xcode** selon mes réglages (dossiers synchronisés), puis je n'ajoute que des fichiers |
| Encre pendant « À toi » | **100 %** pour toute la sélection (comme la maquette 3), sauf ce que masque le mode mémoire |
| Bandeau « Récemment » | **La maquette 1 suffit**, reproduite telle quelle |
| Ordre du contenu | **Ayat al-Kursî d'abord**, puis les sourates **une par une à partir de 114** (113, 112… 100), chacune validée avant la suivante |
| Accueil | Seuls les contenus prêts apparaissent ; les sourates pas encore faites ne sont pas affichées |
| Marqueur de fin de verset | En ligne à la fin de l'arabe quand il est affiché, sinon seul sur sa ligne (déduit des maquettes 2 et 5) |

---

## 1. Constats après lecture des maquettes HTML

Valeurs détaillées : voir l'annexe A. Points qui comptent pour l'implémentation :

1. **Tout est natif ou presque.** Accueil = `List` `.insetGrouped`, Réglages = `Form` dans une feuille à mi-hauteur, Fiche = feuille avec bouton OK. Seuls trois éléments sont sur mesure : la colonne de morceaux (avec le repère de reprise), la frise et le lecteur flottant.
2. **Niveaux d'encre** : hors sélection, toute la ligne est à 35 % ; dans la sélection, seule la colonne de texte est à 60 % (le numéro reste gris normal) ; en lecture, 100 % et numéro accent semi-gras.
3. **Pendant « À toi »** (maquette 3), les trois morceaux de la sélection sont à **100 %**, et non à 60 %. Retenu.
4. **Piste de la frise** : gris neutre (12 % / 20 % clair, 36 % sombre), pas l'accent à 16 %. L'accent à 16 % sert seulement à la barre sous le morceau.
5. **Marqueur de fin de verset** : sur Al-Ikhlâs, il est en ligne à la fin du texte arabe (﴿١﴾). Sur Ayat al-Kursî, le morceau 8 est hors sélection, donc sans arabe, et le marqueur ﴿٢٥٥﴾ apparaît seul sur une ligne sous la phonétique. Règle proposée, cohérente avec les deux maquettes : **en ligne à la fin de l'arabe quand l'arabe est affiché, sinon seul sur sa ligne**.
6. **Fiche Al-Ikhlâs** : le sous-titre de la barre est « Sourate 112 » ; le bouton `info.circle` est actif (noir).
7. **Texte arabe des maquettes Kursî** : il vient du prototype et n'est pas en graphie ottomane. Dans l'application, il sera remplacé par le texte de la source retenue, qui sera visuellement un peu différent (par exemple ٱللَّهُ au lieu de اللَّهُ).

---

## 2. Architecture

Trois couches séparées, pour pouvoir ajouter des récitateurs et des sourates sans tout refaire :

```
Contenu (JSON + audio embarqués, produits par tools/)
        │
ShadowingCore (Swift pur, sans UIKit ni AVFoundation, testé)
  modèles, sélection, plan de lecture, formats d'affichage
        │
Application (SwiftUI)
  ├─ Audio : session, moteur AVAudioEngine, Now Playing, interruptions
  ├─ Données : chargement du contenu, persistance SwiftData
  └─ Interface : Accueil, Pratique, Lecteur, Réglages, Fiche
```

- **ShadowingCore** est un paquet Swift local : toute la logique pure (sélection de plage, calcul des timings, planification des répétitions et des pauses) s'y trouve et se teste avec `swift test`, sans simulateur.
- Le **moteur audio** consomme un « plan de lecture » calculé par ShadowingCore. Il ne contient aucune règle métier, il exécute.
- L'**interface** observe un modèle `@Observable` (`PracticeSession`) qui relie sélection, réglages et moteur.
- Aucune dépendance tierce dans l'application. Python est utilisé seulement dans `tools/`, hors application.

## 3. Arborescence proposée

```
Talaqqi-ios/
├─ CLAUDE.md
├─ README.md                      installation sur iPhone, structure, sources
├─ .gitignore
├─ docs/
│  ├─ BRIEF_CLAUDE_CODE.md
│  ├─ BRIEF_DESIGN.md
│  ├─ design/png/01-accueil.png … 05-fiche-sourate.png
│  ├─ design/html/01-accueil/Main.dc.html + README.md   (×5, sans le runtime React)
│  └─ prototype/index.html + kursi.mp3
├─ tools/                         Python, hors application
│  ├─ README.md
│  ├─ requirements.txt            faster-whisper, requests
│  ├─ sources/                    données brutes téléchargées, versionnées (traçabilité)
│  ├─ fetch_sources.py            audio, arabe, phonétique, traduction, fiches
│  ├─ split_long_verse.py         découpe des versets longs (Ayat al-Kursî)
│  ├─ verify_pieces.py            transcription faster-whisper de chaque morceau
│  └─ build_content.py            JSON final + audio converti → app
├─ Packages/ShadowingCore/
│  ├─ Package.swift
│  ├─ Sources/ShadowingCore/      Models, Selection, PlaybackPlan, Formatting
│  └─ Tests/ShadowingCoreTests/
└─ Talaqqi/                       dossier du projet créé par Xcode
   ├─ Talaqqi.xcodeproj
   └─ Talaqqi/                    cible iOS (dossier synchronisé Xcode)
   ├─ App/TalaqqiApp.swift
   ├─ Audio/                      AudioSessionController, ShadowingEngine, PieceBufferLoader, NowPlayingController
   ├─ Data/                       ContentLibrary, modèles SwiftData (historique, état par contenu)
   ├─ Features/Home/              HomeView, RecentStrip, ContentRow
   ├─ Features/Practice/          PracticeView, PieceRow, RepeatMarker, DisplayToggles, PracticeSession
   ├─ Features/Player/            FloatingPlayer, Timeline (frise), TurnCountdown
   ├─ Features/Settings/          SettingsSheet
   ├─ Features/SurahInfo/         SurahInfoSheet
   ├─ DesignSystem/               couleurs, typographie, métriques des maquettes
   └─ Resources/                  Assets.xcassets (Accent, Gold clair/sombre), Fonts/, Content/*.json, Audio/*.m4a
```

Le nom de la cible suit le nom du dépôt (« Talaqqi »). Le nom affiché sur l'écran d'accueil reste provisoire et se change en une ligne plus tard.

## 4. Modèle de données

**Contenu embarqué** (JSON généré par `tools/`, décodé en `Codable`) :

```
Library
 ├─ reciter: Reciter { id, name, source }
 ├─ sections: [Section { title: "Versets" | "Juz ‘Amma", items: [ContentID] }]
 └─ contents: [Content]

Content { id: "2:255" | "112", kind: .verse | .surah, title, subtitle, arabicName,
          surah, verseCount, info: SurahInfo?, verses: [Verse], pieces: [Piece] }
Verse   { number, translation (verset complet, source), lastPieceIndex }
Piece   { index (0 = Basmala), verse: Int?, arabic, phonetic, translation?,
          audio: AudioClip { file, startSample, endSample, sampleRate } }
SurahInfo { objectives (texte recopié), source }
Sources { arabic, phonetic, translation, audio }   (affichées dans la fiche ou un écran « Sources »)
```

- `pieces` est la liste plate utilisée pour pratiquer ; `verses` sert à la navigation et aux marqueurs de fin de verset.
- La Basmala est le morceau 0 de chaque contenu, avec son propre clip audio.
- Les timings sont en échantillons, pas en secondes, pour des coupes exactes.

**État local (SwiftData)** :

```
PracticeState  { contentID (unique), selectionStart, selectionEnd,
                 repetitions (1,2,3,5, ∞), gapSeconds (0…5, pas 0,5, défaut 1), echo,
                 rate (0,75 / 0,9 / 1), showPhonetic, showArabic, showTranslation, memoryMode }
ListeningEntry { contentID, selectionStart, selectionEnd, date }
```

- Une `ListeningEntry` est enregistrée quand la sélection a été lue **en entier au moins une fois** ; si la même sélection existe déjà, on met seulement sa date à jour.
- Le bandeau affiche les entrées les plus récentes (limite proposée : 10).

## 5. Moteur audio

**Session** : `AVAudioSession` catégorie `.playback`, mode `.spokenAudio`, mode d'arrière-plan `audio` dans `Info.plist`. Le son sort donc sur le haut-parleur en mode silencieux, et la lecture continue écran éteint.

**Chaîne** : `AVAudioEngine` → `AVAudioPlayerNode` → `AVAudioUnitTimePitch` (vitesse sans changer la hauteur) → sortie.

**Préparation des morceaux** : chaque morceau est lu une fois depuis son fichier dans un `AVAudioPCMBuffer`, et on applique le fondu d'entrée (10 ms) et le fondu de sortie (30 ms) directement sur les échantillons. Les morceaux sont courts (quelques secondes, quelques centaines de Ko en mémoire). C'est plus simple et plus sûr que `scheduleSegment`, qui ne permet pas de fondus à l'échantillon près.

**Plan de lecture** (pur, dans ShadowingCore, testé) :

```
[ morceau a, respiration 0,3 s, morceau a+1, …, morceau b, PAUSE ]  × répétitions
```

- La respiration de 0,3 s n'est ajoutée qu'entre deux morceaux qui ne sont pas contigus dans un même fichier (d'un verset à l'autre). Entre deux morceaux d'Ayat al-Kursî, le silence naturel du récitant est déjà dans les timings ; la règle précise sera calée à l'écoute.
- La pause = un **vrai buffer de silence** (pas de minuteur), de longueur « temps pour répéter », ou en mode Écho la durée du passage à la vitesse choisie. Comme `TimePitch` étire aussi le silence, sa longueur en échantillons est multipliée par la vitesse pour que la durée réelle soit exacte.
- Pas de pause après la dernière répétition.

**Exécution** : le moteur programme les buffers à l'avance. En mode infini, il garde toujours environ deux tours en file et en ajoute un à chaque fin de tour (rappel `.dataPlayedBack`). Comme le moteur joue en permanence, même pendant les silences, iOS ne suspend pas l'application.

**Position et affichage** : la position vient de `playerNode.lastRenderTime` → `playerTime(forNodeTime:)`, convertie par le plan en (élément en cours, progression, répétition, pause restante). L'interface la lit au rythme de l'écran (`TimelineView`) seulement quand elle est visible.

**Commandes** : pause et reprise avec `playerNode.pause()` / `play()` (la file est conservée). Changer la sélection ou un réglage arrête la file et en programme une nouvelle ; si la lecture était en cours, elle reprend, comme dans le prototype.

**Système** :
- `MPNowPlayingInfoCenter` : titre « Ayat al-Kursî · Morceaux 2 → 4 », artiste « Ali Al-Hudhaify », durée et position du passage.
- `MPRemoteCommandCenter` : lecture, pause, bascule.
- Interruptions (appel, autre application) : pause, puis reprise si le système l'indique (`shouldResume`).
- Écouteurs débranchés (`oldDeviceUnavailable`) : pause.
- Changement de configuration du moteur (`AVAudioEngineConfigurationChange`) : redémarrage propre.

**Format embarqué** : les MP3 d'everyayah sont convertis par `tools/` en AAC mono (`.m4a`). Le MP3 introduit des décalages de début variables selon le décodeur ; l'AAC en `.m4a` indique son décalage, qu'AVFoundation respecte. Les timings sont calculés sur les fichiers convertis, donc identiques à ce que lit l'application.

## 6. Contenu et outils (`tools/`)

1. **`fetch_sources.py`** télécharge et range dans `tools/sources/`, avec l'URL et la date :
   - audio Hudhaify verset par verset (`Hudhaify_128kbps/SSSAAA.mp3`), et la Basmala (`001001.mp3`, à vérifier) ;
   - arabe ottoman avec signes waqf ;
   - phonétique Tanzil `en.transliteration` ;
   - traduction QuranEnc `french_hameedullah` ;
   - objectifs des sourates QuranEnc `french_mokhtasar`.
2. **`split_long_verse.py`** (seulement 2:255 en version 1) : `ffmpeg silencedetect` (−25 dB, 0,25 s), coupes placées dans les silences proches des signes waqf, début et fin resserrés sur la voix (profil de volume par tranches de 10 ms). Le cas difficile « ḥifẓuhumā / wa huwa » est traité à part et vérifié à l'écoute. Le script sera d'abord testé sur `docs/prototype/kursi.mp3` (Al-Ghamidi), dont on connaît déjà les bons timings, avant de l'appliquer à Al-Hudhaify.
3. **`verify_pieces.py`** : faster-whisper `small`, langue arabe, sur chaque morceau. Il compare le texte entendu au texte attendu (sans voyelles) et signale les débordements.
4. **`build_content.py`** : resserre aussi le début et la fin des versets courts (un morceau = un fichier), convertit l'audio et écrit `Resources/Content/library.json`.
5. **Validation humaine** : un rapport lisible (texte, durée, résultat de la transcription) que tu valides, plus une écoute dans l'application. Rien n'est figé sans ton accord.

**Fiches de sourate** : le paragraphe « objectifs » est extrait tel quel de `french_mokhtasar`. Si la donnée n'existe pas pour une sourate, la fiche n'a pas de paragraphe ; pour Ayat al-Kursî, le bouton `info.circle` est désactivé.

**Police** : KFGQPC Uthmanic Script HAFS (King Fahd Complex) embarquée, Amiri Quran en secours. Le texte arabe doit venir de la même famille que la police (texte « QPC Hafs »), sinon certains signes s'affichent mal. C'est ce qui oriente le choix de la source arabe.

## 7. Interface (décisions de détail)

- **« Toute la sourate »** : le titre « Morceaux 2 → 4 » du lecteur est un `Menu` natif (avec un petit chevron discret) qui propose « Toute la sourate ».
- **Défilement automatique** vers le morceau en lecture (`ScrollViewReader`, animation douce, sans rebond).
- **Repère de reprise** : dessiné en arrière-plan de la colonne, de la première à la dernière ligne sélectionnée ; « ×3 » ou « ∞ » au-dessus.
- **Mode mémoire** : flou sur les textes des morceaux de la sélection sauf le dernier, avec un petit bouton « Voir » (capsule neutre, même style que les bascules) qui révèle ce morceau jusqu'au prochain changement de sélection.
- **Hors sélection** : phonétique seule, même si l'arabe est activé ; si la phonétique est désactivée, l'arabe est affiché à la place pour que la ligne ne soit jamais vide (à confirmer à l'usage).
- **Matériaux** : Liquid Glass du système (`glassEffect`) pour le lecteur ; barre de navigation et feuilles natives.
- **Dark mode** : couleurs système pour fond, texte, secondaire, filets ; Accent et Doré dans l'Asset Catalog avec variantes ; icône lecture / pause noire sur l'accent en sombre.
- **Accessibilité** : libellés VoiceOver repris des maquettes (« Sélection : morceaux 2 à 4, répétée 3 fois »…), cibles de 44 pt.

## 8. Étapes de développement

Chaque étape se termine par un commit poussé sur `claude/clever-mayer-c5wxy7` et, quand il y a quelque chose à voir, un test sur ton iPhone.

| # | Étape | Qui | Résultat vérifiable |
|---|---|---|---|
| 0 | Ranger le dépôt : `docs/`, `CLAUDE.md`, `.gitignore`, README | moi | dépôt structuré |
| 1 | Créer le projet Xcode vide (réglages fournis pas à pas) | toi, guidé | le projet compile |
| 2 | ShadowingCore : modèles, sélection, plan de lecture + tests | moi | `swift test` passe sur ton Mac |
| 3 | `tools/` : contenu d'**Ayat al-Kursî** : audio Hudhaify (2:255 et Basmala), arabe, phonétique, traduction ; découpe en morceaux + vérification Whisper + ta validation à l'écoute | moi + toi | 9 morceaux validés, `library.json` + audio |
| 4 | **Moteur audio** testé sur Ayat al-Kursî avec une interface minimale | moi | sur l'iPhone : mode silencieux, écran éteint, autre app, coupes, pauses, vitesse, écran verrouillé |
| 5 | Écran de pratique : morceaux, niveaux d'encre, repère, défilement, barre de progression | moi | conforme aux maquettes 2 et 3 |
| 6 | Lecteur flottant : frise, « À toi », commandes ; feuille Réglages | moi | maquettes 2, 3, 4 |
| 7 | Accueil, bandeau « Récemment », persistance SwiftData | moi | maquette 1, reprise d'une sélection |
| 8 | Mode mémoire, « Toute la sourate », finitions sombre, VoiceOver, interruptions | moi | comportement complet sur Ayat al-Kursî |
| 9+ | **Sourates une par une, en partant de la fin** : 114, puis 113, 112… jusqu'à 100 ; fiche de sourate (maquette 5) avec la première sourate. Un commit par sourate, validé par toi avant la suivante | moi + toi | chaque sourate écoutée et validée |

**État de l'étape 1** : projet créé par Amadou (commit `8a9d937`, après correction d'un dépôt Git imbriqué créé par Xcode). Réglages de la cible appliqués ensuite directement dans `project.pbxproj` : iOS 26.0, iPhone seul, portrait seul, et `Talaqqi/Talaqqi-Info.plist` (hors du dossier synchronisé) avec `UIBackgroundModes` = `audio`. La disposition imbriquée `Talaqqi/Talaqqi.xcodeproj` (créée automatiquement par Xcode) est conservée ; le paquet sera référencé comme `../Packages/ShadowingCore`. Les cibles de test `TalaqqiTests` et `TalaqqiUITests` créées par Xcode sont gardées.

**État de l'étape 2 (commit `996cd87`)** : premier `swift test` sur le Mac d'Amadou : compilation OK, 42 tests sur 43 passent. Échec dans `FadesTests.fadesInAndOutWithoutTouchingTheMiddle` (`Packages/ShadowingCore/Tests/ShadowingCoreTests/SettingsAndFadesTests.swift:46`) : `samples[70] == 29.0 / 30.0` compare un `Float` (0.96666664) à un `Double` (0.9666666666666667), car la macro `#expect` type les deux côtés séparément. Le code de `Fades.apply` est correct, c'est le test qui est faux. Correction : écrire `#expect(samples[70] == Float(29) / Float(30))`. Corrigé dans le commit `a8c942c` ; Amadou relance `swift test` (attendu : 43 tests passés).

**État de l'étape 3 (commit `6cd28d6`, en cours)** : scripts `tools/` écrits, sources de 1:1 et 2:255 téléchargées, Ayat al-Kursî construit (Basmala + 8 morceaux, 7 pauses nettes d'Al-Hudhaify, dont une entre « ḥifẓuhumā » et « wa huwa »). Phonétique : QUL Tajweed (ressource 469, lue sur la page publique de chaque verset). Traduction : appels de note `[n]` retirés. Pas encore validé à l'écoute.

### Étape 3 bis : chaîne de contenu automatisée, tests d'abord (demande d'Amadou)

**Pourquoi** : le même travail se répétera pour chaque sourate. Au lieu de vérifier à la main à chaque fois, on écrit d'abord des tests génériques, puis une seule commande télécharge, construit et teste. Vert : on committe. Rouge : le test dit quoi et où.

**Spécification par contenu** (`tools/content/<id>.json`, le « test écrit d'abord ») : pour une sourate, juste `id`, `kind`, `surah`, `title`, `arabicName`, `basmala` (noms repris de la liste de `docs/BRIEF_DESIGN.md`, section 7). Les versets sont énumérés depuis la source ; règle par défaut : un morceau par verset. Le regroupement en phrases (`pieces`) n'est écrit que pour les versets longs, comme `tools/content/2_255.json`.

**Tests pytest** (`tools/tests/`, `pytest` ajouté à `tools/requirements.txt`), paramétrés sur chaque contenu de `library.json` :
1. **Fidélité des textes** : les morceaux d'un verset remis bout à bout redonnent exactement `arabic_text` (QuranEnc), la translittération QUL et la traduction ; seule différence permise : les `[n]` retirés (`tools/text.py` : `strip_footnote_refs`, `waqf_phrases`, `transliteration_phrases`, `sentences`).
2. **Cohérence des sources** : autant de signes de pause en arabe que d'arrêts en phonétique pour les versets découpés ; chaque phrase de traduction utilisée une fois, dans l'ordre.
3. **Libellés** : ni tiret cadratin ni émoji dans titres et sous-titres.
4. **Structure audio** : morceaux ordonnés, sans chevauchement, dans les bornes du fichier, tous à 44 100 Hz, fichiers présents.
5. **Pas de débordement** : avant le début et après la fin de chaque morceau (hors bords du fichier), au moins 150 ms de silence sous le seuil (`tools/audio.py` : `loudness_profile`).
6. **Durée plausible** : secondes par lettre arabe (texte normalisé, `text.normalize_arabic`) dans une plage calibrée sur Ayat al-Kursî ; attrape deux phrases fusionnées ou une phrase manquante.
7. **Conversion fidèle** : `.m4a` aligné à l'échantillon près sur le MP3 source (décalage 0, longueur à une trame AAC près).
8. **Whisper mot à mot** : premier et dernier mots entendus = premier et dernier mots attendus, ressemblance globale ≥ 75 % ; transcriptions mises en cache (`tools/.cache/`, clé = empreinte de l'extrait) pour que les relances soient rapides.
9. **Non-régression de l'algorithme de découpe** : sur `docs/prototype/kursi.mp3` (Al-Ghamidi), retrouver les coupes du prototype à ±0,15 s là où le récitant fait une vraie pause (timings du bloc `LESSON` de `docs/prototype/index.html`, copiés dans `tools/tests/golden/ghamidi_2255.json` ; la coupe sans pause « ḥifẓuhumā / wa huwa » est exclue).

**Test Swift** : `Packages/ShadowingCore/Tests/ShadowingCoreTests/LibraryTests.swift` décode le vrai `Talaqqi/Talaqqi/Resources/Content/library.json` (chemin relatif via `#filePath`) et construit un `PlaybackPlan` pour chaque contenu ; indices de morceaux contigus, plages de versets cohérentes.

**Commande unique** : `tools/.venv/bin/python tools/pipeline.py 114` = `fetch_sources` (si absent) → `build_content` → `pytest` sur ce contenu → résumé vert / rouge + rapport `tools/reports/<id>.md` ; code de sortie non nul si rouge. `verify_pieces.py` devient le module Whisper appelé par les tests.

**Whisper** : `hf.co` ajouté, mais `us.aws.cdn.hf.co` et `cas-server.xethub.hf.co` répondent encore 403 (règle pas encore appliquée, ou sous-domaines non couverts). Tant que c'est bloqué, le test 8 est marqué « non exécuté » et le résultat du pipeline est « incomplet », jamais vert. Demander à Amadou d'ajouter ces deux hôtes exacts, ou de relancer la session.

**Rôle humain restant** : une écoute du contenu complet avant chaque commit ; décision quand un test signale une pause manquante ou en trop (jamais tranchée par le script).

**Ordre** : écrire les tests → les lancer sur Ayat al-Kursî (calibrer les seuils, noter les valeurs retenues) → écoute d'Amadou → commit → An-Nâs (114) avec la commande unique.

**État** : chaîne en place (`tools/pipeline.py`, `tools/tests/`, `LibraryTests.swift`). Découpe : pauses = creux du volume lissé, frontières estimées au prorata des lettres, attribution ordonnée (programmation dynamique) ; retrouve les 7 coupes du prototype d'Al-Ghamidi à 0,12 s près et ignore sa pause après وَٱلۡأَرۡضَۖ comme la spécification le demande. Débit mesuré d'Al-Hudhaify : 0,19 à 0,38 s par lettre (plage tolérée 0,12 à 0,60). Ayat al-Kursî : 28 tests verts, 9 Whisper non exécutés (CDN Hugging Face encore bloqué). Deux fautes injectées volontairement (une lettre changée, une coupe allongée) ont bien été détectées.

**Ayat al-Kursî validé** par Amadou à l'écoute ; `swift test` : 46 tests passés sur son Mac.

### An-Nâs (114) : premier contenu passé par la chaîne

**Constats sur les sources** (lecture seule) :
- QuranEnc `french_hameedullah` sourate 114 : 6 versets ; la traduction est une seule phrase répartie sur les versets (« Le Souverain des hommes, »…), avec des guillemets droits `"` : recopiée telle quelle.
- La fiche « Parmi les objectifs de la sourate » n'est pas dans l'API `french_mokhtasar` (qui donne le tafsir verset par verset) mais dans la page publique `https://quranenc.com/fr/browse/french_mokhtasar/114`, bloc « Parmi les objectifs de la sourate: » : texte arabe puis français. Pour 114 : « Elle commande de se prémunir et de se préserver par Allah contre le mal de Satan et son insufflation. » Pour 112, c'est exactement le texte de la maquette 5, ce qui confirme la source.

**Changements** :
1. `tools/content/114.json` (spécification, écrite d'abord) : `{"id": "114", "kind": "surah", "surah": 114, "title": "An-Nâs", "arabicName": "الناس", "basmala": true}` ; noms repris de `docs/BRIEF_DESIGN.md` section 7. Sous-titre par défaut « Sourate 114 ».
2. `tools/fetch_sources.py` : `fetch_surah_info(surah)` lit la page publique, extrait le paragraphe français (et l'arabe pour traçabilité), et l'enregistre dans `tools/sources/quranenc/french_mokhtasar/objectives/114.json` avec URL et date ; appelé par `fetch_surah`. Si le bloc est absent : pas de fichier, pas de fiche.
3. `tools/build_content.py` : pour une sourate, `info = {"objectives": <texte>, "source": LIBRARY_SOURCES["surahInfo"]}` si le fichier existe (correspond à `SurahInfo` dans `Packages/ShadowingCore/Sources/ShadowingCore/Models.swift`).
4. `tools/tests/test_texts.py` : `test_surah_info_reproduces_its_source` (texte identique à la source ; absent si la source est absente).
5. `tools/.venv/bin/python tools/pipeline.py 114` : attendu 7 morceaux (Basmala + 6), section « Juz ‘Amma » créée, tous les tests verts sauf Whisper (« non exécuté » tant que `us.aws.cdn.hf.co` et `cas-server.xethub.hf.co` sont bloqués) → résultat INCOMPLET.
6. Envoi des 7 extraits à Amadou pour l'écoute ; commit + push (le hook l'exige en fin de tour), message indiquant « à valider à l'écoute ». Puis `swift test` sur son Mac (LibraryTests couvre le nouveau contenu).

**Si un test est rouge** : ne rien forcer ; rapporter le test, le morceau et la raison, et demander la décision (par exemple une longue pause à l'intérieur d'un verset).

**État** : An-Nâs, Al-Falaq, Al-Ikhlâs, Al-Masad construits par la chaîne (181 tests verts, Whisper non exécuté) ; An-Nâs validé à l'écoute.

### Étape 4 (faite sans validation intermédiaire, à la demande d'Amadou)

Paquet `ShadowingCore` relié à la cible dans `project.pbxproj` (référence locale `../Packages/ShadowingCore`). `ShadowingPlayer` (AVAudioEngine → AVAudioUnitTimePitch, buffers à l'échantillon près, silences réels, deux tours d'avance en boucle infinie, interruptions, écouteurs débranchés, Now Playing et commandes de l'écran verrouillé). Interface minimale : liste des contenus, écran de pratique (trois niveaux d'encre, barre de progression, défilement automatique), lecteur (menu « Toute la sourate », −, lecture, +, arrêt, « À toi » en doré), feuille Réglages. Couleurs Accent et Gold dans l'Asset Catalog. Police arabe système en attendant KFGQPC. Prochaine étape demandée par Amadou : le logo.

### Logo et étapes C et D (faites d'une traite à la demande d'Amadou)

- **Logo** : direction 3, le tā’ calligraphié (deux points : le maître à l'encre, l'élève en rouge). `AppIcon` clair (opaque), sombre et teinté (fond transparent). Planche des directions : `docs/logo-directions.png`.
- **Sourates 110 à 100** : 691 tests verts sur 16 contenus. An-Nasr 110:3 coupé en deux morceaux (pause d'Al-Hudhaify au signe ۚ, deux phrases de traduction). La translittération QUL marque parfois l'arrêt d'une simple virgule.
- **C, écran de pratique** : barre d'affichage Phonétique / Arabe / Français / Mémoire, repère de reprise « ×3 » dans la marge, trois niveaux d'encre, barre de progression 2 pt, marqueur de fin de verset, mode mémoire (flou + « Voir »), titre et sous-titre, bouton `info.circle` et fiche de sourate (maquette 5).
- **Police** : KFGQPC inaccessible (sites du Complexe du Roi Fahd et CDN de Quran.com bloqués) ; **Amiri Quran** (OFL, dépôt Google Fonts) embarquée. Correspondance d'affichage des tanwīn ouverts du texte QPC (U+065E → U+08F1, U+0656 → U+08F2), le texte enregistré n'est pas modifié.
- **D, lecteur et réglages** : frise proportionnelle aux durées (visible aussi à l'arrêt), compte à rebours doré, frise estompée pendant « À toi », Liquid Glass, feuille Réglages.
- **Reste** (étapes E et F) : accueil conforme et bandeau « Récemment », persistance SwiftData, finitions sombre et VoiceOver ; Whisper toujours bloqué.

L'audio passe avant l'interface (étape 4), sur une interface minimale : c'est le risque principal, et le prototype web a justement échoué sur iPhone à cet endroit. Il est testé directement sur Ayat al-Kursî, le cas le plus exigeant (9 morceaux, coupes nettes, enchaînement « ḥifẓuhumā / wa huwa »).

## 9. Installation sur ton iPhone (résumé, détaillé dans le README)

1. Xcode → Réglages → Comptes : ajouter ton identifiant Apple.
2. Cible → Signing & Capabilities : choisir ton équipe, laisser la signature automatique, bundle identifier unique (par exemple `fr.lespilotes.talaqqi`).
3. Sur l'iPhone : activer le mode développeur (Réglages → Confidentialité et sécurité → Mode développeur), brancher l'iPhone, le choisir comme destination, puis Run.
4. Au premier lancement : Réglages → Général → VPN et gestion de l'appareil → faire confiance au certificat.
5. Identifiant gratuit : l'application expire au bout de 7 jours, il faut la relancer depuis Xcode. Apple Developer Program : un an.

## 10. Vérification

- `swift test` dans `Packages/ShadowingCore` : sélection (toucher, étendre, repartir, +, −, toute la sourate, bornes), plan de lecture (ordre, respiration, pauses fixes et Écho, vitesse, répétitions finies et infinies, pas de pause finale), conversion position → (morceau, progression, répétition).
- `tools/verify_pieces.py` : rapport de transcription de chaque morceau.
- Tests manuels sur iPhone, liste à cocher pour chaque étape audio : mode silencieux sur haut-parleur ; écran verrouillé pendant 3 répétitions avec pauses ; passage dans une autre application ; appel entrant ; écouteurs débranchés ; commandes de l'écran verrouillé ; aucune trace du morceau suivant à la fin d'une coupe ; enchaînement entre deux versets sans clic.
- Comparaison visuelle avec les PNG de `docs/design/png/`, en clair et en sombre.

## 11. Point bloquant identifié

Le réseau de cette session refuse pour l'instant everyayah.com, quranenc.com, api.quran.com, tanzil.net et qul.tarteel.ai. Décision : Amadou les ajoute aux domaines autorisés de l'environnement (menu de l'environnement dans la barre de titre de la session, Edit, Allowed domains). Faire la même chose pour l'hôte de téléchargement des modèles faster-whisper (huggingface.co) et pour pypi.org si les gestionnaires de paquets ne sont pas déjà autorisés. Les étapes 0 à 2 ne dépendent pas du réseau.

Swift n'est pas installé ici : je ne peux ni compiler ni lancer les tests. Chaque étape Swift est donc vérifiée sur ton Mac (`swift test`, build Xcode) avant de passer à la suivante. ffmpeg et Python sont disponibles ici pour `tools/`.

---

## Annexe A : valeurs relevées dans les maquettes HTML

### 1 · Accueil
| Élément | Valeur |
|---|---|
| Fond / lignes | `#F2F2F7` / `#FFFFFF` |
| Grand titre | 34/41 gras, marge 16 |
| Titres de section | 17/22 semi-gras, marge 20, 6 à 8 dessous ; 20 sous le grand titre, 28 entre sections |
| Bandeau : entrée | 2 lignes, écart 2, rembourrage vertical 6 ; ligne 1 17/22 (nom semi-gras + « · sélection ») ; ligne 2 15/20 `#6E6E73` |
| Bandeau : séparateur | trait vertical 1 pt `#D1D1D6`, marges verticales 8, écart 16, marges latérales 20 |
| Liste | marge 16, rayon 12 ; ligne min 60, rembourrage 8/16, écart 12 |
| Numéro | colonne 28, 15/20 `#6E6E73` tabulaire ; vide pour Ayat al-Kursî |
| Nom / sous-titre | 17/22 ; 15/20 `#6E6E73`, écart 1 |
| Nom arabe | KFGQPC 22/36, à droite |
| Filet | 1 pt `#E5E5EA`, retrait 56 |

### 2 · Pratique en lecture (clair) et 3 · À toi (sombre)
| Élément | Clair | Sombre |
|---|---|---|
| Fond / texte / secondaire | `#FFFFFF` / `#000000` / `#6E6E73` | `#000000` / `#FFFFFF` / `#98989F` |
| Filets | `#EBEBF0`, retrait 48 | `#262628` |
| En-tête | 146 de haut, blanc 90 % flouté | noir 86 % flouté |
| Bouton retour | capsule 44, rayon 22, fond `rgba(120,120,128,.12)` | `.24` |
| `info.circle` désactivé | `rgba(60,60,67,.3)` | `rgba(235,235,245,.3)` |
| Titre / sous-titre | 17/20 semi-gras ; 13/16 secondaire | idem |
| Bascules | 32 de haut, rembourrage 11, rayon 16, écart 4, 15 pt ; active : fond neutre, medium ; inactive : transparent, regular, secondaire | fond `.24` |
| Numéro | colonne 30 alignée à droite, 13/24 tabulaire | idem |
| Texte | départ à 48, marge droite 16, écart 4 entre lignes | idem |
| Rembourrage morceau | 10 haut ; 10 bas (hors sélection), 12 bas (sélection) | idem |
| Phonétique / arabe / traduction | New York 17/24 ; KFGQPC 26/44 à droite ; New York 15/20 secondaire | idem |
| Barre de progression | 8 sous le texte, 2 pt, piste accent 16 % | |
| Repère | sélection 18 de marge haute ; « ×3 » à x 30, 13/16 semi-gras ; trait x 38, de 20 à 12 du bas, 1,5 pt | accent `#E2897D` |
| Lecteur | marges 8, 24 du bas, rembourrage 14/20/10, écart 8, rayon 32, bordure `rgba(0,0,0,.06)`, blanc 78 % | `rgba(28,28,30,.8)`, bordure `rgba(255,255,255,.08)` |
| Ligne 1 | 15/20 semi-gras ; temps 15/20 secondaire tabulaire | idem |
| Frise | écart 3 ; segment 4 pt, rayon 2, piste `rgba(120,120,128,.2)` ; numéro 13/16 à 5 dessous, en cours accent semi-gras | piste `.36` ; frise à 35 % pendant « À toi » |
| Ligne 3 | « Répétition 2 sur 3 » 13/16 secondaire | « À toi · 0,6 s » 13/16 semi-gras `#D4B06A` ; barre 2 pt à 6 dessous, piste doré 20 % |
| Commandes | boutons 44, écart 4 ; icônes 24 (arrêt 22) ; bouton central 64, icône 26 blanche | icône noire |

### 4 · Réglages
Feuille à mi-hauteur, fond `#F2F2F7`, rayon 38 ; poignée 36×5 ; titre « Réglages » 17/22 semi-gras ; bouton « OK » capsule 44 semi-gras à droite ; en-têtes de section 13/18 regular secondaire (pas en majuscules) ; groupes rayon 12 ; contrôles segmentés natifs ; ligne « Temps pour répéter » avec valeur « 1 s » secondaire + stepper natif ; interrupteur Écho ; pied de section « Un silence aussi long que le passage. » 13/18 secondaire. Le tout correspond à un `Form` natif.

### 5 · Fiche de sourate
Feuille fond blanc, rembourrage 24 (28 en bas) ; « OK » en haut à droite ; titre 28/34 gras ; « 4 versets » 17/22 secondaire ; nom arabe KFGQPC 28/48 aligné en bas à droite ; filet `#E5E5EA` avec 20 de marge ; « Parmi les objectifs de la sourate » 17/22 semi-gras ; paragraphe New York 17/26 ; source 13/18 secondaire, en bas. Écran de fond : morceaux sans sélection, rembourrage 12/12, marqueur de verset en ligne à la fin de l'arabe.
