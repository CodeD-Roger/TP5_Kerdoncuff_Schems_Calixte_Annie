#!/bin/bash
# ============================================================
#  TP5 — Reverse Engineering Android IoT
#  InjuredAndroid : Analyse statique + Frida + Objection
#  Cours Cybersécurité IoT — Jour 2
# ============================================================

set +e

BOLD="\033[1m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
RESET="\033[0m"

if [[ $EUID -eq 0 && -n "$SUDO_USER" ]]; then
  REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
elif [[ $EUID -eq 0 && -z "$SUDO_USER" ]]; then
  REAL_HOME="/root"
else
  REAL_HOME="$HOME"
fi

BASE="$REAL_HOME/IoT/formation-Jour2/android-analysis"
REPO_DIR="$BASE/InjuredAndroid"
APK_NAME="InjuredAndroid.apk"
APK_PATH="$BASE/$APK_NAME"
OUT_DIR="$BASE/injured_out"
RESULTS="$BASE/results"
FRIDA_DIR="$BASE/frida-scripts"
FRIDA_SERVER_DIR="$BASE/frida-server"

banner() {
  echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════${RESET}"
  echo -e "${CYAN}${BOLD}  $1${RESET}"
  echo -e "${CYAN}${BOLD}══════════════════════════════════════════${RESET}\n"
}
ok()    { echo -e "  ${GREEN}✔  $1${RESET}"; }
info()  { echo -e "  ${YELLOW}▸  $1${RESET}"; }
warn()  { echo -e "  ${YELLOW}⚠  $1${RESET}"; }
title() { echo -e "\n  ${BLUE}${BOLD}── $1${RESET}"; }

is_valid_apk() {
  local f="$1"
  [[ ! -f "$f" ]] && return 1
  local size; size=$(stat -c%s "$f" 2>/dev/null || echo 0)
  [[ "$size" -lt 500000 ]] && return 1
  xxd "$f" 2>/dev/null | head -1 | grep -q "504b 0304" && return 0
  file "$f" 2>/dev/null | grep -qiE "Zip|Android|Java" && return 0
  return 1
}

# ─────────────────────────────────────────────────────────────
banner "Préparation de l'environnement"

mkdir -p "$BASE" "$RESULTS" "$FRIDA_DIR" "$FRIDA_SERVER_DIR"
cd "$BASE" || { echo "Erreur $BASE"; exit 1; }
ok "Dossier de travail : $BASE"

# ─────────────────────────────────────────────────────────────
banner "Installation des dépendances système"

info "Mise à jour des paquets..."
apt-get update -qq

for pkg in wget curl unzip default-jdk adb python3 python3-pip git file xxd docker.io; do
  dpkg -l "$pkg" &>/dev/null 2>&1 \
    && ok "$pkg déjà installé" \
    || { apt-get install -y -qq "$pkg" 2>/dev/null \
         && ok "$pkg installé" || warn "$pkg non disponible"; }
done

# Node.js
if command -v node &>/dev/null; then
  ok "Node.js : $(node --version)"
else
  info "Installation Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 2>/dev/null
  apt-get install -y -qq nodejs 2>/dev/null && ok "Node.js installé"
fi

# ─────────────────────────────────────────────────────────────
banner "Installation de JADX"

JADX_DIR="$BASE/jadx"
JADX_BIN="$JADX_DIR/bin/jadx"
JADX_URL="https://github.com/skylot/jadx/releases/download/v1.4.7/jadx-1.4.7.zip"

if [[ -f "$JADX_BIN" ]]; then
  ok "JADX déjà installé"
  export PATH="$JADX_DIR/bin:$PATH"
elif command -v jadx &>/dev/null; then
  ok "JADX système disponible"
else
  info "Téléchargement JADX v1.4.7..."
  wget -q --show-progress -O /tmp/jadx.zip "$JADX_URL" 2>&1 \
    || curl -L --progress-bar -o /tmp/jadx.zip "$JADX_URL" 2>&1
  if [[ -f /tmp/jadx.zip && $(stat -c%s /tmp/jadx.zip) -gt 1000000 ]]; then
    unzip -q /tmp/jadx.zip -d "$JADX_DIR" && chmod +x "$JADX_DIR/bin/jadx"
    export PATH="$JADX_DIR/bin:$PATH"
    ok "JADX installé"
    rm -f /tmp/jadx.zip
  else
    warn "JADX non téléchargé"
  fi
fi

# ─────────────────────────────────────────────────────────────
banner "Récupération d'InjuredAndroid (git clone)"

# Méthode principale : git clone du repo (contient l'APK précompilé)
if [[ -d "$REPO_DIR/.git" ]]; then
  info "Repo déjà cloné — mise à jour..."
  cd "$REPO_DIR" && git pull -q 2>/dev/null && ok "Repo mis à jour"
  cd "$BASE"
else
  info "Clonage du repo InjuredAndroid..."
  git clone --depth=1 https://github.com/B3nac/InjuredAndroid "$REPO_DIR" 2>&1 \
    && ok "Repo cloné dans $REPO_DIR" \
    || warn "git clone échoué — réseau indisponible"
fi

# Cherche l'APK dans le repo cloné
if [[ -d "$REPO_DIR" ]]; then
  REPO_APK=$(find "$REPO_DIR" -name "*.apk" 2>/dev/null | head -1)
  if [[ -n "$REPO_APK" ]]; then
    cp "$REPO_APK" "$APK_PATH"
    ok "APK copié depuis le repo : $(basename $REPO_APK)"
  fi
fi

# Fallback : téléchargement direct si APK toujours absent
if ! is_valid_apk "$APK_PATH"; then
  info "APK non trouvé dans le repo — téléchargement direct..."
  DIRECT_URL="https://github.com/B3nac/InjuredAndroid/releases/download/v1.0.12/InjuredAndroid-v1.0.12-release.apk"
  wget -L -q --show-progress -O "$APK_PATH" "$DIRECT_URL" 2>&1 \
    || curl -L --progress-bar -o "$APK_PATH" "$DIRECT_URL" 2>&1
fi

if is_valid_apk "$APK_PATH"; then
  ok "APK valide : $(du -h $APK_PATH | cut -f1) — $(file $APK_PATH | cut -d: -f2 | xargs)"
else
  warn "APK non disponible automatiquement"
  echo ""
  echo -e "  ${BOLD}ACTION REQUISE :${RESET}"
  echo -e "  1. Ouvre sur ton PC :"
  echo -e "     ${CYAN}https://github.com/B3nac/InjuredAndroid/releases/tag/v1.0.12${RESET}"
  echo -e "  2. Télécharge : InjuredAndroid-v1.0.12-release.apk"
  echo -e "  3. Transfère :"
  echo -e "     ${YELLOW}sudo cp ~/InjuredAndroid-v1.0.12-release.apk $APK_PATH${RESET}"
  echo -e "  4. Relance ce script"
  echo ""
  touch "$APK_PATH"
fi

# ─────────────────────────────────────────────────────────────
banner "Décompilation JADX"

JADX_CMD="${JADX_BIN:-jadx}"

if is_valid_apk "$APK_PATH"; then
  if [[ $(find "$OUT_DIR/sources" -name "*.java" 2>/dev/null | wc -l) -gt 0 ]]; then
    NB=$(find "$OUT_DIR/sources" -name "*.java" 2>/dev/null | wc -l)
    ok "Décompilation déjà présente : $NB fichiers Java"
  else
    info "Décompilation (1-2 min)..."
    rm -rf "$OUT_DIR"
    "$JADX_CMD" -d "$OUT_DIR" "$APK_PATH" 2>&1 | grep -E "INFO|WARN|ERROR" | tail -5
    NB=$(find "$OUT_DIR/sources" -name "*.java" 2>/dev/null | wc -l)
    [[ "$NB" -gt 0 ]] \
      && ok "$NB fichiers Java décompilés" \
      || warn "0 fichiers Java — APK peut-être corrompu"
  fi
else
  warn "APK absent — décompilation ignorée"
fi

# ─────────────────────────────────────────────────────────────
banner "Analyse statique — AndroidManifest.xml"

MANIFEST_FILE="$RESULTS/manifest_analysis.txt"
MANIFEST=$(find "$OUT_DIR" -name "AndroidManifest.xml" 2>/dev/null | head -1)

{ echo "=== ANALYSE ANDROIDMANIFEST.XML ==="; echo "Date : $(date)"; echo ""; } \
  > "$MANIFEST_FILE"

if [[ -f "$MANIFEST" ]]; then
  title "Activités exportées"
  {
    echo "--- ACTIVITÉS EXPORTÉES ---"
    grep -B2 'exported.*true' "$MANIFEST" 2>/dev/null || echo "(aucune)"
    echo ""
    echo "--- PERMISSIONS ---"
    grep 'uses-permission' "$MANIFEST" 2>/dev/null \
      | sed 's/.*android:name="\([^"]*\)".*/\1/'
    echo ""
    echo "--- PACKAGE ---"
    grep -E 'package=|versionName=' "$MANIFEST" 2>/dev/null | head -3
  } | tee -a "$MANIFEST_FILE"
  NB_EXP=$(grep -c 'exported.*true' "$MANIFEST" 2>/dev/null || echo 0)
  ok "$NB_EXP activités exportées → manifest_analysis.txt"
else
  warn "AndroidManifest.xml non trouvé"
  echo "(Manifest non disponible)" >> "$MANIFEST_FILE"
fi

# ─────────────────────────────────────────────────────────────
banner "Analyse statique — Secrets hardcodés"

SECRETS_FILE="$RESULTS/hardcoded_secrets.txt"
{ echo "=== SECRETS HARDCODÉS ==="; echo "Date : $(date)"; echo ""; } \
  > "$SECRETS_FILE"

if [[ $(find "$OUT_DIR/sources" -name "*.java" 2>/dev/null | wc -l) -gt 0 ]]; then
  for pattern in "api_key" "apikey" "password" "secret" "token" \
                 "firebase" "aws" "mqtt" "broker" "credential" \
                 "private_key" "access_key" "http://" "https://"; do
    MATCHES=$(grep -r -i "$pattern" "$OUT_DIR/sources/" \
      --include="*.java" -l 2>/dev/null | wc -l)
    if [[ "$MATCHES" -gt 0 ]]; then
      { echo "=== [$pattern] — $MATCHES fichiers ===";
        grep -r -i "$pattern" "$OUT_DIR/sources/" \
          --include="*.java" -n 2>/dev/null | head -8;
        echo ""; } >> "$SECRETS_FILE"
      ok "[$pattern] → $MATCHES fichiers"
    else
      info "[$pattern] → 0"
    fi
  done
else
  warn "Sources indisponibles"
  echo "(Sources non disponibles)" >> "$SECRETS_FILE"
fi
ok "Rapport → hardcoded_secrets.txt"

# ─────────────────────────────────────────────────────────────
banner "Analyse statique — Ressources"

RES_FILE="$RESULTS/resources_analysis.txt"
{ echo "=== RESSOURCES ==="; echo "Date : $(date)"; echo ""; } > "$RES_FILE"

STRINGS_XML=$(find "$OUT_DIR" -name "strings.xml" 2>/dev/null | head -1)
if [[ -n "$STRINGS_XML" ]]; then
  { echo "--- strings.xml ---"; cat "$STRINGS_XML"; echo ""; } \
    | tee -a "$RES_FILE" | head -20
  ok "strings.xml analysé"
fi
find "$OUT_DIR" \( -name "*.json" -o -name "*.properties" \) 2>/dev/null \
  | while read f; do
    { echo "--- $(basename $f) ---"; cat "$f" | head -15; echo ""; } >> "$RES_FILE"
    info "Analysé : $(basename $f)"
  done
ok "Ressources → resources_analysis.txt"

# ─────────────────────────────────────────────────────────────
banner "Installation Frida + Objection"

if pip3 show frida &>/dev/null 2>&1; then
  ok "Frida déjà installé"
else
  info "Installation Frida (2-3 min)..."
  pip3 install frida frida-tools \
    --break-system-packages --timeout 120 --no-build-isolation \
    -q 2>&1 | tail -3 \
    && ok "Frida installé" \
    || warn "Frida non installé — essaie : pip3 install frida frida-tools"
fi

if pip3 show objection &>/dev/null 2>&1; then
  ok "Objection déjà installé"
else
  info "Installation Objection (2-3 min)..."
  pip3 install objection \
    --break-system-packages --timeout 120 \
    -q 2>&1 | tail -3 \
    && ok "Objection installé" \
    || warn "Objection non installé"
fi

# Frida-server Android x86
FRIDA_VER=$(pip3 show frida 2>/dev/null | grep Version | awk '{print $2}' || echo "16.2.1")
FRIDA_SERVER="$FRIDA_SERVER_DIR/frida-server"
FRIDA_URL="https://github.com/frida/frida/releases/download/${FRIDA_VER}/frida-server-${FRIDA_VER}-android-x86.xz"

if [[ -f "$FRIDA_SERVER" && $(stat -c%s "$FRIDA_SERVER") -gt 1000000 ]]; then
  ok "Frida-server déjà présent (v$FRIDA_VER)"
else
  info "Téléchargement frida-server v$FRIDA_VER..."
  wget -q --show-progress -O "$FRIDA_SERVER.xz" "$FRIDA_URL" 2>&1 \
    || curl -L --progress-bar -o "$FRIDA_SERVER.xz" "$FRIDA_URL" 2>&1
  if [[ -f "$FRIDA_SERVER.xz" && $(stat -c%s "$FRIDA_SERVER.xz") -gt 1000000 ]]; then
    xz -d "$FRIDA_SERVER.xz" && chmod +x "$FRIDA_SERVER"
    ok "Frida-server prêt : $FRIDA_SERVER"
  else
    warn "Frida-server non téléchargé"
    rm -f "$FRIDA_SERVER.xz"
  fi
fi

# ─────────────────────────────────────────────────────────────
banner "Génération des scripts Frida"

# hook_flag.js
cat > "$FRIDA_DIR/hook_flag.js" << 'JSEOF'
// Hook méthode submitFlag — InjuredAndroid
// frida -U -l hook_flag.js -f b3nac.injuredandroid --no-pause
Java.perform(function() {
  console.log("[*] Hook InjuredAndroid chargé");
  try {
    var FlagOne = Java.use('b3nac.injuredandroid.FlagOneActivity');
    FlagOne.submitFlag.overloads.forEach(function(o) {
      o.implementation = function() {
        var args = Array.prototype.slice.call(arguments);
        console.log('[FLAG1] submitFlag(' + JSON.stringify(args) + ')');
        // Pour forcer le bon flag :
        // return o.apply(this, ['the_real_flag']);
        return o.apply(this, arguments);
      };
    });
    console.log("[+] FlagOneActivity hookée");
  } catch(e) { console.log("[-] " + e); }

  // Scan toutes les méthodes de l'app
  Java.enumerateLoadedClasses({
    onMatch: function(name) {
      if (name.indexOf('b3nac') !== -1) {
        try {
          Java.use(name).class.getDeclaredMethods().forEach(function(m) {
            var mn = m.getName();
            if (/flag|submit|check|verify/i.test(mn))
              console.log('[MÉTHODE] ' + name + '.' + mn);
          });
        } catch(e) {}
      }
    },
    onComplete: function() {}
  });
});
JSEOF
ok "hook_flag.js créé"

# dump_prefs.js
cat > "$FRIDA_DIR/dump_prefs.js" << 'JSEOF'
// Dump SharedPreferences — InjuredAndroid
Java.perform(function() {
  console.log("[*] Dump SharedPreferences actif");
  var SP = Java.use('android.app.SharedPreferencesImpl');
  SP.getString.overload('java.lang.String','java.lang.String').implementation =
    function(k,d) {
      var v = this.getString(k,d);
      if (v !== d) console.log('[PREFS] ' + k + ' = ' + v);
      return v;
    };
  var Act = Java.use('android.app.Activity');
  Act.getSharedPreferences.overload('java.lang.String','int').implementation =
    function(n,m) {
      console.log('[PREFS FILE] ' + n);
      return this.getSharedPreferences(n,m);
    };
  console.log("[+] Hooks SharedPreferences actifs");
});
JSEOF
ok "dump_prefs.js créé"

# bypass_root.js
cat > "$FRIDA_DIR/bypass_root.js" << 'JSEOF'
// Bypass Root Detection — InjuredAndroid
Java.perform(function() {
  console.log("[*] Bypass root detection");
  try {
    var RB = Java.use('com.scottyab.rootbeer.RootBeer');
    RB.isRooted.overload().implementation = function() {
      console.log('[ROOT] isRooted() -> false');
      return false;
    };
    RB.isRootedWithoutBusyBoxCheck.implementation = function() { return false; };
    console.log("[+] RootBeer bypassed");
  } catch(e) { console.log("[-] RootBeer absent : " + e); }
  var File = Java.use('java.io.File');
  File.exists.implementation = function() {
    var p = this.getAbsolutePath();
    if (/su|busybox|superuser/i.test(p)) {
      console.log('[ROOT] File.exists(' + p + ') -> false');
      return false;
    }
    return this.exists();
  };
  console.log("[+] Root detection bypass actif");
});
JSEOF
ok "bypass_root.js créé"

# bypass_ssl.js — méthode complète (doc v2 + fallback)
cat > "$FRIDA_DIR/bypass_ssl.js" << 'JSEOF'
// Bypass SSL Pinning — InjuredAndroid
// Combine les deux méthodes du TP (verifyChain + checkTrustedRecursive)
Java.perform(function() {
  console.log("[*] Bypass SSL Pinning chargé");

  // Méthode 1 : verifyChain (Android 11+ / TP doc v2)
  try {
    var TM = Java.use('com.android.org.conscrypt.TrustManagerImpl');
    TM.verifyChain.implementation = function() {
      console.log('[SSL] verifyChain bypassed');
      return arguments[0];
    };
    console.log("[+] TrustManagerImpl.verifyChain bypassed");
  } catch(e) { console.log("[-] verifyChain absent : " + e); }

  // Méthode 2 : checkTrustedRecursive (Android < 11)
  try {
    var TM2 = Java.use('com.android.org.conscrypt.TrustManagerImpl');
    TM2.checkTrustedRecursive.implementation = function() {
      console.log('[SSL] checkTrustedRecursive bypassed');
      return Java.use('java.util.ArrayList').$new();
    };
    console.log("[+] TrustManagerImpl.checkTrustedRecursive bypassed");
  } catch(e) { console.log("[-] checkTrustedRecursive absent : " + e); }

  // Méthode 3 : OkHttp3 CertificatePinner
  try {
    var CP = Java.use('okhttp3.CertificatePinner');
    CP.check.overload('java.lang.String','java.util.List').implementation =
      function(h,c) { console.log('[SSL] OkHttp3 CertificatePinner(' + h + ') bypassed'); };
    console.log("[+] OkHttp3 SSL pinning bypassed");
  } catch(e) { console.log("[-] OkHttp3 absent : " + e); }

  console.log("[+] SSL bypass complet");
});
JSEOF
ok "bypass_ssl.js créé (verifyChain + checkTrustedRecursive + OkHttp3)"

# list_activities.js
cat > "$FRIDA_DIR/list_activities.js" << 'JSEOF'
// Liste toutes les activités — InjuredAndroid
Java.perform(function() {
  var AT = Java.use('android.app.ActivityThread');
  var ctx = AT.currentApplication().getApplicationContext();
  var pm = ctx.getPackageManager();
  var pkg = ctx.getPackageName();
  try {
    var info = pm.getPackageInfo(pkg, 0x00000008);
    var acts = info.activities.value;
    console.log("\n[+] Activités (" + (acts ? acts.length : 0) + ") :");
    if (acts) acts.forEach(function(a) {
      var exported = a.exported.value;
      var perm = a.permission.value;
      console.log(
        (exported ? "[EXPORTED] " : "[private]  ") +
        a.name.value +
        (perm ? " [perm:" + perm + "]" : "")
      );
    });
  } catch(e) { console.log("[-] " + e); }
});
JSEOF
ok "list_activities.js créé"

# ─────────────────────────────────────────────────────────────
banner "Docker — Émulateur Android alternatif"

# Vérifie si Docker est disponible
if command -v docker &>/dev/null; then
  ok "Docker disponible : $(docker --version 2>/dev/null | head -1)"

  DOCKER_GUIDE="$RESULTS/docker_emulator.txt"
  cat > "$DOCKER_GUIDE" << EOF
=== ÉMULATEUR ANDROID VIA DOCKER ===
Alternative à Android Studio — accessible via navigateur

── Commande de lancement ─────────────────────────────────────
docker run -d \\
  -p 6080:6080 \\
  -p 5555:5555 \\
  -e EMULATOR_DEVICE="Samsung Galaxy S10" \\
  --privileged \\
  budtmo/docker-android:emulator_11.0

── Accès ─────────────────────────────────────────────────────
Interface web : http://localhost:6080
ADB           : adb connect localhost:5555

── Après connexion ADB ───────────────────────────────────────
adb connect localhost:5555
adb devices
adb install $APK_PATH

── Pousser Frida-server ──────────────────────────────────────
adb -s localhost:5555 push $FRIDA_SERVER /data/local/tmp/frida-server
adb -s localhost:5555 shell 'chmod 755 /data/local/tmp/frida-server'
adb -s localhost:5555 shell '/data/local/tmp/frida-server &'

── Frida via ADB réseau ──────────────────────────────────────
frida -H localhost:27042 -l $FRIDA_DIR/hook_flag.js \\
  -f b3nac.injuredandroid --no-pause
EOF
  ok "Guide Docker → docker_emulator.txt"

  # Pull de l'image Docker (optionnel, peut prendre du temps)
  info "Pull de l'image Docker Android (peut prendre 5-10 min selon connexion)..."
  docker pull budtmo/docker-android:emulator_11.0 2>&1 | tail -3 \
    && ok "Image Docker Android prête" \
    || warn "Pull Docker échoué — réseau lent ? Lance manuellement"
else
  warn "Docker non disponible — émulateur Docker ignoré"
  info "Installe Docker : apt install docker.io"
fi

# ─────────────────────────────────────────────────────────────
banner "Génération des guides"

# Guide Frida/Émulateur Android Studio
cat > "$RESULTS/frida_setup_emulator.txt" << EOF
=== SETUP FRIDA — ANDROID STUDIO ===
Date : $(date)

── Prérequis ─────────────────────────────────────────────────
Android Studio + AVD : Pixel 4 API 30 (x86)
Google Play désactivé pour accès root

── Étapes ────────────────────────────────────────────────────
1. Démarrer l'émulateur
   emulator -avd Pixel_4_API_30 &

2. Installer l'APK
   adb install $APK_PATH

3. Pousser frida-server
   adb push $FRIDA_SERVER /data/local/tmp/frida-server
   adb shell 'chmod 755 /data/local/tmp/frida-server'
   adb shell '/data/local/tmp/frida-server &'

4. Vérifier
   frida-ps -U | grep injuredandroid

── Scripts disponibles ───────────────────────────────────────
$FRIDA_DIR/hook_flag.js         Hook submitFlag
$FRIDA_DIR/dump_prefs.js        Dump SharedPreferences
$FRIDA_DIR/bypass_root.js       Bypass root detection
$FRIDA_DIR/bypass_ssl.js        Bypass SSL pinning (verifyChain + OkHttp3)
$FRIDA_DIR/list_activities.js   Liste activités exportées

── Commandes Frida ───────────────────────────────────────────
frida -U -l $FRIDA_DIR/hook_flag.js -f b3nac.injuredandroid --no-pause
frida -U -l $FRIDA_DIR/bypass_root.js -f b3nac.injuredandroid --no-pause
frida -U -l $FRIDA_DIR/bypass_ssl.js -f b3nac.injuredandroid --no-pause

Voir aussi : $RESULTS/docker_emulator.txt pour l'alternative Docker
EOF
ok "Guide Frida → frida_setup_emulator.txt"

# Guide Objection
cat > "$RESULTS/objection_commands.txt" << 'EOF'
=== GUIDE OBJECTION ===
Connexion : objection -g b3nac.injuredandroid explore

── Bypass ──────────────────────────────────────────────────
android root disable
android sslpinning disable

── Exploration ─────────────────────────────────────────────
android hooking list activities
android hooking list services
file ls /data/data/b3nac.injuredandroid/
file ls /data/data/b3nac.injuredandroid/shared_prefs/
android preferences get

── Lancement direct d'activités (bypass auth) ──────────────
android intent launch_activity b3nac.injuredandroid.FlagOneActivity
android intent launch_activity b3nac.injuredandroid.FlagEightLogInActivity

── Hooking ─────────────────────────────────────────────────
android hooking watch class b3nac.injuredandroid.FlagOneActivity
android hooking watch class_method b3nac.injuredandroid.FlagOneActivity.submitFlag --dump-args --dump-return
android hooking list classes | grep injuredandroid

── Mémoire ─────────────────────────────────────────────────
memory list modules
memory dump all /tmp/dump.bin
EOF
ok "Guide Objection → objection_commands.txt"

# Rapport de vulnérabilités
cat > "$RESULTS/vulnerabilities_report.txt" << 'EOF'
=== VULNÉRABILITÉS — InjuredAndroid ===

[V1] ACTIVITÉS EXPORTÉES SANS PERMISSION — CRITIQUE
  Exploitation :
    adb shell am start -n b3nac.injuredandroid/.FlagEightLogInActivity
    objection : android intent launch_activity b3nac.injuredandroid.FlagEightLogInActivity

[V2] SECRETS HARDCODÉS — CRITIQUE
  Exploitation : grep -r 'api_key\|secret\|password' injured_out/sources/

[V3] SHAREDPREFERENCES EN CLAIR — ÉLEVÉE
  Exploitation :
    adb shell cat /data/data/b3nac.injuredandroid/shared_prefs/*.xml
    objection : android preferences get

[V4] AUTH CÔTÉ CLIENT HOOKABLE — CRITIQUE
  Exploitation (Frida) :
    FlagOneActivity.submitFlag.implementation = function() { return true; }

[V5] ROOT DETECTION CONTOURNABLE — ÉLEVÉE
  bypass_root.js / objection : android root disable

[V6] SSL PINNING CONTOURNABLE — ÉLEVÉE
  bypass_ssl.js (verifyChain Android 11+ + checkTrustedRecursive + OkHttp3)
  objection : android sslpinning disable

=== RECOMMANDATIONS ===
- Secrets -> variables d'env / secrets manager (jamais dans le code)
- Validation côté serveur uniquement (zero trust)
- Android Keystore pour données sensibles
- EncryptedSharedPreferences
- SafetyNet / Play Integrity API anti-tampering
- Certificate pinning résistant (network_security_config.xml)
EOF
ok "Rapport vulnérabilités → vulnerabilities_report.txt"

# Info APK
APK_INFO="$RESULTS/apk_info.txt"
{ echo "=== APK INFO ==="; echo "Date : $(date)"; echo ""; } > "$APK_INFO"
if is_valid_apk "$APK_PATH"; then
  { echo "Fichier : $APK_PATH"
    echo "Taille  : $(du -h $APK_PATH | cut -f1)"
    echo "MD5     : $(md5sum $APK_PATH | cut -d' ' -f1)"
    echo "SHA256  : $(sha256sum $APK_PATH | cut -d' ' -f1)"
    echo "Type    : $(file $APK_PATH | cut -d: -f2 | xargs)"
  } | tee -a "$APK_INFO"
  ok "APK info → apk_info.txt"
else
  echo "(APK non disponible)" >> "$APK_INFO"
fi

# ─────────────────────────────────────────────────────────────
banner "Récapitulatif"

echo -e "  ${BOLD}Dossier : $BASE${RESET}"
echo ""
echo "  Résultats générés :"
ls "$RESULTS"/*.txt 2>/dev/null | while read f; do
  echo "  ├── results/$(basename $f)"
done
echo ""
echo "  Scripts Frida :"
ls "$FRIDA_DIR"/*.js 2>/dev/null | while read f; do
  echo "  ├── frida-scripts/$(basename $f)"
done
echo ""

if ! is_valid_apk "$APK_PATH"; then
  echo -e "  ${YELLOW}${BOLD}⚠  APK manquant — télécharge manuellement :${RESET}"
  echo -e "     ${CYAN}https://github.com/B3nac/InjuredAndroid/releases/tag/v1.0.12${RESET}"
  echo -e "     sudo cp ~/InjuredAndroid-v1.0.12-release.apk $APK_PATH"
  echo -e "     Puis relance : ${BOLD}sudo ./install_tp5.sh${RESET}"
  echo ""
fi

echo -e "  ${GREEN}${BOLD}✔  TP5 terminé !${RESET}"
echo ""
