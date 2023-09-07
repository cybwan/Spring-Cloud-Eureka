#!/bin/bash
# shellcheck disable=SC1091
NS=default
POD=$(kubectl get pods --selector app=eureka-service -n $NS --no-headers | grep 'Running' | awk 'NR==1{print $1}')
kubectl port-forward "$POD" -n "$NS" 8761:8761 --address 0.0.0.0

