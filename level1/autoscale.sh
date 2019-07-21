POD_LOAD=0
TODAY=`date +%F`
SCRIPT_HOME=/usr/local/script
KUBECTL=/usr/local/bin/kubectl
DEPLOYMENT=$1

#Set Threshold value for load average of pods
LOAD_SCALEUPTHRESHOLD=2
LOAD_SCALEDOWNTHRESHOLD=1

#Define Log location
LOG_FILE=$SCRIPT_HOME/kube-$DEPLOYMENT-$TODAY.log
touch $LOG_FILE

#Find number of current replica set of provided deployment
REPLICAS=`$KUBECTL get deployment -l name=$DEPLOYMENT | awk '{print $3}' | grep -v "CURRENT"`

#Function to calculate load average of pod of provided deployment
calculate_load()
{
echo "===========================" >> $LOG_FILE
PODS=`$KUBECTL get pod -l name=$DEPLOYMENT | awk '{print $1}' | grep -v NAME`
for i in $pods
  do
    echo "Pod: "$i >> $LOG_FILE
    POD_LOAD= `kubectl -n staging exec -it $i -- uptime | awk '{print $8}'`
    echo "Load Average: "$POD_LOAD >> $LOG_FILE
    if [ $POD_LOAD -gt 1 ]
    then 
       load_autoscale $i $POD_LOAD
    fi
  done
}

#Function to autoscale the pods depending on calculated its load average
load_autoscale()
{
if [ $2 -gt $LOAD_SCALEUPTHRESHOLD ]
  then
      echo "Load is greater than the threshold" >> $LOG_FILE
      count=$((REPLICAS+1))
      echo "Updated No. of Replicas will be: "$count >> $LOG_FILE
      scale=`$KUBECTL scale --replicas=$count deployment/$DEPLOYMENT`
      echo "Deployment Scaled Up" >> $LOG_FILE

  elif [ $2 -lt $SCALEDOWNTHRESHOLD ] && [ $REPLICAS -gt 2 ]
  then
      echo "Load is less than threshold" >> $LOG_FILE
      count=$((REPLICAS-1))
      echo "Updated No. of Replicas will be: "$count >> $LOG_FILE
      scale=`$KUBECTL scale --replicas=$count deployment/$DEPLOYMENT`
      echo "Deployment Scaled Down" >> $LOG_FILE
  else
      echo "Load Average is not crossing the threshold. No Scaling Done." >> $LOG_FILE
  fi
}
