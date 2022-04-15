#!/usr/bin/env bash

# Modified from docs found at: https://docs.kasten.io/latest/install/other/kind.html

exists=false
for cluster in $(kind get clusters); do
    if [[ "$cluster" == "k10-demo" ]]; then
        exists=true
    fi
done
if [[ "$exists" == false ]]; then
    kind create cluster --name k10-demo --image kindest/node:v1.22.7
fi

SNAPSHOTTER_VERSION=v4.0.1

echo "Applying VolumeSnapshot CRDs"
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

echo "Creating Snapshot Controller"
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml

echo "Installing the CSI Hostpath Driver"
git clone https://github.com/kubernetes-csi/csi-driver-host-path.git

./csi-driver-host-path/deploy/kubernetes-1.22/deploy.sh

kubectl apply -f ./csi-driver-host-path/examples/csi-storageclass.yaml

kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

rm -rf csi-driver-host-path

echo "Installing Kasten"
kubectl create namespace kasten-io
helm repo add kasten https://charts.kasten.io/
helm install k10 kasten/k10 --namespace=kasten-io
kubectl annotate volumesnapshotclass csi-hostpath-snapclass k10.kasten.io/is-snapshot-class=true