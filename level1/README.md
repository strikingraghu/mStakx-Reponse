1. Create a Kubernetes cluster on GCP (GCP gives free credits on signup so those should suffice for this
exercise). If possible share a script / code which can be used to create the cluster.
```
a. $ gcloud init
b. $ gcloud container clusters create mstakxlevel1 --zone us-central1-a --node-locations us-central1-a --num-nodes=1 --disk-size=20GB

Note: Created a GKE cluster with other default configs & single zonal node of g1-small size with 20GB Disk Size due to requirement of deploying a lighter application.
```
2. Install nginx ingress controller on the cluster. For now, we consider that the user will add public IP of
ingress LoadBalancer to their /etc/hosts file for all hostnames to be used. So do not worry about DNS
resolution.
```
a. $ cd mstakx/level1
b. $ kubectl -n ingress apply -f ingress/
c. $ kubectl -n ingress get pods,service,deployment,ingress,configmap
```
3. On this cluster, create namespaces called staging and production.
```
a. $ kubectl create namespace staging
b. $ kubectl create namespace production
```
4. Install guest-book application on both namespaces.
```
cd mstakx/level1/app/guestbook
ON STAGING:-
a. $ kubectl apply -n staging -f all-in-one
b. $ kubectl -n staging get pods,service,deployment
ON PRODUCTION:-
a. $ kubectl apply -n production -f all-in-one 
b. $ kubectl -n production get pods,service,deployment
```
5. Expose staging application on hostname staging-guestbook.mstakx.io
```
$ kubectl -n staging apply mstakx/level1/app/guestbook/frontend-ingress-staging.yaml
```
6. Expose production application on hostname guestbook.mstakx.io
```
$ kubectl -n staging apply mstakx/level1/app/guestbook/frontend-ingress-production.yaml
```
7. Implement a pod autoscaler on both namespaces which will scale frontend pod replicas up and down
based on CPU utilization of pods.
```
Below will autoscale the pod when there is cpu utlization will be 80% or more till max value mentioned.
a. $ kubectl -n staging autoscale deployment frontend --min=1 --max=5 --cpu-percent=80
a. $ kubectl -n production autoscale deployment frontend --min=1 --max=5 --cpu-percent=80
```
8. Write a script which will demonstrate how the pods are scaling up and down by increasing/decreasing load
on existing pods.
```
$ sh mstakx/level1/autoscale.sh <Deployment Name>
```
9. Write a wrapper script which does all the steps above. Mention any pre-requisites in the README.md at
the root of your repo.
```
$ sh mstakx/level1/wripper_script.sh
```

In the context of above test, please explain the following:
• What was the node size chosen for the Kubernetes nodes? And why?
```
To save the cloud cost & test purpose, I have created a minimal size GKE cluster of one node with instanace g1-small & 20GB Disk space. Kubernetes Cluster size depends on the size of application, usuage of application, no. of concurrent connections on application, purpose of application usuage(like on Dev/Test/UAT/SIT/Stage/Production), criticality of application, Security of application, etc.
```
• What method was chosen to install the demo application and ingress controller on the cluster, justify the
method used.
```
I am installing application & ingress controller through kubectl utility but it can be deploy using serveral other utilities like Spinnaker & helm package manager.
```
• What would be your chosen solution to monitor the application on the cluster and why?
```
I use to monitor application on cluster using grafana/prometheus & Kibana dashboard but if there is requirement to put alert on some application monitoring parameters, I prefer to use Datadog to monitoring and alerting.
```
• What additional components / plugins would you install on the cluster to manage it better?
```
I prefer to install security scan plugin like kube-hunter to find out the vulnerability in kubernetes cluster.
```
