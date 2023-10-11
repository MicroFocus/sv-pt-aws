project_folder=$1
sv_rest_url=$2
user=$3
password=$4

waitUntil () {
  command=$1
  desired_value_name=$2
  desired_value=$3
  sleep_time=$4

  while true
  do
    #echo $command
    current_value=$(eval $command)
    
	if [ "$desired_value" == "$current_value" ]; then
	  echo "$desired_value_name='$current_value' as expected."
	  break
	else
	  echo "$desired_value_name='$current_value', but must be '$desired_value'. Retrying in $sleep_time seconds..."
	fi
	
    sleep $sleep_time
  done
}

echo "Deploying $project_folder"

rm -f tmp.vproja
zip -r -j -q tmp.vproja $project_folder

#
url="$sv_rest_url/v2/uploadProject"
command="curl -s --user '$user:$password' --insecure --header 'Content-Type:application/octet-stream' --data-binary @tmp.vproja $url | jq '.id' | xargs"
echo $command
deployer_id=$(eval "$command")
echo "DeployerID=$deployer_id"

url="$sv_rest_url/v2/deployer/$deployer_id"
command="curl -s --user '$user:$password' --insecure $url | jq '.deployerState' | xargs"
waitUntil "$command" deployerState ReadyToStartDeployment 2

url="$sv_rest_url/v2/deployer/$deployer_id/startDeployment"
command="curl -s --user '$user:$password' --insecure -X POST --header 'Content-Type:application/json' -d '{}' $url"
echo $command
result=$(eval $command)

url="$sv_rest_url/v2/deployer/$deployer_id/deploymentResult"
command="curl -s --user '$user:$password' --insecure $url | jq '.deploymentState' | xargs"
waitUntil "$command" deploymentState DeploymentFinished 2

# running the above request again to get VS ID
url="$sv_rest_url/v2/deployer/$deployer_id/deploymentResult"
command="curl -s --user '$user:$password' --insecure $url | jq '.deploymentResultInformations[0].virtualServiceInfo.id' | xargs"
echo $command
vs_id=$(eval $command)
echo "Finished deploying $vs_id"

rm -f tmp.vproja