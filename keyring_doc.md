# Gestion sécurisée des mots de passe en R avec `keyring`

*Petit guide pratique — stockage, récupération, et intégration SMTP*

## Sommaire

- [1. Pourquoi keyring ?](#1-pourquoi-keyring-)
- [2. Installation](#2-installation)
- [3. Concepts : service, username, keyring](#3-concepts--service-username-keyring)
- [4. Utilisation courante](#4-utilisation-courante)
- [5. Backends selon l'OS](#5-backends-selon-los)
- [6. Bonnes pratiques](#6-bonnes-pratiques)
- [7. Dépannage](#7-dépannage)

## 1. Pourquoi keyring ?

Le package `keyring` permet de stocker mots de passe, tokens API et autres secrets dans le **gestionnaire natif de l'OS** plutôt qu'en clair dans un script ou un fichier `.Renviron`. Les secrets sont chiffrés par le système et protégés par la session utilisateur.

> ⛔ **À ne jamais faire :**
> - envoyer par mail un message d'erreur postgresql contenant vos identifiants (supprimer les informations confidentielles avant d'envoyer le message). Ça oblige l'administrateur à supprimer le compte et à le recréer et ça le met de mauvaise humeur.
> - écrire `password = "monMdp123"` en dur dans un script R (ou n'importe quel fichier destiné à être échangé) — les login et password doivent être ABSOLUMENT personnels.
> - écrire `password = "monMdp123"` en dur dans un script R versionné sur Git. Un secret poussé sur un dépôt reste dans l'historique même après suppression.

### Comparaison rapide

| Méthode | Sécurité | Portabilité |
|---|---|---|
| En dur dans le script | ❌ Nulle | ✅ |
| Variable `.Renviron` | ⚠️ Fichier en clair | ✅ |
| `keyring` | ✅ Chiffré par l'OS | ⚠️ Par machine/utilisateur |
| Coffre-fort externe (Vault, etc.) | ✅✅ | ✅ mais lourd |

## 2. Installation

```r
install.packages("keyring")
library(keyring)
```

Sous Linux, un backend Secret Service (GNOME Keyring, KDE Wallet…) doit être disponible ; sur une VM headless (serveur INRAE par exemple), voir la section [Backends](#5-backends-selon-los).

## 3. Concepts : service, username, keyring

Un secret est identifié par deux clés :

- `service` — nom logique du service (ex. `"smtp"`, `"argo_api"`, `"db_homer"`)
- `username` — identifiant associé (ex. votre adresse mail, un login)

Un `keyring` (au singulier, dans le vocabulaire du package) est un trousseau — un conteneur qui regroupe plusieurs secrets. Par défaut, keyring utilise le trousseau de la session utilisateur, ce qui suffit dans la majorité des cas.

## 4. Utilisation courante

### Stocker un mot de passe (une seule fois, en interactif)

```r
library(keyring)

#Créer votre trousseau avec keyring

keyring::keyring_create("mon_nom")

# Ouvre une fenêtre de saisie sécurisée — le mdp n'apparaît pas dans l'historique
####un mot de passe sécurisant le trousseau est demandé (le mot de passe maître), entrez votre mot de passe de ldap. Keyring crypte le trousseau.

####Puis on stocke les identifiants de connection à la base (ou aux bases) de données à laquelle on peut accéder.

#user/login
 keyring::key_set_with_value(
   service  = "db", #le nom du service associé au identifiants
   username = "login", # l'identifiant associé à ce que l'on veut garder secret (ici le login)
   password = "mon_login", # votre login/user
   keyring  = "mon_nom" #le nom du trousseau de clefs
 )
 
#password 
 keyring::key_set_with_value(
   service  = "db", #le nom du service associé au identifiants
   username = "pwd", # l'identifiant associé à ce que l'on veut garder secret (ici le mot de passe)
   password = "mon_pwd", # votre mot de passe
   keyring  = "mon_nom" #le nom du trousseau de clefs
 )
 
#host 
  keyring::key_set_with_value(
   service  = "db", # Le nom du service associé au identifiants
   username = "host", # L'identifiant associé à ce que l'on veut garder secret (ici le nom de l'hôte)
   password = "nom de l'hôte (serveur distant)", # Le nom du serveur qui héberge la base de données
   keyring  = "mon_nom" # Le nom du trousseau de clefs 
 )
 
#nom de la base de données 
   keyring::key_set_with_value(
   service  = "db", # Le nom du service associé au identifiants
   username = "base de données chevreuils", # L'identifiant associé à ce que l'on veut garder secret (ici le nom de la base de données)
   password = "nom de la base de données", # Le nom de la base de données
   keyring  = "mon_nom" # Le nom du trousseau de clefs 
 )
 
```
#####les lignes de commandes ci-dessus sont excécutées une seule fois puis suppimées

> ℹ️ `keyring_create()` ouvre un prompt masqué : le mot de passe n'est ni tapé dans la console, ni conservé dans `.Rhistory`.

### Récupérer un mot de passe dans un script
```r
mdp <- key_get(service="db","pwd",keyring ="mon_nom")
```
#####Ce qui donne pour une connection à une base de données  

```r
con<-dbConnect(Postgres(), host=key_get(service="db","host",keyring ="pwd"), dbname=key_get(service="db","base de données chavreuils",keyring ="pwd"), user=key_get(service="db","login",keyring ="pwd"), password=key_get(service="db","pwd",keyring ="pwd"))
```
### Lister les secrets enregistrés

```r
key_list()
key_list(service = "db")  # filtré
```

### Supprimer un secret

```r
key_delete(service = "db", username = "pwd")
```

### Stocker un mot de passe en mode non-interactif (scripts automatisés)

```r
# À éviter en production, mais utile pour un déploiement scripté
key_set_with_value(
  service  = "smtp",
  username = "ricky@anthropic.com",
  password = Sys.getenv("SMTP_PWD")  # variable d'env temporaire
)
```

## 5. Backends selon l'OS

| OS | Backend par défaut | Remarques |
|---|---|---|
| macOS | Keychain | Fonctionne immédiatement |
| Windows | Credential Store | Fonctionne immédiatement |
| Linux desktop | Secret Service (GNOME/KDE) | Nécessite un service `dbus` actif |
| Linux serveur / VM headless | — | Utiliser `backend_file` |

### Sur une VM sans environnement graphique

```r
# Backend basé sur un fichier chiffré, protégé par une passphrase
kb <- keyring::backend_file$new()
kb$keyring_create("homer")         # crée un trousseau nommé "homer"
kb$set("smtp", "ricky@anthropic.com")
mdp <- kb$get("smtp", "ricky@anthropic.com")
```

> ⚠️ **Attention VM :** avec `backend_file`, la passphrase du trousseau doit être fournie au moins une fois par session. Pour un cron entièrement non-attendu, il faut alors passer par une variable d'environnement injectée par le système d'orchestration (systemd, Ansible Vault…).

## 6. Bonnes pratiques

- Ne jamais commiter de mot de passe, ni dans un script, ni dans `.Renviron`, ni dans un YAML.
- Ajouter `.Renviron` et `.Rhistory` au `.gitignore` du projet.
- Nommer les services de façon parlante : `"argo_api"`, `"smtp_inrae"`, `"db_homer_prod"`.
- Documenter dans le README les `service`/`username` attendus pour que le pipeline se remonte facilement.
- Pour du multi-utilisateur sur un serveur partagé, préférer un backend fichier chiffré par projet plutôt que le trousseau système personnel.
- Faire tourner les secrets régulièrement (`key_delete()` puis `key_set()`).

## 7. Dépannage

### Erreur : `Error in b_dbus_get: Cannot open keyring` (Linux)

Le service Secret Service n'est pas disponible (VM sans session graphique). Basculer sur `backend_file` ou installer `gnome-keyring` + `dbus`.

### Le mot de passe est demandé à chaque session

Le trousseau se ferme automatiquement selon la politique OS. Sur macOS/Windows c'est très rare ; sur Linux, vérifier que le trousseau est bien déverrouillé au login.

### Vérifier qu'un secret existe sans le lire

```r
nrow(key_list(service = "smtp")) > 0
```

---

*Documentation officielle du package : `?keyring` ou [keyring.r-lib.org](https://keyring.r-lib.org/).*
