docker build -t acr73061.azurecr.io/fastapi-app:latest .
docker push acr73061.azurecr.io/fastapi-app:latest
az aks get-credentials --admin --name fastapi-aks-cluster --resource-group fastapi-resource-group
kubectl get nodes
cd infrastructure/kubernetes/
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml 