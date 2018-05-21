# Helm chart for [kube-ingress-aws-controller](https://github.com/zalando-incubator/kube-ingress-aws-controller)

[![Build Status](https://travis-ci.org/baez90/kube-ingress-aws-controller-helm.svg?branch=master)](https://travis-ci.org/baez90/kube-ingress-aws-controller-helm)

- [Helm chart for kube-ingress-aws-controller](#helm-chart-for-kube-ingress-aws-controllerhttps---githubcom-zalando-incubator-kube-ingress-aws-controller)
  - [Disclaimer](#disclaimer)
  - [Helm registry](#helm-registry)
  - [Deployment](#deployment)
    - [Minimal](#minimal)
    - [Other namespace than `default`](#other-namespace-than-default)
    - [Enable RBAC](#enable-rbachttps---kubernetesio-docs-admin-authorization-rbac)
    - [Enable kube2iam](#enable-kube2iamhttps---githubcom-jtblin-kube2iam)
    - [Passing extra args to the controller](#passing-extra-args-to-the-controller)
    - [Deploy with `values.yaml` file](#deploy-with-valuesyaml-file)
  - [Development](#development)

## Disclaimer

**This Helm chart is still under development and is not considered stable (yet)!**

There might be breaking changes which are applied without any further notice and that **might** harm also some kittens!

**History:**

- Moved Skipper part of this chart to [second Repository](https://github.com/baez90/skipper-helm)
- Renamed `rbac.enable` to `rbac.create`
- Renamed `prometheusOperator.enable` to `prometheusOperator.create`

If you encounter any errors feel free to leave me an Issue and I'll try to help as good and fast as I can but I'm maintaining this chart mostly in my spare time so please be kind :wink:

Furthermore I'm trying to keep the docs as up-to-date and detailed as I can but there might be some details that I don't (and probably won't) cover in this docs.
You can always have a look at the [`values.yaml`](kube-ingress-aws-controller/values.yaml) file to see all config options.

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
|-------------------------------|------------------------|
| `rbac.svcAccountName`         | aws-ingress-controller |
| `rbac.svcAccountNamespace`    | kube-system            |
| `rbac.clusterRoleName`        | aws-ingress-controller |
| `rbac.clusterRoleBindingName` | aws-ingress-controller |

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
ROLE_NAME="<Name of your role e.g. Kube-Ingress-AWS-Controller>"
INSTANCE_PROFILE_NAME="Name of the instance profile e.g. EC2-Kube-Ingress-AWS-Controller"

aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json
aws iam put-role-policy --role-name $ROLE_NAME --policy-name Kube-Ingress-Aws-Controller-Policy --policy-document file://policy-document.json
aws iam create-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME
aws iam add-role-to-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --role-name $ROLE_NAME
```

To assign this role to Kube-Ingress-AWS-Controller you will need the ARN of your previously created role.
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

### Passing extra args to the controller

To pass extra arguments to the controller (e.g. to change the API server URI) add them like this:

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set ingressController.args[0]="--version" \
  "<your release name e.g. kube-ingress-aws-controller>"
```

This gets a little bit cumbersome if you want to pass multiple arguments.

Therefore a second syntax exists, that enables you to pass multiple arguments at once:

```bash
helm registry upgrade quay.io/baez/kube-ingress-aws-controller -- \
    --install \
    --wait \
    --set ingressController.awsRegion="<AWS region>" \
    --set ingressController.args='{--version,--test}' \
  "<your release name e.g. kube-ingress-aws-controller>"
```

_Note: the quotes around the block `{...}` are mandatory!_

There's no official documentation of all available switches but one can have a look at the [`.go` code](https://github.com/zalando-incubator/kube-ingress-aws-controller/blob/master/controller.go).

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
    --set ingressController.awsRegion="us-east-1" \
    --set ingressController.args[0]='--version' \
    --set kube2iam.awsArn="arn:aws:iam::$(uuidgen | cut -d '-' -f 1):role/SkipperIngress" \
    --set rbac.create=true \
    --set prometheusOperator.create=true \
    kube-ingress-aws-controller/
```

or if you have Kubernetes with installed Tiller available:

```bash
helm install \
    --dry-run \
    --debug \
    --set ingressController.awsRegion="us-east-1" \
    --set ingressController.args='{--version,--test}' \
    --set kube2iam.awsArn="arn:aws:iam::$(uuidgen | cut -d '-' -f 1):role/SkipperIngress" \
    --set rbac.create=true \
    --set prometheusOperator.create=true \
    kube-ingress-aws-controller/
```