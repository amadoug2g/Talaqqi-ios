# tools/

Préparation du contenu embarqué, hors application. Python 3 et ffmpeg.

```
python3 -m venv tools/.venv
tools/.venv/bin/pip install -r tools/requirements.txt
```

## Ajouter un contenu : une commande

1. Écrire d'abord la spécification `tools/content/<id>.json` (c'est le test écrit d'abord). Pour une sourate :

   ```json
   { "id": "114", "kind": "surah", "surah": 114, "title": "An-Nâs", "arabicName": "الناس", "basmala": true }
   ```

   Les versets sont lus dans les sources, un morceau par verset. Pour un verset long, `verses[].pieces`
   dit comment les phrases (coupées aux signes de pause) et les phrases de la traduction se regroupent
   en morceaux : voir `content/2_255.json`. Une sourate peut aussi découper un seul de ses versets (`content/110.json`, verset 3 : le récitant marque la pause du signe ۚ).

   Un contenu peut aussi avoir son propre enregistrement et ses coupes déjà validées à l'oreille (`recording` : récitant, fichier, empreinte sha256, temps de chaque morceau). C'est le cas d'Ayat al-Kursî, récitée par Saad Al-Ghamidi comme dans le prototype ; les surates restent celles d'Al-Hudhaify.

2. Lancer :

   ```
   tools/.venv/bin/python tools/pipeline.py 114
   ```

   Téléchargement des sources (si absentes), construction (`library.json` et audio `.m4a` dans
   l'application), tests, extraits audio dans `tools/reports/<id>/` pour l'écoute.

   | Résultat | Sens |
   |---|---|
   | VERT | tout passe ; reste l'écoute du contenu avant le commit |
   | INCOMPLET | des tests n'ont pas pu tourner (par exemple Whisper sans accès au modèle) |
   | ROUGE | un test échoue ; son message dit quoi et où |

## Ce que vérifient les tests (`tools/tests/`)

| Test | Vérifie |
|---|---|
| `test_texts.py` | Les morceaux remis bout à bout redonnent exactement l'arabe, la phonétique et la traduction des sources ; seuls les appels de note `[n]` sont retirés ; les sources découpées concordent ; pas de tiret cadratin ni d'émoji |
| `test_audio.py` | Morceaux ordonnés et sans chevauchement ; 150 ms de silence avant et après chaque morceau (pas de débordement) ; durée plausible (0,12 à 0,60 s par lettre) ; conversion alignée à l'échantillon près ; `library.json` à jour ; aucune longue pause du récitant laissée sans coupe |
| `test_whisper.py` | La transcription de chaque morceau ressemble au texte attendu (75 %), premier et dernier mots compris |
| `test_segmentation.py` | L'algorithme de découpe retrouve à 0,15 s près les coupes du prototype (Al-Ghamidi) |

Côté Swift, `Packages/ShadowingCore/Tests/ShadowingCoreTests/LibraryTests.swift` charge le vrai
`library.json` et construit un plan de lecture pour chaque contenu.

## Découpe des versets longs

1. Repérer les pauses du récitant (creux du volume lissé sur 100 ms).
2. Estimer où tombe chaque frontière de morceau, au prorata du nombre de lettres.
3. Attribuer à chaque frontière la pause réelle la plus proche, dans l'ordre et une seule fois.
4. Resserrer chaque morceau sur la voix (50 ms avant l'attaque, 80 ms après la fin).

Une longue pause non utilisée fait échouer les tests : c'est à un humain de trancher.

## Sources

| Donnée | Source |
|---|---|
| Audio | Ali Al-Hudhaify, everyayah.com (`Hudhaify_128kbps`), un fichier par verset, `bismillah.mp3` pour la Basmala |
| Arabe | Texte ottoman (Hafs) du Complexe du Roi Fahd, champ `arabic_text` de QuranEnc |
| Phonétique | English Transliteration (Tajweed), Quranic Universal Library (QUL, ressource 469) |
| Traduction | Muhammad Hamidullah, QuranEnc `french_hameedullah` ; seuls les appels de note `[n]` sont retirés |

Chaque fichier de `tools/sources/` garde l'URL et la date de téléchargement.
