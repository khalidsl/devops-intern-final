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
```

3) Docker

```bash
docker build -t devops-intern-final:latest .
docker run --rm devops-intern-final:latest
```

4) CI/CD (GitHub Actions)

- Le fichier `.github/workflows/ci.yml` exécute `python hello.py` et `scripts/sysinfo.sh` à chaque push.
- Pushez ce dépôt sur GitHub et vérifiez l'onglet Actions.

5) Nomad

```bash
# construire l'image
docker build -t devops-intern-final:latest .

# démarrer nomad en mode dev (si non déjà lancé)
nomad agent -dev &

# lancer la job Nomad
nomad job run nomad/hello.nomad

# vérifier le statut
nomad job status hello
``` 

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

Ajoutez vos captures d'écran sous un dossier `screenshots/` si nécessaire.

Bonne chance pour l'évaluation !
