#!/bin/bash
# shellcheck disable=SC1091
NS=default
POD=$(kubectl get pod -n $NS -l app=curl -o jsonpath='{.items..metadata.name}')
kubectl exec "$POD" -n $NS -- curl -s http://consumer:8001/hello

