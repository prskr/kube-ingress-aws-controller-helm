# Helm chart for [kube-ingress-aws-controller](https://github.com/zalando-incubator/kube-ingress-aws-controller)

## Deployment

### Minimal

The minimal deployment of this chart looks like this:

* check out this repository
* change your working directory to the repository root
* run the following snippet and adjust the placeholders for **ingressController.awsRegion**

```bash
helm upgrade \
    --install \
    --wait \
    --set ingressController.awsRegion="<your AWS region e.g. us-east-1>" \
    "kube-ingress-aws-controller" \
    kube-ingress-aws-controller/
```

### Other namespace than `default`

To deploy the ingress controller to a specific namespace run it like this and adjust the **--namespace** value:

```bash
helm upgrade \
    --install \
    --wait \
    --set ingressController.awsRegion="<your AWS region e.g. us-east-1>" \
    --namespace "<your-namespace-goes-here>" \
    "kube-ingress-aws-controller" \
    kube-ingress-aws-controller/
```

### Enable `rbac`

```bash
helm upgrade \
    --install \
    --wait \
    --set ingressController.awsRegion="<your AWS region e.g. us-east-1>" \
    --set rbac.enable=true \
    --namespace "<your-namespace-goes-here>" \
    "kube-ingress-aws-controller" \
    kube-ingress-aws-controller/
```

### Enable [prometheus-operator](https://github.com/coreos/prometheus-operator)

```bash
helm upgrade \
    --install \
    --wait \
    --set ingressController.awsRegion="<your AWS region e.g. us-east-1>" \
    --set prometheusOperator.enable=true \
    --namespace "<your-namespace-goes-here>" \
    "kube-ingress-aws-controller" \
    kube-ingress-aws-controller/
```

### Enable [kube2iam](https://github.com/jtblin/kube2iam)

```bash
helm upgrade \
    --install \
    --wait \
    --set ingressController.awsRegion="<your AWS region e.g. us-east-1>" \
    --set kube2iam.enable=true \
    --set kube2iam.awsArn="<your AWS ARN goes here>" \
    --namespace "<your-namespace-goes-here>" \
    "kube-ingress-aws-controller" \
    kube-ingress-aws-controller/
```

## Debugging

```bash
helm upgrade \
    --install \
    --wait \
    --set ingressController.awsRegion="<your AWS region e.g. us-east-1>" \
    --set skipper.logLevel="DEBUG" \
    --namespace "<your-namespace-goes-here>" \
    "kube-ingress-aws-controller" \
    kube-ingress-aws-controller/
```

## Validation

```bash
helm lint --set kube2iam.enable=true,prometheusOperator.enable=true,rbac.enable=true kube-ingress-aws-controller/
```