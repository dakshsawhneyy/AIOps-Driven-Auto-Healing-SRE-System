from fastapi import FastAPI, Header, HTTPException, Depends
from kubernetes import client, config
import os

app = FastAPI()

# Load in-cluster config
config.load_incluster_config()
k8s = client.AppsV1Api()
core = client.CoreV1Api()

API_KEY = os.environ["API_KEY"]

# Send a correct api key along with request
def auth(x_api_key: str = Header(None)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")


@app.post("/heal/cpu", dependencies=[Depends(auth)])
def scale_backend():
    k8s.patch_namespaced_deployment_scale(
        name="backend-deployment",
        namespace="default",
        body={"spec": {"replicas": 4}}
    )
    return {"status": "scaled backend to 4 replicas"}


@app.post("/heal/memory", dependencies=[Depends(auth)])
def restart_pod():
    pods = core.list_namespaced_pod("default", label_selector="app=backend").items
    if pods:
        core.delete_namespaced_pod(pods[0].metadata.name, "default")
        return {"status": f"restarted pod {pods[0].metadata.name}"}
    return {"status": "no pod found"}


@app.post("/heal/traffic", dependencies=[Depends(auth)])
def scale_frontend():
    k8s.patch_namespaced_deployment_scale(
        name="frontend-deployment",
        namespace="default",
        body={"spec": {"replicas": 5}}
    )
    return {"status": "scaled frontend to 5 replicas"}