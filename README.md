# DevOps Intern Final Assessment

**Auteur :** Khalid Salhi

**Date :** 25 Octobre 2025

---

Ce dépôt contient un petit pipeline DevOps complet et reproductible, conçu pour l'évaluation finale.

Objectifs couverts : Git/GitHub, scripting Linux, Docker, CI/CD (GitHub Actions), déploiement Nomad et monitoring (Grafana Loki + Promtail).

Structure du projet

```
devops-intern-final/
├─ README.md
├─ hello.py
├─ scripts/sysinfo.sh
├─ Dockerfile
├─ .github/workflows/ci.yml
├─ nomad/hello.nomad
├─ monitoring/loki_setup.txt
├─ monitoring/promtail-config.yml
└─ extra/mlflow/
   ├─ mlflow_example.py
   └─ requirements.txt
```

Badge CI (exemple - mettez à jour le chemin avec votre utilisateur/repo) :

```
![CI](https://github.com/khalidsl/devops-intern-final/actions/workflows/ci.yml/badge.svg)
```

IMPORTANT : remplacez `khalidsl/devops-intern-final` par votre `GITHUB_USER/REPO` après le push pour que le badge affiche l'état réel.

------

Prérequis (Linux recommandé)

- git
- docker
- nomad (optionnel, pour exécuter la job Nomad)
- docker-compose (optionnel, facilite Loki/Promtail)
- python3 (pour tester les scripts locaux / MLflow)

------

Instructions rapides

1) Tester Python localement

```bash
python3 hello.py
# => Hello, DevOps!
```

2) Tester le script système (Linux)

```bash
chmod +x scripts/sysinfo.sh
./scripts/sysinfo.sh
--- Informations système ---
Utilisateur courant: khalid
Date actuelle: Sat Oct 25 10:58:59 +01 2025
\nUtilisation des disques (df -h):
Filesystem                                Size  Used Avail Use% Mounted on
none                                      1.9G     0  1.9G   0% /usr/lib/modules/6.6.87.2-microsoft-standard-WSL2
none                                      1.9G  4.0K  1.9G   1% /mnt/wsl
none                                      1.9G  776K  1.9G   1% /mnt/wsl/docker-desktop/shared-sockets/host-services
/dev/sdd                                 1007G   57M  956G   1% /mnt/wsl/docker-desktop/docker-desktop-user-distro
drivers                                   476G  460G   17G  97% /usr/lib/wsl/drivers
/dev/sdf                                 1007G  2.2G  954G   1% /
none                                      1.9G  284K  1.9G   1% /mnt/wslg
none                                      1.9G     0  1.9G   0% /usr/lib/wsl/lib
rootfs                                    1.9G  2.7M  1.9G   1% /init
none                                      1.9G  528K  1.9G   1% /run
none                                      1.9G     0  1.9G   0% /run/lock
none                                      1.9G     0  1.9G   0% /run/shm
none                                      1.9G   76K  1.9G   1% /mnt/wslg/versions.txt
none                                      1.9G   76K  1.9G   1% /mnt/wslg/doc
C:\                                       476G  460G   17G  97% /mnt/c
/dev/loop0                                482M  482M     0 100% /mnt/wsl/docker-desktop/cli-tools
tmpfs                                     1.9G  4.0K  1.9G   1% /run/user/1000
tmpfs                                     1.9G  4.0K  1.9G   1% /run/user/0
C:\Program Files\Docker\Docker\resources  476G  460G   17G  97% /Docker/host
```

3) Docker

```bash
docker build -t devops-intern-final:latest .
docker run --rm devops-intern-final:latest 
Hello, DevOps!
```

4) CI/CD (GitHub Actions)

- Le fichier `.github/workflows/ci.yml` exécute `python hello.py` et `scripts/sysinfo.sh` à chaque push.
- Pushez ce dépôt sur GitHub et vérifiez l'onglet Actions.

5) Nomad

```bash
#Utilise 
chmod +x scripts/check_nomad.sh
./scripts/check_nomad.sh
#or 
# construire l'image
docker build -t devops-intern-final:latest .

# démarrer nomad en mode dev (si non déjà lancé)
nomad agent -dev &

# lancer la job Nomad
nomad job run nomad/hello.nomad

# vérifier le statut
nomad job status hello
``` 

Smoke tests

Des scripts de vérification (smoke-tests) ont été ajoutés dans le dossier `scripts/` pour valider rapidement le pipeline local :

- `scripts/check_nomad.sh` (bash/WSL) — reconstruit l'image, soumet la job Nomad, attend qu'une allocation soit RUNNING puis effectue une requête HTTP sur l'adresse dynamique.
- `scripts/check_nomad.ps1` (PowerShell) — équivalent pour Windows.

Exécution

PowerShell (Windows) :

```powershell
.\scripts\check_nomad.ps1
```

Bash / WSL :

```bash
chmod +x scripts/check_nomad.sh
./scripts/check_nomad.sh
```

Pré-requis

- Nomad doit être accessible (si vous utilisez le conteneur Nomad, assurez-vous qu'il a `/var/run/docker.sock` monté afin d'utiliser les images locales).
- Docker doit être installé et le démon actif.

Sortie attendue

Le script affiche les étapes (build, submit, wait) et doit finir par afficher `OK` et renvoyer le corps "Hello, DevOps!" si tout fonctionne.



6) Monitoring (Loki + Promtail)

Voir `monitoring/loki_setup.txt` et `monitoring/promtail-config.yml` pour les commandes Docker et la configuration Promtail.

7) Bonus — MLflow

```bash
python3 -m pip install -r extra/mlflow/requirements.txt
python3 extra/mlflow/mlflow_example.py
```

Le script enregistrera un run MLflow local et affichera l'ID du run.

------

Support & captures d'écran

Voici quelques exemples de captures d'écran utiles (stockées dans `docs/screenshots/`). Remplacez-les par vos propres images réelles :


