getStatsAwsEc2Headers() {
  echo "=== getStatsAwsEc2Header($1) ========="
  local prefix=$1
  echo "prefix=$prefix"
  stats_headers="$prefix Instance Type,$prefix CPU Count,$prefix RAM,$prefix Public IP,$prefix AMI ID,$prefix AMI Platform,$prefix AMI Description,$prefix CPU Utilization (CW),$prefix Net In MB/s (CW),$prefix Net Out MB/s (CW),$prefix Net In MB (CW),$prefix Net Out MB (CW)"
  echo "stats_headers=$stats_headers"
}

getStatsAwsEc2() {
  echo "=== getStatsAwsEc2($1,$2,$3,$4) ========="
  
  local _instance_id=$1
  echo "_instance_id=$_instance_id"
  local _start_time=$2
  echo "_start_time=$_start_time"
  local _end_time=$3
  echo "_end_time=$_end_time"
  # period must be divisible by 60
  local _period=$4
  echo "_period=$_period"
  
  if [ -z "$_instance_id" ]; then
    echo "No instance ID specified, skipping..."
  else
    # get instance specific data
    local _describe_instance_result=$(aws ec2 describe-instances --instance-ids $_instance_id)
	
	# continue only of there is some result since instance id might be empty/wrong
	if [[ -z $_describe_instance_result ]]; then
	  echo "There was an error getting instance data, skipping EC2 stats..."
	else
      local _instance_type=$(echo $_describe_instance_result | jq ".Reservations[0].Instances[0].InstanceType" | xargs)
      echo "_instance_type=$_instance_type"
      
      local _public_ip=$(echo $_describe_instance_result | jq ".Reservations[0].Instances[0].PublicIpAddress" | xargs)
      echo "_public_ip=$_public_ip"
      
      local _ami_id=$(echo $_describe_instance_result | jq ".Reservations[0].Instances[0].ImageId" | xargs)
      echo "_ami_id=$_ami_id"
      
      local _describe_instance_type_result=$(aws ec2 describe-instance-types --instance-type $instance_type)
      
      local _cpu_count=$(echo $_describe_instance_type_result | jq ".InstanceTypes[0].VCpuInfo.DefaultVCpus")
      echo "_cpu_count=$_cpu_count"
      
      local _ram_MB=$(echo $_describe_instance_type_result | jq ".InstanceTypes[0].MemoryInfo.SizeInMiB")
      local _ram_GB=$(echo "$_ram_MB/1024" | bc -l | xargs printf "%0.1f")
      echo "_ram_GB=$_ram_GB"
      
      local _describe_image_result=$(aws ec2 describe-images --image-ids $_ami_id)
      
      local _image_platform=$(echo $_describe_image_result | jq ".Images[0].PlatformDetails" | xargs)
      echo "_image_platform=$_image_platform"
      
      local _image_description=$(echo $_describe_image_result | jq ".Images[0].Description" | xargs)
      echo "_image_description=$_image_description"
      
      # get test specific metrics
      local _cpu_utilization_result=$(aws cloudwatch get-metric-statistics --namespace AWS/EC2 --region eu-central-1 --metric-name CPUUtilization --start-time $_start_time --end-time $_end_time --period $_period --statistics Average --dimensions "Name=InstanceId,Value=$_instance_id")
      #echo "cpu_utilization_result=$cpu_utilization_result"
      local _cpu_utilization=$(echo $_cpu_utilization_result | jq ".Datapoints[0].Average")
      local _cpu_utilization=$(echo "$_cpu_utilization/100" | bc -l | xargs printf "%0.3f")
      echo "_cpu_utilization=$_cpu_utilization"
      
      local _net_in_result=$(aws cloudwatch get-metric-statistics --namespace AWS/EC2 --region eu-central-1 --metric-name NetworkIn --start-time $_start_time --end-time $_end_time --period $_period --statistics Sum --dimensions "Name=InstanceId,Value=$_instance_id")
      #echo "_net_in_result=$_net_in_result"
      local _net_in_bytes=$(echo $_net_in_result | jq ".Datapoints[0].Sum")
      local _net_in_Mbytes=$(echo "$_net_in_bytes/1000000" | bc -l | xargs printf "%0.4f")
      echo "_net_in_Mbytes=$_net_in_Mbytes"
      local _net_in_MBps=$(echo "$_net_in_Mbytes/$_period" | bc -l | xargs printf "%0.4f")
      echo "_net_in_MBps=$_net_in_MBps"
      
      local _net_out_result=$(aws cloudwatch get-metric-statistics --namespace AWS/EC2 --region eu-central-1 --metric-name NetworkOut --start-time $_start_time --end-time $_end_time --period $_period --statistics Sum --dimensions "Name=InstanceId,Value=$_instance_id")
      #echo "_net_out_result=$_net_out_result"
      local _net_out_bytes=$(echo $_net_out_result | jq ".Datapoints[0].Sum")
      local _net_out_Mbytes=$(echo "$_net_out_bytes/1000000" | bc -l | xargs printf "%0.4f")
      echo "_net_out_Mbytes=$_net_out_Mbytes"
      local _net_out_MBps=$(echo "$_net_out_Mbytes/$_period" | bc -l | xargs printf "%0.4f")
      echo "_net_out_MBps=$_net_out_MBps"
	fi
  fi
  
  stats_result="$_instance_type,$_cpu_count,$_ram_GB,$_public_ip,$_ami_id,$_image_platform,\"$_image_description\",$_cpu_utilization,$_net_in_MBps,$_net_out_MBps,$_net_in_Mbytes,$_net_out_Mbytes"
  #echo "stats_result=$stats_result"
}