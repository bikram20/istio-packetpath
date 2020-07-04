#!/usr/bin/bash

for cluster in cluster0
do
   # kind
   kind create cluster --name $cluster --config ${cluster}.yaml
   
   # metallb
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
   kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
   kubectl apply -f ${cluster}.metallb

   # bookinfo app
   kubectl apply -f istio-1.6.4/samples/bookinfo/platform/kube/bookinfo.yaml
   kubectl expose service productpage --type=LoadBalancer --name=productpage-ext

done

