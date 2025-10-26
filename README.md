# DevOps Intern Final Assessment

**Auteur :** Khalid Salhi

**Date :** 25 Octobre 2025

---

Ce dépôt contient un petit pipeline DevOps complet et reproductible,

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


```
https://github.com/khalidsl/devops-intern-final
```

------

Prérequis (Linux recommandé)

- git
- docker
- nomad (optionnel, pour exécuter la job Nomad)
- docker-compose (optionnel, facilite Loki/Promtail)
- py (pour tester les scripts locaux / MLflow)

------

Instructions rapides

1) Tester Python localement

```bash
py hello.py
# => Hello, DevOps!
```

2) Tester le script système (Linux)

```bash
chmod +x scripts/sysinfo.sh
./scripts/sysinfo.sh

--- Informations système ---
Utilisateur courant:  user
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

5) Nomad

```bash
#Utilise 
chmod +x scripts/check_nomad.sh
./scripts/check_nomad.sh
#or 
# construire l'image
docker build -t devops-intern-final:latest .

#en démarrer nomad en mode dev 
nomad agent -dev &

#en lancer la job Nomad
nomad job run nomad/hello.nomad

# en vérifier le statut
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

Le script affiche les étapes (build, submit, wait) et `OK` et renvoyer le corps "Hello, DevOps!" 


6) Monitoring (Loki + Promtail)

Voir `monitoring/loki_setup.txt` et `monitoring/promtail-config.yml` pour les commandes Docker et la configuration Promtail.
  
# Comment l'architecture monitoring est implémentée

Le monitoring est basé sur trois composants principaux :

- **Loki** : stockage centralisé des logs, déployé en conteneur Docker avec configuration locale (`loki-local-config.yaml`). Les volumes nécessaires sont créés et montés pour la persistance.
- **Promtail** : agent de collecte des logs, déployé en conteneur Docker. Il lit les fichiers de log système (`/var/log/*.log`) et, si configuré, les logs Docker (`/var/lib/docker/containers/*/*-json.log`). La configuration est dans `promtail-config.yml`.
- **Grafana** : interface web pour visualiser et interroger les logs, déployée en conteneur Docker. La source de données Loki est provisionnée automatiquement.

Le tout est orchestré via `docker-compose.yml` :

- Les services sont définis avec leurs volumes et ports exposés.
- Les fichiers de configuration sont montés en lecture seule dans les conteneurs.
- Les volumes Docker assurent la persistance des données Loki et Grafana.

**Démarrage rapide** :

```bash
cd monitoring
docker compose up -d
```

Accédez à Grafana sur [http://127.0.0.1:3000](http://127.0.0.1:3000) (admin/admin).

Dans Grafana, onglet « Explore », sélectionnez la source de données Loki et lancez une requête comme :
```
{job=~".+"}
```
pour afficher tous les logs collectés.

Vous pouvez personnaliser la collecte en modifiant `promtail-config.yml` pour ajouter d'autres chemins ou labels.

###  MLflow Tracking

Un exemple de script MLflow est fourni dans `extra/mlflow/mlflow_example.py` :

```powershell
py -m pip install -r extra/mlflow/requirements.txt
py extra/mlflow/mlflow_example.py
```

Ce script crée une expérience MLflow et enregistre un run local :
```
MLflow run enregistré : <run_id>
```

Vous pouvez consulter les runs et les paramètres enregistrés dans le dossier `.mlruns` généré localement.

------

captures d'écran

quelques  captures d'écran  (stockées dans `docs/screenshots/`). 
