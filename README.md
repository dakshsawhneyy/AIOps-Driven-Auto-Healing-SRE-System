# Multi-Cloud AIOps-Driven Auto-Healing SRE System

Modern microservices fail unpredictably — CPU spikes, memory leaks, traffic surges, and random pod crashes.
Traditional monitoring reacts **after** failure.
I wanted a system that detects problems early, understands them, and heals itself.

This project is my attempt to build that:
**A fully automated AIOps platform combining DevOps, SRE, Cloud, Kubernetes, and MLOps.**

<img width="1768" height="1236" alt="diagram-export-12-14-2025-1_55_47-PM" src="https://github.com/user-attachments/assets/8d8d5fcd-8241-47f0-8877-cfdd4704e65e" />

---

## The Problem

Microservices generate huge volumes of logs/metrics, but:
* failures are detected late
* alerts are noisy
* root cause is unclear
* engineers manually fix issues
* multi-cloud setups lack unified intelligence

I needed a way to:
* collect signals in real time
* understand what's normal vs abnormal
* predict incidents
* auto-heal workloads running on Kubernetes

---

## My Approach

I broke the solution into small phases:
1. **Create a real microservice environment that can break**
2. **Collect every signal (logs, metrics) from Kubernetes**
3. **Push data to AWS for AIOps processing**
4. **Normalize → label → train models → detect anomalies**
5. **Trigger healing actions automatically**
6. **Track incidents and visualize everything**

A simple idea:
**Make the system learn from chaos — then heal itself.**

---

## What I Built

### Multi-Cloud Architecture

* **AKS on Azure** for running the application
* <img width="1457" height="717" alt="image" src="https://github.com/user-attachments/assets/da6d6fa8-b106-44a5-9796-a557f9b71889" />
* **AWS** for AIOps pipeline (Kinesis, Lambda, S3, DynamoDB, SNS)
* 

### Data & Observability

* FluentBit shipping logs + metrics from AKS → AWS
* Real-time normalization Lambda
* Central S3 data lake (normalized / processed / training-data)
  <img width="1329" height="692" alt="image" src="https://github.com/user-attachments/assets/7660c67e-87bd-45d6-b91b-fcd829f58d1f" />
* Prometheus + Grafana for cluster-level dashboards
* CloudWatch for AWS service metrics

### Chaos Engineering

Created controlled failures:
* CPU stress
  <img width="893" height="642" alt="image" src="https://github.com/user-attachments/assets/08ea7dc7-603c-4852-ab05-abfa78407fac" />
* Memory leaks
  <img width="1492" height="470" alt="image" src="https://github.com/user-attachments/assets/658bc091-a51c-4f3a-994a-d56bfef2ff4c" />
* High traffic
  <img width="1090" height="525" alt="image" src="https://github.com/user-attachments/assets/5cb838e0-1108-4894-bbef-383a6722c78b" />
* Pod restarts
  These generated labeled training windows for anomaly detection.

### ML / Anomaly Detection
* Training dataset generator Lambda
* Isolation Forest models for CPU, memory, and traffic
  <img width="862" height="600" alt="image" src="https://github.com/user-attachments/assets/e770118f-5146-4c2d-98ee-6ddf0fc45100" />
* Models stored as `.pkl` in S3
* Inference Lambda running on real-time streams
* Severity scoring + incident classification

### Auto-Healing Engine
* SNS → Lambda alert workflow
* Auto-heal API deployed inside AKS
* Lambda securely contacting AKS using custom headers + secret
* Healing actions: scale pods, restart deployments, clear state
  <img width="1084" height="231" alt="image" src="https://github.com/user-attachments/assets/219731e6-afd8-420e-86b3-7d7e9ff0c5c5" />
* DynamoDB incident history

### Dashboards
* Prometheus → Grafana for cluster metrics
  <img width="1842" height="410" alt="image" src="https://github.com/user-attachments/assets/1313e4fc-698c-44e9-a6dd-355cb1f42bab" />
  <img width="1555" height="904" alt="34ea5d0a-cbc3-4f83-a2af-1dfc679be006" src="https://github.com/user-attachments/assets/06a677bf-db0e-4817-86d9-a037786f963f" />
* CloudWatch for AWS services
* <img width="1840" height="877" alt="51291f20-ba5f-40a9-8375-bb3e9e7fccca" src="https://github.com/user-attachments/assets/cf3cea88-177a-40ad-ba60-5797fc40282f" />
* <img width="1838" height="621" alt="3048cc12-6a9d-416d-b4a0-a4e700d5480a" src="https://github.com/user-attachments/assets/849fcf9d-edcb-474c-b4e7-626deae4c590" />
* Tracked error rates, latency, request counts, anomaly frequency
* <img width="1852" height="958" alt="e5a212c5-7894-4f35-b705-9c60a8de8514" src="https://github.com/user-attachments/assets/6bad2ef2-b22c-4221-9f52-07f55611c7c4" />

---

## Key Outcomes
* The system **detects anomalies** in real time
* Generates **incident alerts**
* Executes **automatic healing** on AKS workloads
* Creates **training datasets** from chaos experiments
* Trains and updates ML models
* Stores **incident history** for analysis
* Provides **multi-cloud observability**

Everything works end-to-end without manual involvement.

---
