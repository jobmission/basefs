#!/usr/bin/env bash

kubectl create -f applications/tigera-operator.yaml
kubectl apply -f applications/custom-resources.yaml