from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def read_root():
    return {"message": "Hello, This is FastAPI deployed on Azure Kubernetes Service (AKS)! version 2"}