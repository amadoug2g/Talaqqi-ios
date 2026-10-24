# tools/

Préparation du contenu embarqué, hors application. Python 3 et ffmpeg.

```
python3 -m venv tools/.venv
tools/.venv/bin/pip install -r tools/requirements.txt
tools/.venv/bin/python tools/fetch_sources.py 1:1 2:255   # sources brutes dans tools/sources/
tools/.venv/bin/python tools/build_content.py             # audio .m4a + library.json dans l'application
tools/.venv/bin/python tools/verify_pieces.py 2:255       # transcription Whisper et rapport
```

## Sources

| Donnée | Source |
|---|---|
| Audio | Ali Al-Hudhaify, everyayah.com (`Hudhaify_128kbps`), un fichier par verset, `bismillah.mp3` pour la Basmala |
| Arabe | Texte ottoman (Hafs) du Complexe du Roi Fahd, champ `arabic_text` de QuranEnc |
| Phonétique | English Transliteration (Tajweed), Quranic Universal Library (QUL, ressource 469) |
| Traduction | Muhammad Hamidullah, QuranEnc `french_hameedullah` ; seuls les appels de note `[n]` sont retirés |

Chaque fichier de `tools/sources/` garde l'URL et la date de téléchargement.
