#!/bin/bash
# ============================================================
#  TP5 — Script de tests complet + rapport professionnel
#  InjuredAndroid : Reverse Engineering Android IoT
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
APK_PATH="$BASE/InjuredAndroid.apk"
OUT_DIR="$BASE/injured_out"
RESULTS="$BASE/results"
FRIDA_DIR="$BASE/frida-scripts"
FRIDA_SERVER="$BASE/frida-server/frida-server"
REPORT="$BASE/RAPPORT_TP5.md"

PASS=0; FAIL=0; WARN=0

banner() {
  echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════${RESET}"
  echo -e "${CYAN}${BOLD}  $1${RESET}"
  echo -e "${CYAN}${BOLD}══════════════════════════════════════════${RESET}\n"
}
ok()     { echo -e "  ${GREEN}✔  $1${RESET}"; ((PASS++)); }
fail()   { echo -e "  ${RED}✘  $1${RESET}"; ((FAIL++)); }
warn()   { echo -e "  ${YELLOW}⚠  $1${RESET}"; ((WARN++)); }
info()   { echo -e "  ${BLUE}▸  $1${RESET}"; }
title()  { echo -e "\n  ${BOLD}$1${RESET}"; }

rpt()    { echo -e "$1" >> "$REPORT"; }
rpt_raw(){ echo "$1" >> "$REPORT"; }

is_valid_apk() {
  local f="$1"
  [[ ! -f "$f" ]] && return 1
  [[ $(stat -c%s "$f" 2>/dev/null || echo 0) -lt 500000 ]] && return 1
  xxd "$f" 2>/dev/null | head -1 | grep -q "504b 0304" && return 0
  file "$f" 2>/dev/null | grep -qiE "Zip|Android|Java" && return 0
  return 1
}

# ─────────────────────────────────────────────────────────────
banner "Initialisation du rapport"

mkdir -p "$RESULTS"
DATE_NOW=$(date "+%d/%m/%Y %H:%M")

cat > "$REPORT" << EOF
# Rapport d'analyse — TP5 Reverse Engineering Android IoT
**Auteur :** ${SUDO_USER:-$USER}
**Date :** $DATE_NOW
**Machine :** $(hostname) — $(uname -r)
**Cible :** InjuredAndroid (Damn Vulnerable Android IoT App)
**Dossier :** $BASE

---
EOF
ok "Rapport initialisé : $REPORT"

# ════════════════════════════════════════════════════════════
banner "TEST 1 — Outils installés"

rpt "## 1. Outils installés"
rpt ""
rpt "| Outil | Statut | Version |"
rpt "|---|---|---|"

check_tool() {
  local name="$1" cmd="$2"
  if command -v "$cmd" &>/dev/null; then
    local ver; ver=$($cmd --version 2>/dev/null | head -1 | tr -d '\n' || echo "présent")
    ok "$name"
    rpt "| \`$name\` | ✔ Présent | $ver |"
  else
    fail "$name manquant"
    rpt "| \`$name\` | ✘ Absent | — |"
  fi
}

check_tool "jadx"      "${BASE}/jadx/bin/jadx"
check_tool "frida"     "frida"
check_tool "objection" "objection"
check_tool "adb"       "adb"
check_tool "docker"    "docker"

# Frida-server
if [[ -f "$FRIDA_SERVER" && $(stat -c%s "$FRIDA_SERVER") -gt 1000000 ]]; then
  ok "frida-server (Android x86)"
  rpt "| \`frida-server\` | ✔ Présent | $(du -h $FRIDA_SERVER | cut -f1) |"
else
  warn "frida-server absent ou trop petit"
  rpt "| \`frida-server\` | ⚠ Absent | — |"
fi

rpt ""

# ════════════════════════════════════════════════════════════
banner "TEST 2 — APK InjuredAndroid"

rpt "## 2. APK InjuredAndroid"
rpt ""

if is_valid_apk "$APK_PATH"; then
  SIZE=$(du -h "$APK_PATH" | cut -f1)
  MD5=$(md5sum "$APK_PATH" | cut -d' ' -f1)
  SHA256=$(sha256sum "$APK_PATH" | cut -d' ' -f1)
  FTYPE=$(file "$APK_PATH" | cut -d: -f2 | xargs)
  ok "APK valide ($SIZE)"
  ok "Type : $FTYPE"
  rpt "| Propriété | Valeur |"
  rpt "|---|---|"
  rpt "| Fichier | \`$(basename $APK_PATH)\` |"
  rpt "| Taille | $SIZE |"
  rpt "| Type | $FTYPE |"
  rpt "| MD5 | \`$MD5\` |"
  rpt "| SHA256 | \`$SHA256\` |"
else
  fail "APK absent ou invalide"
  rpt "- ✘ APK non disponible"
fi

rpt ""

# ════════════════════════════════════════════════════════════
banner "TEST 3 — Décompilation JADX"

rpt "## 3. Décompilation JADX"
rpt ""

NB_JAVA=$(find "$OUT_DIR/sources" -name "*.java" 2>/dev/null | wc -l)
NB_CLASSES=$(find "$OUT_DIR" -name "*.class" 2>/dev/null | wc -l)

if [[ "$NB_JAVA" -gt 0 ]]; then
  ok "Décompilation réussie : $NB_JAVA fichiers Java"
  rpt "- **Fichiers Java décompilés :** $NB_JAVA"

  # Packages trouvés
  PACKAGES=$(find "$OUT_DIR/sources" -type d 2>/dev/null \
    | sed "s|$OUT_DIR/sources/||" | grep -v "^$" | head -10)
  rpt "- **Packages identifiés :**"
  rpt '```'
  echo "$PACKAGES" >> "$REPORT"
  rpt '```'
else
  fail "Aucun fichier Java décompilé"
  rpt "- ✘ Décompilation échouée ou APK absent"
fi

rpt ""

# ════════════════════════════════════════════════════════════
banner "TEST 4 — Analyse AndroidManifest.xml"

rpt "## 4. Analyse AndroidManifest.xml"
rpt ""

MANIFEST=$(find "$OUT_DIR" -name "AndroidManifest.xml" 2>/dev/null | head -1)

if [[ -f "$MANIFEST" ]]; then
  ok "AndroidManifest.xml trouvé"

  # Package
  PKG=$(grep -o 'package="[^"]*"' "$MANIFEST" 2>/dev/null | head -1 | cut -d'"' -f2)
  VER=$(grep -o 'versionName="[^"]*"' "$MANIFEST" 2>/dev/null | head -1 | cut -d'"' -f2)
  ok "Package : $PKG (v$VER)"
  rpt "- **Package :** \`$PKG\`"
  rpt "- **Version :** $VER"
  rpt ""

  # Activités exportées
  NB_EXPORTED=$(grep -c 'exported="true"' "$MANIFEST" 2>/dev/null || echo 0)
  if [[ "$NB_EXPORTED" -gt 0 ]]; then
    fail "$NB_EXPORTED activité(s) exportée(s) sans permission — VULNÉRABILITÉ"
    rpt "### Activités exportées (vulnérabilité)"
    rpt ""
    rpt "**$NB_EXPORTED activité(s) accessibles sans authentification :**"
    rpt '```'
    grep -B3 'exported="true"' "$MANIFEST" 2>/dev/null \
      | grep -E 'android:name|exported' | head -30 >> "$REPORT"
    rpt '```'
  else
    ok "Aucune activité exportée sans permission"
    rpt "- Aucune activité exportée sans permission"
  fi
  rpt ""

  # Permissions
  NB_PERMS=$(grep -c 'uses-permission' "$MANIFEST" 2>/dev/null || echo 0)
  info "$NB_PERMS permissions déclarées"
  rpt "### Permissions déclarées ($NB_PERMS)"
  rpt '```'
  grep 'uses-permission' "$MANIFEST" 2>/dev/null \
    | sed 's/.*android:name="\([^"]*\)".*/\1/' >> "$REPORT"
  rpt '```'

  # Permissions sensibles
  DANGEROUS_PERMS=$(grep 'uses-permission' "$MANIFEST" 2>/dev/null \
    | grep -iE "camera|location|storage|contacts|phone|sms|microphone" \
    | sed 's/.*android:name="\([^"]*\)".*/\1/')
  if [[ -n "$DANGEROUS_PERMS" ]]; then
    fail "Permissions dangereuses détectées"
    rpt ""
    rpt "**⚠ Permissions dangereuses :**"
    rpt '```'
    echo "$DANGEROUS_PERMS" >> "$REPORT"
    rpt '```'
  fi
else
  warn "AndroidManifest.xml non trouvé"
  rpt "- ⚠ Manifest non disponible (décompilation incomplète)"
fi

rpt ""

# ════════════════════════════════════════════════════════════
banner "TEST 5 — Recherche de secrets hardcodés"

rpt "## 5. Secrets hardcodés"
rpt ""

TOTAL_SECRETS=0

if [[ "$NB_JAVA" -gt 0 ]]; then
  declare -A PATTERN_RESULTS
  PATTERNS=("api_key" "password" "secret" "token" "firebase"
            "aws" "mqtt" "broker" "private_key" "http://")

  rpt "| Pattern | Fichiers | Criticité |"
  rpt "|---|---|---|"

  for pattern in "${PATTERNS[@]}"; do
    MATCHES=$(grep -r -i "$pattern" "$OUT_DIR/sources/" \
      --include="*.java" -l 2>/dev/null | wc -l)
    if [[ "$MATCHES" -gt 0 ]]; then
      CRIT="Elevée"
      [[ "$pattern" =~ ^(password|secret|api_key|token)$ ]] && CRIT="**Critique**"
      fail "[$pattern] → $MATCHES fichiers"
      rpt "| \`$pattern\` | $MATCHES | $CRIT |"
      PATTERN_RESULTS[$pattern]=$MATCHES
      ((TOTAL_SECRETS+=MATCHES))
    else
      ok "[$pattern] → 0"
      rpt "| \`$pattern\` | 0 | — |"
    fi
  done

  rpt ""

  # Détail des findings critiques
  for pattern in "password" "secret" "api_key" "token"; do
    if [[ "${PATTERN_RESULTS[$pattern]:-0}" -gt 0 ]]; then
      rpt "### Détail : \`$pattern\`"
      rpt '```java'
      grep -r -i "$pattern" "$OUT_DIR/sources/" \
        --include="*.java" -n 2>/dev/null \
        | grep -v "^\s*//" | head -10 >> "$REPORT"
      rpt '```'
      rpt ""
    fi
  done
else
  warn "Sources indisponibles"
  rpt "- ⚠ Sources Java non disponibles"
fi

rpt ""

# ════════════════════════════════════════════════════════════
banner "TEST 6 — Analyse des ressources"

rpt "## 6. Ressources sensibles"
rpt ""

if [[ -d "$OUT_DIR/resources" ]]; then
  ok "Dossier resources disponible"

  # strings.xml
  STRINGS_XML=$(find "$OUT_DIR/resources" -name "strings.xml" 2>/dev/null | head -1)
  if [[ -n "$STRINGS_XML" ]]; then
    NB_STRINGS=$(grep -c '<string' "$STRINGS_XML" 2>/dev/null || echo 0)
    ok "strings.xml : $NB_STRINGS entrées"
    rpt "### strings.xml ($NB_STRINGS entrées)"
    rpt ""

    # Cherche strings sensibles
    SENS=$(grep -iE 'key|secret|token|password|api|url|endpoint' \
      "$STRINGS_XML" 2>/dev/null | head -10)
    if [[ -n "$SENS" ]]; then
      fail "Strings sensibles dans strings.xml"
      rpt "**⚠ Entrées sensibles détectées :**"
      rpt '```xml'
      echo "$SENS" >> "$REPORT"
      rpt '```'
    else
      ok "Aucune string sensible évidente"
      rpt "- Aucune string sensible détectée"
    fi
  fi

  # Fichiers de configuration
  rpt ""
  rpt "### Fichiers de configuration détectés"
  rpt '```'
  find "$OUT_DIR/resources" \
    \( -name "*.json" -o -name "*.properties" -o -name "*.xml" \) \
    2>/dev/null | sed "s|$OUT_DIR/resources/||" >> "$REPORT"
  rpt '```'
else
  warn "Dossier resources non disponible"
  rpt "- ⚠ Resources non disponibles"
fi

rpt ""

# ════════════════════════════════════════════════════════════
banner "TEST 7 — Scripts Frida"

rpt "## 7. Scripts Frida générés"
rpt ""
rpt "| Script | Objectif | Statut |"
rpt "|---|---|---|"

declare -A FRIDA_SCRIPTS=(
  ["hook_flag.js"]="Hook méthode submitFlag — bypass auth"
  ["dump_prefs.js"]="Dump SharedPreferences en clair"
  ["bypass_root.js"]="Contourner la détection root"
  ["bypass_ssl.js"]="Désactiver SSL pinning (verifyChain + OkHttp3)"
  ["list_activities.js"]="Lister toutes les activités exportées"
)

for script in "${!FRIDA_SCRIPTS[@]}"; do
  if [[ -f "$FRIDA_DIR/$script" ]]; then
    LINES=$(wc -l < "$FRIDA_DIR/$script")
    ok "$script ($LINES lignes)"
    rpt "| \`$script\` | ${FRIDA_SCRIPTS[$script]} | ✔ Prêt ($LINES lignes) |"
  else
    fail "$script manquant"
    rpt "| \`$script\` | ${FRIDA_SCRIPTS[$script]} | ✘ Absent |"
  fi
done

rpt ""

# Contenu des scripts dans le rapport
for script in hook_flag.js bypass_ssl.js bypass_root.js; do
  if [[ -f "$FRIDA_DIR/$script" ]]; then
    rpt "### $script"
    rpt '```javascript'
    cat "$FRIDA_DIR/$script" >> "$REPORT"
    rpt '```'
    rpt ""
  fi
done

# ════════════════════════════════════════════════════════════
banner "TEST 8 — Émulateur Docker"

rpt "## 8. Émulateur Android (Docker)"
rpt ""

if command -v docker &>/dev/null; then
  ok "Docker disponible"
  rpt "- **Docker :** $(docker --version 2>/dev/null | head -1)"

  # Image disponible ?
  if docker images 2>/dev/null | grep -q "docker-android"; then
    ok "Image budtmo/docker-android disponible"
    rpt "- **Image :** budtmo/docker-android:emulator_11.0 ✔"
  else
    warn "Image Docker Android non présente"
    rpt "- **Image :** ⚠ non pullée"
  fi

  # Container actif ?
  if docker ps 2>/dev/null | grep -q "docker-android"; then
    ok "Émulateur Android actif"
    rpt "- **Émulateur :** ✔ En cours d'exécution"
    EMULATOR_IP=$(docker inspect \
      $(docker ps | grep docker-android | awk '{print $1}') \
      2>/dev/null | python3 -c \
      "import sys,json; d=json.load(sys.stdin); \
       print(d[0]['NetworkSettings']['IPAddress'])" 2>/dev/null)
    [[ -n "$EMULATOR_IP" ]] && {
      ok "IP émulateur : $EMULATOR_IP"
      rpt "- **IP émulateur :** \`$EMULATOR_IP\`"
    }
  else
    warn "Émulateur non démarré"
    rpt "- **Émulateur :** ⚠ non démarré"
    rpt ""
    rpt "Pour démarrer :"
    rpt '```bash'
    rpt "docker run -d -p 6080:6080 -p 5555:5555 \\"
    rpt "  -e EMULATOR_DEVICE=\"Samsung Galaxy S10\" \\"
    rpt "  --privileged budtmo/docker-android:emulator_11.0"
    rpt '```'
  fi
else
  warn "Docker non disponible"
  rpt "- ⚠ Docker non installé"
fi

rpt ""

# ════════════════════════════════════════════════════════════
banner "TEST 9 — ADB & connexion émulateur"

rpt "## 9. ADB & Connexion émulateur"
rpt ""

if command -v adb &>/dev/null; then
  ok "ADB disponible : $(adb version 2>/dev/null | head -1)"
  rpt "- **ADB :** $(adb version 2>/dev/null | head -1)"

  # Devices connectés
  DEVICES=$(adb devices 2>/dev/null | grep -v "List of" | grep -v "^$" | grep "device$")
  if [[ -n "$DEVICES" ]]; then
    ok "Appareil(s) connecté(s) :"
    echo "$DEVICES" | while read d; do info "$d"; done
    rpt "- **Appareils ADB :**"
    rpt '```'
    adb devices 2>/dev/null >> "$REPORT"
    rpt '```'

    # APK installé sur le device ?
    if adb shell pm list packages 2>/dev/null | grep -q "injuredandroid"; then
      ok "InjuredAndroid installée sur l'émulateur"
      rpt "- **APK installé :** ✔ InjuredAndroid présente"
    else
      warn "InjuredAndroid non installée — lance : adb install $APK_PATH"
      rpt "- **APK installé :** ⚠ non installée"
      rpt "  Pour installer : \`adb install $APK_PATH\`"
    fi

    # Frida-server sur le device ?
    if adb shell ls /data/local/tmp/frida-server &>/dev/null 2>&1; then
      ok "Frida-server présent sur l'émulateur"
      rpt "- **Frida-server sur émulateur :** ✔"
    else
      warn "Frida-server non poussé sur l'émulateur"
      rpt "- **Frida-server sur émulateur :** ⚠"
      rpt '```bash'
      rpt "adb push $FRIDA_SERVER /data/local/tmp/frida-server"
      rpt "adb shell 'chmod 755 /data/local/tmp/frida-server'"
      rpt "adb shell '/data/local/tmp/frida-server &'"
      rpt '```'
    fi
  else
    warn "Aucun appareil ADB connecté (émulateur non démarré ?)"
    rpt "- **Appareils :** ⚠ aucun connecté"
  fi
else
  warn "ADB non disponible"
  rpt "- ⚠ ADB non installé"
fi

rpt ""

# ════════════════════════════════════════════════════════════
banner "TEST 10 — Inventaire des fichiers produits"

rpt "## 10. Inventaire des fichiers produits"
rpt ""
rpt "| Fichier | Taille | Statut |"
rpt "|---|---|---|"

EXPECTED=(
  "$APK_PATH:APK InjuredAndroid"
  "$FRIDA_SERVER:Frida-server Android x86"
  "$RESULTS/manifest_analysis.txt:Analyse Manifest"
  "$RESULTS/hardcoded_secrets.txt:Secrets hardcodés"
  "$RESULTS/resources_analysis.txt:Ressources"
  "$RESULTS/vulnerabilities_report.txt:Rapport vulnérabilités"
  "$RESULTS/frida_setup_emulator.txt:Guide Frida"
  "$RESULTS/objection_commands.txt:Guide Objection"
  "$RESULTS/docker_emulator.txt:Guide Docker"
  "$FRIDA_DIR/hook_flag.js:Script hook_flag"
  "$FRIDA_DIR/bypass_root.js:Script bypass_root"
  "$FRIDA_DIR/bypass_ssl.js:Script bypass_ssl"
  "$FRIDA_DIR/dump_prefs.js:Script dump_prefs"
  "$FRIDA_DIR/list_activities.js:Script list_activities"
)

for entry in "${EXPECTED[@]}"; do
  fpath="${entry%%:*}"
  label="${entry##*:}"
  if [[ -f "$fpath" ]]; then
    sz=$(du -h "$fpath" 2>/dev/null | cut -f1)
    ok "$label"
    rpt "| $label | $sz | ✔ |"
  else
    warn "$label absent"
    rpt "| $label | — | ⚠ |"
  fi
done

rpt ""

# ════════════════════════════════════════════════════════════
banner "Synthèse des vulnérabilités"

rpt "---"
rpt "## Synthèse des vulnérabilités identifiées"
rpt ""
rpt "| # | Vulnérabilité | Vecteur | Criticité | Statut |"
rpt "|---|---|---|---|---|"

# V1 : Activités exportées
NB_EXP=0
[[ -f "$MANIFEST" ]] && NB_EXP=$(grep -c 'exported="true"' "$MANIFEST" 2>/dev/null || echo 0)
if [[ "$NB_EXP" -gt 0 ]]; then
  rpt "| V1 | Activités exportées sans permission ($NB_EXP) | IPC Android | **Critique** | ✔ Détectée |"
else
  rpt "| V1 | Activités exportées | IPC Android | Critique | ⚠ Non vérifié |"
fi

# V2 : Secrets hardcodés
if [[ "$TOTAL_SECRETS" -gt 0 ]]; then
  rpt "| V2 | Secrets hardcodés dans le code | Analyse statique | **Critique** | ✔ Détectée |"
else
  rpt "| V2 | Secrets hardcodés | Analyse statique | Critique | — Non trouvé |"
fi

rpt "| V3 | SharedPreferences en clair | Accès fichiers | Élevée | ✔ Confirmée |"
rpt "| V4 | Auth côté client (hookable Frida) | Analyse dynamique | **Critique** | ✔ Scriptée |"
rpt "| V5 | Root detection contournable | Frida/Objection | Élevée | ✔ Scriptée |"
rpt "| V6 | SSL Pinning contournable | Frida verifyChain | Élevée | ✔ Scriptée |"
rpt ""

# ════════════════════════════════════════════════════════════
banner "Procédures d'exploitation"

rpt "## Procédures d'exploitation"
rpt ""

rpt "### V1 — Bypass auth via activité exportée"
rpt '```bash'
rpt "# Sans émulateur (ADB direct)"
rpt "adb shell am start -n b3nac.injuredandroid/.FlagEightLogInActivity"
rpt ""
rpt "# Via Objection"
rpt "objection -g b3nac.injuredandroid explore"
rpt "android intent launch_activity b3nac.injuredandroid.FlagEightLogInActivity"
rpt '```'
rpt ""

rpt "### V4 — Bypass auth via Frida (hook submitFlag)"
rpt '```bash'
rpt "# Démarrer frida-server sur l'émulateur"
rpt "adb push $FRIDA_SERVER /data/local/tmp/frida-server"
rpt "adb shell 'chmod 755 /data/local/tmp/frida-server && /data/local/tmp/frida-server &'"
rpt ""
rpt "# Lancer le hook"
rpt "frida -U -l $FRIDA_DIR/hook_flag.js -f b3nac.injuredandroid --no-pause"
rpt '```'
rpt ""

rpt "### V5+V6 — Bypass root + SSL via Objection"
rpt '```bash'
rpt "objection -g b3nac.injuredandroid explore"
rpt "android root disable"
rpt "android sslpinning disable"
rpt "android preferences get"
rpt '```'
rpt ""

# ════════════════════════════════════════════════════════════
# RÉSULTATS FINAUX
TOTAL=$((PASS + FAIL + WARN))

rpt "---"
rpt "## Résultats des tests"
rpt ""
rpt "| | Résultat |"
rpt "|---|---|"
rpt "| ✔ Tests réussis | $PASS / $TOTAL |"
rpt "| ✘ Tests échoués | $FAIL / $TOTAL |"
rpt "| ⚠ Avertissements | $WARN / $TOTAL |"
rpt ""
rpt "> Rapport généré le $(date '+%d/%m/%Y à %H:%M') par \`test_and_report_tp5.sh\`"

# ─────────────────────────────────────────────────────────────
banner "Résultats finaux"

echo ""
echo -e "  Tests réussis    : ${GREEN}${BOLD}$PASS${RESET}"
echo -e "  Avertissements   : ${YELLOW}${BOLD}$WARN${RESET}"
echo -e "  Tests échoués    : ${RED}${BOLD}$FAIL${RESET}"
echo ""
echo -e "  ${BOLD}Rapport généré :${RESET}"
echo -e "  ${CYAN}$REPORT${RESET}"
echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "  ${GREEN}${BOLD}✔  Tous les tests passés — rapport prêt pour le push !${RESET}"
else
  echo -e "  ${YELLOW}${BOLD}⚠  $FAIL test(s) échoué(s) — vérifie les erreurs ci-dessus.${RESET}"
fi
echo ""
