GCLOUD=mstakx/google-cloud-sdk/bin/gcloud

#Create a GKE cluster in US_East1 Region with 1 node and 20GB Disk Size.
$GCLOUD init
$GCLOUD container clusters create mstakxlevel1 --zone us-central1-a --node-locations us-central1-a --num-nodes=1 --disk-size=20GB

#Install nginx ingress controller on the cluster.
cd mstakx/level1
$ kubectl -n ingress apply -f ingress/
$ kubectl -n ingress get pods,service,deployment,ingress,configmap

#Create namespaces called staging and production, deploy guest-book application on both these namespaces, expose it over respective provided URL and autoscale the deployment as per the CPU usuage.
for in in staging production
do
/usr/local/bin/kubectl create namespace $i
cd mstakx/level1/app/guestbook
/usr/local/bin/kubectl apply -n $i -f all-in-one
/usr/local/bin/kubectl -n $i get pods,service,deployment
/usr/local/bin/kubectl -n $i apply frontend-ingress-$i.yaml
/usr/local/bin/kubectl -n $i autoscale deployment frontend --min=1 --max=5 --cpu-percent=80
done

#Autoscale the frontend deployment if load will increase as per set threshole
sh mstakx/level1/autoscale.sh froentend

