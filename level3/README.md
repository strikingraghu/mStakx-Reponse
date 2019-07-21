1. Create a Kubernetes cluster on GCP (GCP gives free credits on signup so those should suffice for this
exercise) on their virtual machines (do not use GKE) or use the cluster created in the level2 test. If possible
share a script / code which can be used to create the cluster. 
```
I am using the same GCP kubernetes cluster created in level2 test using kubeadm utility.
```
2. Setup CI Server (Jenkins or tool of your choice) inside the Kubernetes cluster and maintain the high
availability of the jobs created. 
```To setup the Jenkins in Kubernetes, there are multiple ways in which one way I am mentioning here:- 
a. $ kubectl create ns jenkins
b. $ kubectl -n jenkins create -f level3/jenkins 
c. Access it through this url: http://<node-ip>:3000 
d. $ kubectl -n jenkins get pods 
e. Jenkins login password can be retrieve from Jenkins pod log:-
$ kubectl -n jenkins logs jenkins-deployment-2539456353-j00w5 

Note: We can also install Jenkins in kubernetes by creating a persistent volume for storing the Jenkins home data, associate it with Jenkins replica sets while creating deployment & service with more than 2 replica sets for high availability & failover, store the certificate in kubernetes secrets, create a ingress controller(nginx/haproxy/traefik) and register a domain by pointing a ingress endpoint to access Jenkins over internet. To secure the Jenkins access over public internet, we can whitelist few ip ranges by blocking all ips at ingress level.
```
3. Create a namespace and deploy the mediawiki application on the cluster. 
```
Deploy mediawiki over Kubernetes mediawiki namespace:- 
a.$ kubectl create ns mediawiki 
b.$ helm install --name my-release --set mediawikiUser=admin,mediawikiPassword=password,mariadb.mariadbRootPassword=secretpassword stable/mediawiki —namespace mediawiki
```
4. Setup a private docker registry to store the docker images. Configure restricted access between cluster to
registry and Cluster to pipeline.
```
Create a private docker registry named “docker-private-registry” by exposing 5000 port to host:-
$ docker run -d -p 5000:5000 --restart=always --name docker-private-registry -v `pwd`/config.yml:/etc/docker/registry/config.yml registry:2 

Note: All configuration options can be found at https://docs.docker.com/registry/configuration and auth option can be configured in same config.yml file by choosing any of auth options(token/htpasswd/silly).
```
5. Deploy an open source vulnerability scanner for docker images scanning within the CI build pipeline.
```
kube-hunter is an open-source tool that hunts for security issues in your Kubernetes clusters. From outside the cluster, kube-hunter probes a domain or address range for open Kubernetes-related ports, and tests for any configuration issues that leave your cluster exposed to attackers. You’ll get a full report that highlights these security concerns.
Start by running kube-hunter as a container on any machine outside your cluster, and when prompted, give it the domain name or IP address of the cluster. This gives an attackers-eye-view of your Kubernetes setup.  You can also run kube-hunter as a pod within the cluster. The report will give you an indication of how exposed your cluster would be in the event that one of your application pods is compromised. Kube-hunter tests are classified into “passive” and “active”, and by default kube-hunter only runs passive tests (or “hunters”).
A passive hunter will never change the state of the cluster, while an active hunter can potentially do state-changing operations on the cluster, which could    be harmful. If you want to also run the active hunters you need to specify –active when running the command. 
To Run kube-hunter on any VM with docker installed outside the kubernetes cluster, please run below docker command:- 
$ docker run -it --rm --network host aquasec/kube-hunter --token eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0aW1lIjoxNTYwMDgwMjYxLjI4MDk3NDYsImVtYWlsIjoiaml0LnBhdGVsLjQxNkBnbWFpbC5jb20iLCJyIjoiMGNhMTRmOWYifQ.cNB_YsNCyDqdG3q1uEfj0jr5P46OG-Oa2dRfKYiEJzM
```
6. Setup Nginx Ingress Controller manually. Configure proper routes between ingress and the application. 
```
We have already configured it in 2nd questions of level1 test.
```
7. Setup Istio and configure Kiali & Zipkin.
```
Istio captures a trace for all requests by default. Installation of Istio can be done in below two ways by sending trace to pipkin tracing provider:- 
Option1:- 
a. Create a namespace for the istio-system components: kubectl create namespace istio-system 
b. Install all the Istio Custom Resource Definitions (CRDs) using kubectl apply, and wait a few seconds for the CRDs to be committed in the Kubernetes API-server:-
$ helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system 	--set tracing.provider=zipkin | kubectl apply -f - 
c. Verify that all 53 Istio CRDs were committed to the Kubernetes api-server using the following command:-
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l 
d. Select a configuration profile and then render and apply Istio’s core components corresponding to your chosen profile. The defaultprofile is recommended for production deployments:-
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -  

Option2:- 
a. Create service account tiller:-
$ kubectl apply -f helm-service-account.yaml  << \
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
EOF
b. Install Tiller on your cluster with the service account:-
$	helm init --service-account tiller 
c. Install the istio-init chart to bootstrap all the Istio’s CRDs:-
$ helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system --set tracing.provider=zipkin
 d. Verify that all 53 Istio CRDs were committed to the Kubernetes api-server using the following command:-
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l 
e. Select a configuration profile and then install the istio chart corresponding to your chosen profile. The default profile is recommended for production deployments:-
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system
f. Verifying the installation:- 
a. $ kubectl get svc -n istio-system 
b. $ kubectl get pods -n istio-system 
g. To setup access to the tracing dashboard, use port forwarding:-
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}') 15032:15032 &
h. If you want to use Kubernetes ingress, specify the Helm chart option --set tracing.ingress.enabled=true.
i. Generating trace information of “http://URL/productpage”:-
$ for i in `seq 1 100`; do curl -s -o /dev/null http://URL/productpage; done
```
8. Setup mTLS authentication between microservices. Use self-signed certificates for secure communication
between microservices.
``` 
Generate self signed certificate & use in kubernetes cluster for secure communication between micro services:-
 a. Generate the CA Key and Certificate:-
$ openssl req -x509 -sha256 -newkey rsa:4096 -keyout ca.key -out ca.crt -days 356 -nodes -subj '/CN=Fern Cert Authority'
 b. Generate the Server Key, and Certificate and Sign with the CA Certificate:-
$ openssl req -new -newkey rsa:4096 -keyout server.key -out server.csr -nodes -subj '/CN=meow.com' ; openssl x509 -req -sha256 -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt 
c. Generate the Client Key, and Certificate and Sign with the CA Certificate:-
$ openssl req -new -newkey rsa:4096 -keyout client.key -out client.csr -nodes -subj '/CN=Fern’ ; openssl x509 -req -sha256 -days 365 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 02 -out client.crt 
d. Creating the Kubernetes Secrets:-
$ kubectl create secret generic my-certs --from-file=tls.crt=server.crt --from-file=tls.key=server.key --from-file=ca.crt=ca.crt ; kubectl get secret my-certs 
e. Mention below in metadata of your ingress rule YAML file:-
 metadata:
   annotations:
     nginx.ingress.kubernetes.io/auth-tls-verify-client: \"on\"
     nginx.ingress.kubernetes.io/auth-tls-secret: \"default/my-certs\"
f. Mention below in spec section of your ingress rule YAML file:-
spec: 
 tls:
  - hosts:
      - application_URL
  secretName: my-certs        
g. Create the ingress object and get its details:-
$ kubectl get ing 
```
9. Setup Kubernetes Dashboard and secure access to the dashboard using a read only token.
```
Setup Kubernetes Dashboard and secure access to the dashboard using a read only token:-
a. Deploy the kubernetes dashboard:-
$ kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml 
b. Create proxy server between your machine and Kubernetes API server:-
$ kubectl proxy 
c. Access the kubernetes dashboard from any browser:-
$ http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/ 
d. Create a service account for a dashboard in the default namespace:-
$ kubectl create serviceaccount dashboard -n default 
e. Add the cluster binding rules to your dashboard account:-
$ kubectl create clusterrolebinding dashboard-admin -n default  --clusterrole=cluster-admin  --serviceaccount=default:dashboard 
f. Copy the secret token required for your dashboard login generated by this command:-
$ kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode g. Copy the secret token and paste it in Dashboard Login Page, by selecting a token option.
```
10. Automate the process of cluster creation and application deployment using Terraform +
Ansible/Jenkins/Helm/script/SDK.
``` 
Setup kubernetes cluster & application deployment using terraform:-
a. Create required file & directory structure by running below command on your terminal:-
 $ mkdir terraform-gke
 $ cd terraform-gke
 $ mkdir gke k8s
 $ touch main.tf
 $ for f in cluster gcp variables; do touch gke/$f.tf; done
 $ for f in k8s pods services variables; do touch k8s/$f.tf; done           
b. Initialize some variables that the GCP provider requires, which is the target project and the desired region to create the cluster.:-
$ export TF_VAR_project="$(gcloud config list --format 'value(core.project)')" ; export TF_VAR_region="us-east1"
c. Specify the administrative account and a random password for the cluster:-
$ export TF_VAR_user="admin" ; export TF_VAR_password="m8XBWrg2zt8R8JoH"          
d. Initialize the environment, which includes both downloading plugins required google cloud provider and kubernetes provider, as well as references to our modules:-
$ terraform init          
e. Dry run the terraform object creation and create it:- 
$ terraform plan ; terraform apply          
f. After some time (10 to 20 minutes) we can test out our application. Run this to see the end points:-
$ kubectl get service
```
