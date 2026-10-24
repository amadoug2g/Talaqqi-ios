"""Une commande pour un contenu : télécharger, construire, tester.

    tools/.venv/bin/python tools/pipeline.py 114
    tools/.venv/bin/python tools/pipeline.py 2:255

La spécification tools/content/<id>.json doit exister avant : c'est le test écrit d'abord.
Résultat : VERT (tout passe), INCOMPLET (des tests n'ont pas pu tourner, par exemple Whisper),
ROUGE (au moins un test échoue). Le code de sortie vaut 0, 2 ou 1.
"""

import os
import subprocess
import sys
from pathlib import Path

import pytest

TOOLS = Path(__file__).resolve().parent
SOURCES = TOOLS / "sources"
PYTHON = sys.executable

# Le transfert « Xet » de Hugging Face passe par des hôtes souvent bloqués ; le téléchargement classique suffit.
os.environ.setdefault("HF_HUB_DISABLE_XET", "1")

SPEC_TEMPLATE = """{{
  "id": "{id}",
  "kind": "surah",
  "surah": {id},
  "title": "…",
  "arabicName": "…",
  "basmala": true
}}"""


class Results:
    def __init__(self):
        self.passed, self.failed, self.skipped = [], [], []

    def pytest_runtest_logreport(self, report):
        if report.when == "call" and report.passed:
            self.passed.append(report)
        elif report.failed:
            self.failed.append(report)
        elif report.skipped:
            self.skipped.append(report)


def run(*args: str) -> None:
    subprocess.run([PYTHON, *args], check=True, cwd=TOOLS.parent)


def sources_missing(content_id: str) -> bool:
    if ":" in content_id:
        surah, ayah = (int(part) for part in content_id.split(":"))
        return not (SOURCES / "quranenc" / "french_hameedullah" / f"{surah:03d}{ayah:03d}.json").exists()
    return not (SOURCES / "quranenc" / "french_hameedullah" / "index" / f"{int(content_id):03d}.json").exists()


def main(content_id: str) -> int:
    spec = TOOLS / "content" / f"{content_id.replace(':', '_')}.json"
    if not spec.exists():
        print(f"Spécification manquante : {spec.relative_to(TOOLS.parent)}\nÀ écrire d'abord, par exemple :")
        print(SPEC_TEMPLATE.format(id=content_id))
        return 1

    if sources_missing(content_id):
        print("1/3 Téléchargement des sources")
        run(str(TOOLS / "fetch_sources.py"), content_id)
    else:
        print("1/3 Sources déjà présentes")
    print("2/3 Construction")
    run(str(TOOLS / "build_content.py"))
    print("3/3 Tests")
    results = Results()
    pytest.main([str(TOOLS / "tests"), "--content", content_id, "-q", "-p", "no:cacheprovider"], plugins=[results])
    run(str(TOOLS / "verify_pieces.py"), content_id)

    print()
    if results.failed:
        print(f"ROUGE : {len(results.failed)} test(s) en échec, {len(results.passed)} réussi(s).")
        for report in results.failed:
            print(f"  - {report.nodeid.split('::')[-1]}")
        return 1
    if results.skipped:
        print(f"INCOMPLET : {len(results.passed)} test(s) réussi(s), {len(results.skipped)} non exécuté(s).")
        reasons = sorted({str(report.longrepr[-1]) for report in results.skipped})
        for reason in reasons:
            print(f"  - {reason}")
        return 2
    print(f"VERT : {len(results.passed)} test(s) réussi(s). Reste l'écoute du contenu avant le commit.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
