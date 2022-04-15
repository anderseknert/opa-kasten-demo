# POC - OPA policy enforcement for Kasten

## Policies

In order to test policy against Kasten manifests without a kube cluster running,
the [kube-review](https://github.com/anderseknert/kube-review) tool may be used
to transform Kubernetes manifests into AdmissionReview objects, just like they would
be sent from the Kubernetes API server for admission control:

```shell
kube-review create manifests/policy.yaml \
| opa eval --format pretty --stdin-input --data policy/policy.rego data.policy.deny
```