#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/web
if [ ! -f .export_templates/web_nothreads_release.zip ]; then
  python3 tools/fetch_web_template.py
fi
godot --headless --editor --import --quit
godot --headless --export-release Web build/web/index.html
cp docs/images/cover.png build/web/cover.png
cp assets/fonts/OFL.txt build/web/FONT-LICENSE.txt
cp assets/audio/cc0_combat/LICENSES.md build/web/AUDIO-CREDITS.md
python3 - <<'PY'
from pathlib import Path
import hashlib,json
web=Path('build/web')
pack=web/'index.pck'
name='game-'+hashlib.sha256(pack.read_bytes()).hexdigest()[:12]+'.pck'
for old in web.glob('game-*.pck'):old.unlink()
pack.rename(web/name)
html=web/'index.html'
html.write_text(html.read_text().replace('const canvas=','config.mainPack='+json.dumps(name)+';\nconst canvas=',1))
(web/'.nojekyll').touch()
PY
