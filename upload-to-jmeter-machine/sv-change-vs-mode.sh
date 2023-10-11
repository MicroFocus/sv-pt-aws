vs_id=$1
mode=$2

sv_rest_url=$3
user=$4
password=$5
dm_id=$6
pm_id=$7

waitUntil () {
  local command=$1
  local desired_value_name=$2
  local desired_value=$3
  local sleep_time=$4

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

echo "Changing mode of $vs_id to $mode..."

if [[ "$mode" == "PassThrough" ]]; then
  request_json="{'RuntimeMode':'$mode'}"
elif [[ "$mode" == "Simulating" ]]; then

  if [ -z "$dm_id" ]; then
    command="curl -s --insecure --user '$user:$password' $sv_rest_url/v2/services/$vs_id | jq '.dataModels[0].id' | xargs"
    #echo $command
    dm_id=$(eval "$command")
  fi
  echo "DataModelId=$dm_id"

  if [ -z "$pm_id" ]; then
    request_json="{'RuntimeMode':'$mode','DataModelId':'$dm_id'}"
  else
    echo "PerformanceModelId=$pm_id"
    request_json="{'RuntimeMode':'$mode','DataModelId':'$dm_id','PerformanceModelId':'$pm_id'}"
  fi
  
fi

command="curl -X PUT --insecure -s --user '$user:$password' --header 'Content-Type:application/json' -d \"$request_json\" $sv_rest_url/v2/services/$vs_id"
echo $command
result=$(eval "$command")

command="curl -s --user '$user:$password' --insecure $sv_rest_url/v2/services/$vs_id | jq '.deploymentState' | xargs"
echo $command
waitUntil "$command" deploymentState Ready 2

echo "Finished changing mode"