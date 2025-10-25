#!/usr/bin/env python3
"""
Exemple MLflow simple : enregistre un run dummy.
"""
import mlflow


def main():
    mlflow.set_experiment("devops_intern_demo")
    with mlflow.start_run() as run:
        mlflow.log_param("example_param", "value1")
        mlflow.log_metric("accuracy", 0.95)
        print("MLflow run enregistré :", run.info.run_id)


if __name__ == '__main__':
    main()
