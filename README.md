# AWS EKS Kubernetes Microservice Web Application
In this example we use
[CodePipeline](https://aws.amazon.com/codepipeline/), [CodeBuild](https://aws.amazon.com/codebuild/), and [ECR](https://aws.amazon.com/ecr/) to build, test, publish, and deploy a simple microservice web app to our new Kubernetes cluster.

Check out our [AWS EKS Kubernetes Cluster](https://github.com/thestacks-io/eks-cluster) project to see how we use CloudFormation to spin up a new EKS Kubernetes cluster.

# Prerequisites
- [AWS Account](https://aws.amazon.com/)
- [EC2 Key Pair](https://console.aws.amazon.com/ec2/v2/home)
- [cim.sh](https://cim.sh/) - `npm install -g cim`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/installing.html) - Amazon EKS requires at least version 1.15.32 of the AWS CLI
- [kubectl & heptio-authenticator-aws](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html?shortFooter=true#eks-prereqs)
- [AWS EKS Kubernetes Cluster](https://github.com/thestacks-io/eks-cluster) 


# Stacks

We use CodePipeline and CodeBuild to build, test, and deploy a new image to ECR on every commit so you will need to fork this repo into your account.


## Microservice Stack
### 1.) Update the input parameters within [_cim.yml](_cim.yml).
```
  parameters:
    AppName: 'eks-test'
    GitHubOwner: 'thestacks-io'
    GitHubRepo: 'eks-microservice'
    GitHubToken: '${kms.decrypt(AQICAHgiu9XuQb...mJrnw==)}'
```
You will need to replace the `GitHubOwner`, `GitHubRepo`, and `GitHubToken`.  Follow the steps below to encrypt your `GitHubToken`.

Encrypt Secrets:

In order to protect your configuration secrets like your GitHub token we need to create a KMS key first.

- Open the AWS console to [KMS](https://aws.amazon.com/kms/) and create a new KMS key.
- Install https://github.com/ddffx/kms-cli and setup your AWS environment vars.
- Encrypt each string as outlined below.
- Add the encrypted strings to the [_cim.yml](_cim.yml).  The format is `${kms.decrypt(<encreted string>)}`


How to Encrypt:

Create a file called `encrypt.json`
```
{
  "keyId" : "<your kms key id>",
  "plainText": "<your client id>",
  "awsRegion": "<aws region>",
  "awsProfile": "<aws profile"
}
```
Use this command to perform the encryption : `kms-cli encrypt --file encrypt.json`

### 2.) Now we're ready to deploy our stack.
Deploy stack.
```
cim stack-up
```

Once an image is built and placed in ECR we can deploy our microservice.

Record the `ECRUrl` stack output parameter because we will need it in the next step.

### 3.) Configure and create the Kubernetes deployment.
Update the [eks-deployment.yml](eks-deployment.yml) file and replace the `<ecr-url>` and `<image-version>`.  Both of these can be found in your [ECR](https://aws.amazon.com/ecr/) console.  The `<image-version>` is the first 8 characters of the commit hash that triggered the new image.

Now that your [eks-deployment.yml](eks-deployment.yml) file is ready we can create the Kubernetes deployment.

Create the Kubernetes deployment:
```
kubectl create -f eks-deployment.yml
```

Check the status of your pods.
```
kubectl get pods
```

### 4.) Create the Kumbernetes service.
Create the Kubernetes service (Routing for pods)
```
kubectl create -f eks-service.yml
```

This will create a classic load balancer you can use to access your web app.  You can also use the load balancer url to create a Route53 DNS route if you wish.

Get domain.  It may take several minutes before the IP address is available.
```
kubectl get services -o wide
```

# Tear down
```
kubectl delete -f eks-service.yml
kubectl delete -f eks-deployment.yml
cim stack-delete
```