# Helm chart for [kube-ingress-aws-controller](https://github.com/zalando-incubator/kube-ingress-aws-controller)

## Deployment

## Helm registry

The chart is available at the [Quay.io registry](https://quay.io/application/baez/kube-ingress-aws-controller?tab=description).

To be able to install the chart you will need the [registry plugin](https://github.com/app-registry/appr-helm-plugin).
Please follow the install guide in the GitHub repository.

### Minimal

The minimal deployment of this chart looks like this:

* check out this repository
* change your working directory to the repository root
* run the following snippet and adjust the placeholders for **ingressController.awsRegion**

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
  --install \
  --wait \
  --set ingressController.awsRegion="<AWS region>" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

### Other namespace than `default`

To deploy the ingress controller to a specific namespace run it like this and adjust the **--namespace** value:

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
  --install \
  --wait \
  --set ingressController.awsRegion="<AWS region>" \
  --namespace "<your-namespace-goes-here>" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

### Enable `rbac`

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set rbac.enable=true \
    --namespace "<your-namespace-goes-here>" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

### Enable [prometheus-operator](https://github.com/coreos/prometheus-operator)

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set prometheusOperator.enable=true \
    --namespace "<your-namespace-goes-here>" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

### Enable [kube2iam](https://github.com/jtblin/kube2iam)

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set kube2iam.enable=true \
    --set kube2iam.awsArn="<your AWS ARN goes here>" \
    --namespace "<your-namespace-goes-here>" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

## Debugging

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set skipper.logLevel="DEBUG" \
    --namespace "<your-namespace-goes-here>" \
    "kube-ingress-aws-controller" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

## Validation

```bash
helm lint \
    --set kube2iam.enable=true \
    --set prometheusOperator.enable=true \
    --set rbac.enable=true \
    kube-ingress-aws-controller/
```