#!/bin/bash
instance_type=$1 #t2.small
image_id=$2 #ami-07a7b01b96ad73743
key_name=$3 #jakub-2021-11-04
security_group_id=$4 #sg-0a97cc79e157dbbd0

image_name=$(aws ec2 describe-images --image-id $image_id | jq ".Images[0].Name" | xargs)

echo "====================================================================================================================="
echo "Creating instance of type $instance_type"
echo "  image_id=$image_id"
echo "  image_name=$image_name"
echo "  key_name=$key_name"
echo "  security_group_id=$security_group_id"
echo "====================================================================================================================="

# monitoring Enabled=true enables 1-minute monitoring interval AKA Detailed Monitoring (which has additional charges)
aws ec2 run-instances --image-id $image_id --count 1 --instance-type $instance_type --key-name $key_name --security-group-ids $security_group_id --monitoring Enabled=true > svs-instance.json

svs_instance_id=$(cat svs-instance.json | jq ".Instances[0].InstanceId" | xargs)
echo "svs_instance_id=$svs_instance_id"

# get public DNS
echo "Waiting for the public DNS to appear..."
svs_public_dns=""
while [ -z "$svs_public_dns" ]
do
  svs_public_dns=$(aws ec2 describe-instances --instance-ids $svs_instance_id --query 'Reservations[0].Instances[0].PublicDnsName' | xargs)
  sleep 2
done
echo "svs_public_dns=$svs_public_dns"

# wait until SV Server is up
#expected_response="0.00 0.00 0.00 1/153 4756"
#expected_response_chars=${#expected_response}
#echo "expected_response_chars=$expected_response_chars"
echo "Waiting for the SV Server to come up..."
#service_response_chars="0"
rest_running_chars="0"
while [[ $rest_running_chars -lt 10 ]]
do
  echo "Sleeping for 5 seconds..."
  sleep 5
  rest_running=$(curl --insecure --connect-timeout 5 -s https://$svs_public_dns:6085/api | grep "REST API endpoint")
  echo "$rest_running"
  rest_running_chars=${#rest_running}
  #echo "rest_running_chars=$rest_running_chars"
  
  #service_response=`curl --connect-timeout 5 -s "http://$svs_public_dns:6061/linux-stats/proc/loadavg"`
  #echo "service_response=$service_response"
  #service_response_chars=${#service_response}
  #echo "service_response_chars=$service_response_chars"
done
echo "SV Server is up!"