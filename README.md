# Helm chart for [kube-ingress-aws-controller](https://github.com/zalando-incubator/kube-ingress-aws-controller)

[![Build Status](https://travis-ci.org/baez90/kube-ingress-aws-controller-helm.svg?branch=master)](https://travis-ci.org/baez90/kube-ingress-aws-controller-helm)

- [Helm chart for kube-ingress-aws-controller](#helm-chart-for-kube-ingress-aws-controller)
  - [Helm registry](#helm-registry)
  - [Deployment](#deployment)
    - [Minimal](#minimal)
    - [Other namespace than `default`](#other-namespace-than-default)
    - [Enable RBAC](#enable-rbac)
    - [Enable prometheus-operator](#enable-prometheus-operator)
    - [Enable kube2iam](#enable-kube2iam)
    - [Debugging](#debugging)
    - [Enable `ingress.class` annotation handling](#enable-ingressclass-annotation-handling)
    - [Deploy with `values.yaml` file](#deploy-with-valuesyaml-file)
  - [Development](#development)

## Helm registry

The chart is available at the [Quay.io registry](https://quay.io/application/baez/kube-ingress-aws-controller?tab=description).

To be able to install the chart you will need the [registry plugin](https://github.com/app-registry/appr-helm-plugin).
Please follow the install guide in the GitHub repository.

## Deployment

### Minimal

The minimal deployment of this chart looks like this:

- install the Helm client
- install the Helm registry plugin
- run the following snippet and adjust the placeholders for **ingressController.awsRegion**

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

### Enable [RBAC](https://kubernetes.io/docs/admin/authorization/rbac/)

Role-Based Access Control (“RBAC”) is stable since Kubernetes 1.8 and is part of the Kubernetes best practices.
This Helm chart includes manifests for all required resources but does **not** deploy them by default.
If you have RBAC enabled in your Kubernetes cluster you need the following additional resources deployed:

- ClusterRole
- ClusterRoleBinding
- ServiceAccount

This is done by passing `--set rbac.create=true` to the `helm` CLI like this:

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set rbac.create=true \
  "<your release name e.g. kube-ingress-aws-controller>"
```

There are additional values you can override if you want to customize e.g. the name of the `ServiceAccount`.
The following variables can be overridden:

| Variable                      | Default value          |
| ----------------------------- | ---------------------- |
| `rbac.svcAccountName`         | aws-ingress-controller |
| `rbac.svcAccountNamespace`    | kube-system            |
| `rbac.clusterRoleName`        | aws-ingress-controller |
| `rbac.clusterRoleBindingName` | aws-ingress-controller |

### Enable [prometheus-operator](https://github.com/coreos/prometheus-operator)

Prometheus-Operator is project that deploys [Prometheus](https://prometheus.io/) to your Kubernetes cluster.

_Note: there's also a [Helm chart](https://github.com/coreos/prometheus-operator/tree/master/helm) available for Prometheus-Operator._

To notify Prometheus-Operator that it should collect the metrics of Skipper the following additional resources are required:

- ServiceMonitor

This helm chart includes the required manifest but does **not** deploy it by default.
To enable support for Prometheus-Operator add the flat `--set prometheusOperator.enable=true` to your `helm` CLI like this:

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set prometheusOperator.enable=true \
  "<your release name e.g. kube-ingress-aws-controller>"
```

There are a few more configuration options available you can pass to the CLI if required:

| Variable                                   | Default value               | Description                                                                                                         |
| ------------------------------------------ | --------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `prometheusOperator.jobLabel`              | kube-ingress-aws-controller | Label of the Prometheus job                                                                                         |
| `prometheusOperator.monitorName`           | kube-aws-ingress-metrics    | Name of the `ServiceMonitor` resource                                                                               |
| `prometheusOperator.namespace`             | monitoring                  | Namespace where your Prometheus-Operator is deployed                                                                |
| `prometheusOperator.scrapeInterval`        | 30s                         | Interval how often Prometheus will collect metrics                                                                  |
| `prometheusOperator.labels[]`              | prometheus: kube-prometheus | Set of labels to add to the `ServiceMonitor` the default value reflects the default selector or Prometheus-Operator |
| `prometheusOperator.endpoint.name`         | skipper-metrics             | Name of the port used in the `DaemonSet`, `Service` and `ServiceMonitor`                                            |
| `prometheusOperator.endpoint.externalPort` | 9911                        | Port used by the `Service` to publish the metrics port                                                              |

### Enable [kube2iam](https://github.com/jtblin/kube2iam)

Kube2iam delegates AWS roles to pods by redirecting calls to the AWS EC2 metadata API to a local container which resolves temporary credentials for the required role.
By using kube2iam it's possible to keep the permissions of your Kubernetes worker nodes at a bare minimum and delegate the required permissions e.g. for creating ALBs only to the pods that require them.

**kube-ingress-aws-controller** needs the following AWS permissions:

```json
{
  "Effect": "Allow",
  "Action": [
    "acm:ListCertificates",
    "acm:DescribeCertificate",
    "autoscaling:DescribeAutoScalingGroups",
    "autoscaling:AttachLoadBalancers",
    "autoscaling:DetachLoadBalancers",
    "autoscaling:DetachLoadBalancerTargetGroups",
    "autoscaling:AttachLoadBalancerTargetGroups",
    "autoscaling:DescribeLoadBalancerTargetGroups",
    "cloudformation:*",
    "elasticloadbalancing:*",
    "elasticloadbalancingv2:*",
    "ec2:DescribeInstances",
    "ec2:DescribeSubnets",
    "ec2:DescribeSecurityGroups",
    "ec2:DescribeRouteTables",
    "ec2:DescribeVpcs",
    "iam:GetServerCertificate",
    "iam:ListServerCertificates"
  ],
  "Resource": [
    "*"
  ]
}
```

To create the required role with the `aws` CLI save the policy above as `policy-document.json` and the following JSON as `trust-policy.json`:

```json
{
 "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "<ARN of your worker node role>"
      },
      "Action":"sts:AssumeRole"
    }
  ]
}
```

_Note: the trust policy is based on a KOPS deployment where every worker gets a worker role assigned by default. If you're using a different kind of deployment make sure that the `Principal` includes your Kubernetes worker node role!_

Run this bash snippet to create the required role:

```bash
ROLE_NAME="<Name of your role e.g. SkipperIngress>"
INSTANCE_PROFILE_NAME="Name of the instance profile e.g. EC2-SkipperIngress"

aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json
aws iam put-role-policy --role-name $ROLE_NAME --policy-name ExternalDNS-Permissions-Policy --policy-document file://policy-document.json
aws iam create-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME
aws iam add-role-to-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --role-name $ROLE_NAME
```

To assign this role to Skipper you will need the ARN of your previously created role.
To get the role execute the following snippet:

```bash
aws iam get-role --role-name $ROLE_NAME | jq -C ".Role.Arn" -r
```

This Helm chart includes support for kube2iam but it is disabled by default.
To deploy **kube-ingress-aws-controller** with kube2iam support add the flag `--set kube2iam.awsArn=<your role ARN>` to the `helm` CLI like this:

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set kube2iam.awsArn="<your AWS ARN goes here>" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

### Debugging

Sometimes something is just going wrong and you have no clue what's happening.
You can set the log level to `DEBUG` to get more insights by adding the flat `--set skipper.logLevel="DEBUG"` to the `helm` CLI like this:

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set skipper.logLevel="DEBUG" \
    "kube-ingress-aws-controller" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

The available log levels are:

- `ERROR`
- `WARN`
- `INFO`
- `DEBUG`

### Enable `ingress.class` annotation handling

If you want to split the traffic to different Skipper deployments you can define the value `skipper.ingressClass` which will enable the built-in support of Skipper to parse the pod annotation `kubernetes.io/ingress.class`.

Pass the flag `--set skipper.ingressClass=skipper-prod` to the `helm` CLI like this

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set skipper.ingressClass="skipper-prod" \
    "kube-ingress-aws-controller" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

To enable the parsing support and force Skipper to filter for pods with the annotation:

```yaml
kubernetes.io/ingress.class: skipper-prod
```

### Deploy with `values.yaml` file

If you don't want to pass all options via `--set` you can also copy the shipped `./kube-ingress-aws-controller/values.yaml`, adopt it and pass it to the `helm` CLI like this:

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    -f my-values.yaml \
    "<your release name e.g. kube-ingress-aws-controller>"
```

## Development

If you add functionality to this chart please check if the following validation is running correctly:

```bash
helm lint \
    --set kube2iam.awsArn="arn:aws:iam::$(uuidgen | cut -d '-' -f 1):role/SkipperIngress" \
    --set skipper.ingressClass=skipper \
    --set skipper.logLevel=INFO \
    --set prometheusOperator.enable=true \
    --set rbac.create=true \
    kube-ingress-aws-controller/
```

or if you have Kubernetes with installed Tiller available:

```bash
helm install \
    --dry-run \
    --debug \
    --set kube2iam.awsArn="arn:aws:iam::$(uuidgen | cut -d '-' -f 1):role/SkipperIngress" \
    --set skipper.ingressClass=skipper \
    --set skipper.logLevel=INFO \
    --set prometheusOperator.enable=true \
    --set rbac.create=true \
    kube-ingress-aws-controller/
```