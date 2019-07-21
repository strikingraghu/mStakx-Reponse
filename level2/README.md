1. Create a Highly available Kubernetes cluster manually using Google Compute Engines (GCE). Do not create
a Kubernetes hosted solution using Google Kubernetes Engine (GKE). Use Kubeadm(preferred)/kubespray.
Do not use kops.
```
Setup Kubernetes cluster over GCP using Kubeadm:- 
a. $ cd mstakx/level2/k8skubeadm 
b. $ ansible-playbook -i hosts kube-cluster/kube-dependencies.yml 
c. $ ansible-playbook -i hosts kube-cluster/master.yml 
d. $ ansible-playbook -i hosts kube-cluster/workers.yml
```
2. Create a CI/CD pipeline using Jenkins (or a CI tool of your choice) outside Kubernetes cluster (not as a pod
inside Kubernetes cluster).
``` 
Place the checked in jenkinsfile(present at mstakx/level2/jenkinsfile) in your Github/Gitlab repo to trigger ci/cd pipeline with configured Jenkins.
```
3. Create a development namespace.
``` 
kubectl create namespace development
```
4. Deploy guest-book application in the development namespace.
``` 
Navigate to app yaml directory(like cd mstakx/level2/app/guestbook/) and run either of below command to deploy it on development namespace:- 
a. $ kubectl -n development apply -f all-in-one 
b. $ kubectl apply -f all-in-one
```
5. Install and configure Helm in Kubernetes.
```
Install Helm on Linux/MacOS:- 
a. $ cd mstakx/level2/install-helm
b. $ git clone https://github.com/helm/helm.git
c. $ cd helm
d. $ make bootstrap build
e. Set up a Service account for use by tiller(helm server):-
$ kubectl --namespace kube-system create serviceaccount tiller
f. Provide full permission to Service account to manage the cluster:-
$ kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
g. Initialise helm and tiller:-
$ helm init --service-account tiller --wait
h. Ensure the tiller is secure from access inside the cluster:-
$ kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'
i. Verify helm installation:-
$ helm version
```
6. Use Helm to deploy the application on Kubernetes Cluster from CI server.
```
Steps to deploy application using Helm from CI Servers:- 
a. Get code from Git:-
   a.1. Developer pushes code to Git, which triggers a Jenkins build webhook.  
   a.2. Jenkins pulls the latest code changes. 
b. Run build and unit tests:-
   b.1. Jenkins runs the build.   
   b.2. Application’s Docker image is created during the build.- Tests run against a running Docker container. 
c. Publish Docker image and Helm Chart:-  
   c.1. Application’s Docker image is pushed to the Docker registry.  
   c.2. Helm chart is packed and uploaded to the Helm repository. 
d. Deploy to Development:- 
   d.1. Application is deployed to the Kubernetes development cluster or namespace using the published Helm chart.  
   d.2. Tests run against the deployed application in Kubernetes development environment. 
e. Deploy to Staging:-  
   e.1. Application is deployed to Kubernetes staging cluster or namespace using the published Helm chart.   
   e.2. Run tests against the deployed application in the Kubernetes staging environment. 
f. Deploy to Production:-  
   f.1. The application is deployed to the production cluster if the application meets the defined criteria. Please note that you can set up as a manual approval step.  
   f.2. Sanity tests run against the deployed application.   
   f.3. If required, you can perform a rollback.
```
7. Create a monitoring namespace in the cluster.
```
$ kubectl create namespace monitoring
```
8. Setup Prometheus (in monitoring namespace) for gathering host/container metrics along with health
check status of the application.
```
Setup Prometheus in monitoring namespace:- 
a. $ kubectl apply -f mstakx/level2/monitoring/prometheus/ 
b. $ kubectl apply -f mstakx/level2/monitoring/kube-state-metrics/
```
9. Create a dashboard using Grafana to help visualize the Node/Container/API Server etc. metrices from
Prometheus server. Optionally create a custom dashboard on Grafana.
```
Setup dashboard using Grafana:-
$ kubectl apply -f mstakx/level2/monitoring/grafana
```
10. Setup log analysis using Elasticsearch, Fluentd, Kibana.
``` 
Setup Elasticsearch, Fluentd & Kibana:-
$ kubectl apply -f mstakx/level2/elasticsearch-fluentd-kibana
```
11. Demonstrate Blue/Green and Canary deployment for the application (For e.g. Change the background
color or font in the new version).
``` 
Canary Deployment:-
 a. The canary release is a technique to reduce the risk of introducing a new software version in production by slowly rolling out the change to a small subset of users before rolling it out to the entire infrastructure. 
b. It is about to get an idea of how new version will perform (integrate with other apps, CPU, memory, disk usage, etc). 
c. The essence of canary deployment is deploying incrementally. 

Blue/Green Deployment: 
a. It is more about the predictable release with zero downtime deployment. 
b. Easy rollbacks in case of failure. 
c. Completely automated deployment process. 
d. The essence of blue-green is deploying all at once.
```
