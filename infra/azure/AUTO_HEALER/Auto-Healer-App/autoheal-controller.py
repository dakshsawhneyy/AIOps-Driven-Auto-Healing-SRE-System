from fastapi import FastAPI
from kubernetes import client, config

app = FastAPI()

# Load in-cluster config
config.load_incluster_config()
k8s = client.AppsV1Api()
core = client.CoreV1Api()

@app.post("/heal/cpu")
def scale_backend():
    k8s.patch_namespaced_deployment_scale(
        name="backend-deployment",
        namespace="default",
        body={"spec": {"replicas": 4}}
    )
    return {"status": "scaled backend to 4 replicas"}

@app.post("/heal/memory")
def restart_pod():
    pods = core.list_namespaced_pod("default", label_selector="app=backend").items
    if pods:
        core.delete_namespaced_pod(pods[0].metadata.name, "default")
        return {"status": f"restarted pod {pods[0].metadata.name}"}
    return {"status": "no pod found"}

@app.post("/heal/traffic")
def scale_frontend():
    k8s.patch_namespaced_deployment_scale(
        name="frontend-deployment",
        namespace="default",
        body={"spec": {"replicas": 5}}
    )
    return {"status": "scaled frontend to 5 replicas"}