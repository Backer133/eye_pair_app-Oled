#!/usr/bin/env python3
# Patcht das von `flutter create` erzeugte android/app/build.gradle.kts so, dass der
# Release-Build mit einem FESTEN Keystore signiert wird (aus dem CI-Secret, via KS_PASS-Env).
# Ohne das signiert jeder CI-Build mit einem zufaelligen Debug-Key -> Updates schlagen mit
# "App nicht installiert" fehl. Wird im GitHub-Actions-Workflow aufgerufen.
import re, os

p = "android/app/build.gradle.kts"
s = open(p, encoding="utf-8").read()
pw = os.environ.get("KS_PASS", "")

block = (
    "\n    signingConfigs {\n"
    "        create(\"release\") {\n"
    "            storeFile = file(\"release.p12\")\n"
    f"            storePassword = \"{pw}\"\n"
    "            keyAlias = \"sbp\"\n"
    f"            keyPassword = \"{pw}\"\n"
    "        }\n"
    "    }\n"
)

if 'getByName("release")' in s:
    print("already patched")
else:
    s = s.replace('signingConfig = signingConfigs.getByName("debug")',
                  'signingConfig = signingConfigs.getByName("release")')
    s = re.sub(r'(\nandroid\s*\{)', lambda m: m.group(1) + block, s, count=1)
    open(p, "w", encoding="utf-8").write(s)
    print("signingConfig 'release' eingefuegt")
