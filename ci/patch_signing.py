#!/usr/bin/env python3
# Patcht das von `flutter create` erzeugte android/app/build.gradle.kts so, dass der
# Release-Build mit einem FESTEN Keystore (aus key.properties) signiert wird.
# Ohne das signiert jeder CI-Build mit einem zufaelligen Debug-Key -> Updates schlagen
# mit "App nicht installiert" fehl. Wird im GitHub-Actions-Workflow aufgerufen.
import re

p = "android/app/build.gradle.kts"
s = open(p, encoding="utf-8").read()

block = '''
    signingConfigs {
        create("release") {
            val kp = java.util.Properties()
            val kpf = rootProject.file("key.properties")
            if (kpf.exists()) kpf.inputStream().use { kp.load(it) }
            keyAlias = kp.getProperty("keyAlias")
            keyPassword = kp.getProperty("keyPassword")
            storeFile = kp.getProperty("storeFile")?.let { file(it) }
            storePassword = kp.getProperty("storePassword")
        }
    }
'''

if 'getByName("release")' in s:
    print("already patched")
else:
    s = s.replace('signingConfig = signingConfigs.getByName("debug")',
                  'signingConfig = signingConfigs.getByName("release")')
    s = re.sub(r'(\nandroid\s*\{)', r'\1\n' + block, s, count=1)
    open(p, "w", encoding="utf-8").write(s)
    print("signingConfig 'release' eingefuegt")
