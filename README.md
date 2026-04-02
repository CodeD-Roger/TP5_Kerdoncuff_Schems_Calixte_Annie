# TP5_Kerdoncuff_Schems_Calixte_Annie — Cybersécurité Android IoT

**Auteur :** Kerdoncuff Schems & Calixte Annie
**Date :** 02 avril 2026
**Cours :** Cybersécurité IoT TP5

## Description

Reverse engineering d'une application Android IoT vulnérable (InjuredAndroid).
Analyse statique avec JADX, instrumentation dynamique avec Frida et Objection,
émulation via Docker Android.

## Contenu

| Fichier/Dossier | Description |
|---|---|
| `install_tp5.sh` | Installation complète (JADX, Frida, Objection, Docker) |
| `test_and_report_tp5.sh` | Tests automatisés + génération du rapport |
| `frida-scripts/` | Scripts Frida (hook, bypass root, bypass SSL, dump prefs) |
| `results/` | Résultats d'analyse (manifest, secrets, vulnérabilités) |
| `RAPPORT_TP5.md` | Rapport d'analyse complet |

## Utilisation

```bash
# Étape 1 — Installation
chmod +x install_tp5.sh
sudo ./install_tp5.sh

# Étape 2 — Tests et rapport
chmod +x test_and_report_tp5.sh
sudo ./test_and_report_tp5.sh
```

## Vulnérabilités identifiées

| # | Vulnérabilité | Criticité |
|---|---|---|
| V1 | 7 activités exportées sans permission | Critique |
| V2 | Secrets hardcodés (token×40, firebase×363) | Critique |
| V3 | SharedPreferences en clair | Élevée |
| V4 | Authentification côté client hookable | Critique |
| V5 | Root detection contournable | Élevée |
| V6 | SSL Pinning contournable | Élevée |

## Prérequis

```bash
sudo apt install default-jdk adb docker.io python3-pip
pip3 install frida frida-tools objection
```

> Finalité pédagogique et défensive uniquement — VM isolée obligatoire.
