# Multi-Cloud AIOps-Driven Auto-Healing SRE System

## Overview

Modern microservices fail unpredictably — CPU spikes, memory leaks, traffic surges, and random pod crashes.
Traditional monitoring reacts **after** failure.
I wanted a system that detects problems early, understands them, and heals itself.

This project is my attempt to build that:
**A fully automated AIOps platform combining DevOps, SRE, Cloud, Kubernetes, and MLOps.**

*(image here)*

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
* **AWS** for AIOps pipeline (Kinesis, Lambda, S3, DynamoDB, SNS)

### Data & Observability

* FluentBit shipping logs + metrics from AKS → AWS
* Real-time normalization Lambda
* Central S3 data lake (normalized / processed / training-data)
* Prometheus + Grafana for cluster-level dashboards
* CloudWatch for AWS service metrics

### Chaos Engineering

Created controlled failures:

* CPU stress
* Memory leaks
* High traffic
* Pod restarts
  These generated labeled training windows for anomaly detection.

### ML / Anomaly Detection

* Training dataset generator Lambda
* Isolation Forest models for CPU, memory, and traffic
* Models stored as `.pkl` in S3
* Inference Lambda running on real-time streams
* Severity scoring + incident classification

### Auto-Healing Engine

* SNS → Lambda alert workflow
* Auto-heal API deployed inside AKS
* Lambda securely contacting AKS using custom headers + secret
* Healing actions: scale pods, restart deployments, clear state
* DynamoDB incident history

*(image of architecture here)*

### Dashboards

* Prometheus → Grafana for cluster metrics
* CloudWatch for AWS services
* Tracked error rates, latency, request counts, anomaly frequency

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
