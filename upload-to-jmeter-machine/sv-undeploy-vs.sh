vs_id=$1
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

echo "Undeploying $vs_id"

command="curl -X DELETE --insecure -s --user '$user:$password' $sv_rest_url/v2/services/$vs_id"
echo $command
result=$(eval "$command")