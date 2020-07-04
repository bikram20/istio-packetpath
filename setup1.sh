#!/usr/bin/bash

for cluster in cluster1 
do
   # kind
   kind create cluster --name $cluster --config ${cluster}.yaml
   
   # metallb
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
   kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
   kubectl apply -f ${cluster}.metallb

   # istio
   istioctl install --set profile=demo
   kubectl label namespace default istio-injection=enabled
   
   # bookinfo app
   kubectl apply -f istio-1.6.4/samples/bookinfo/platform/kube/bookinfo.yaml
   kubectl apply -f istio-1.6.4/samples/bookinfo/networking/bookinfo-gateway.yaml

   # Run manually. Wait for services to come up.
   sleep 60
   kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
   #ports
   export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
   export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
   
   export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
   echo $GATEWAY_URL
   echo http://$GATEWAY_URL/productpage
   
   # Apply forwarding to all versions
   kubectl apply -f istio-1.6.4/samples/bookinfo/networking/destination-rule-all.yaml
   
done
