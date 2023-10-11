getStatsAwsRdsHeaders() {
  echo "=== getStatsAwsRdsHeaders() ========="
  stats_headers="RDS Instance Type,RDS CPU Count,RDS RAM GB,RDS CPU Utilization (CW),RDS ReadIOPS Avg (CW),RDS ReadIOPS Max (CW),RDS WriteIOPS Avg (CW),RDS WriteIOPS Max (CW),RDS DB Transactions (PI)"
  echo "stats_headers=$stats_headers"
}

getStatsAwsRds() {
  echo "=== getStatsAwsRds($1,$2,$3,$4) ========="
  
  local _rds_instance_id=$1
  echo "_rds_instance_id=$_rds_instance_id"
  local _start_time=$2
  echo "_start_time=$_start_time"
  local _end_time=$3
  echo "_end_time=$_end_time"
  local _period=$4
  echo "_period=$_period"

  if [ -z "$_rds_instance_id" ]; then
    echo "Skipping getting RDS stats since RDS not used"
  else
	local _describe_db_instance_result=$(aws rds describe-db-instances --db-instance-identifier $_rds_instance_id)
	
    local _db_resource_id=$(echo $_describe_db_instance_result | jq ".DBInstances[0].DbiResourceId" | xargs)
    echo "_db_resource_id=$_db_resource_id"
  
    local _db_instance_class=$(echo $_describe_db_instance_result | jq ".DBInstances[0].DBInstanceClass" | xargs)
    echo "_db_instance_class=$_db_instance_class"
    
	# remove db. prefix
	local _instance_type=$(echo $_db_instance_class | cut -c 4-)
	echo "_instance_type=$_instance_type"
	local _describe_instance_type_result=$(aws ec2 describe-instance-types --instance-type $_instance_type)
	
	local _cpu_count=$(echo $_describe_instance_type_result | jq ".InstanceTypes[0].VCpuInfo.DefaultVCpus")
	echo "_cpu_count=$_cpu_count"
	
	local _ram_MB=$(echo $_describe_instance_type_result | jq ".InstanceTypes[0].MemoryInfo.SizeInMiB")
	local _ram_GB=$(echo "$_ram_MB/1024" | bc -l | xargs printf "%0.1f")
	echo "_ram_GB=$_ram_GB"
    
    local _rds_read_iops_result=$(aws cloudwatch get-metric-statistics --region eu-central-1 --metric-name ReadIOPS --start-time $_start_time --end-time $_end_time --period $_period --namespace AWS/RDS --statistics {Maximum,Average} --dimensions "Name=DBInstanceIdentifier,Value=$_rds_instance_id")
    #echo "_rds_read_iops_result=$_rds_read_iops_result"
    local _rds_read_iops_max=$(echo $_rds_read_iops_result | jq ".Datapoints[0].Maximum" | xargs printf "%0.3f")
    echo "_rds_read_iops_max=$_rds_read_iops_max"
    
    local _rds_read_iops_avg=$(echo $_rds_read_iops_result | jq ".Datapoints[0].Average" | xargs printf "%0.3f")
    echo "_rds_read_iops_avg=$_rds_read_iops_avg"
    
    local _rds_write_iops_result=$(aws cloudwatch get-metric-statistics --region eu-central-1 --metric-name WriteIOPS --start-time $_start_time --end-time $_end_time --period $_period --namespace AWS/RDS --statistics {Maximum,Average} --dimensions "Name=DBInstanceIdentifier,Value=$_rds_instance_id")
    #echo "_rds_write_iops_result=$_rds_write_iops_result"
    
    local _rds_write_iops_max=$(echo $_rds_write_iops_result | jq ".Datapoints[0].Maximum" | xargs printf "%0.3f")
    echo "_rds_write_iops_max=$_rds_write_iops_max"
    
    local _rds_write_iops_avg=$(echo $_rds_write_iops_result | jq ".Datapoints[0].Average" | xargs printf "%0.3f")
    echo "_rds_write_iops_avg=$_rds_write_iops_avg"
    
    local _rds_cpu_utilization_result=$(aws cloudwatch get-metric-statistics --region eu-central-1 --metric-name CPUUtilization --start-time $_start_time --end-time $_end_time --period $_period --namespace AWS/RDS --statistics Average --dimensions "Name=DBInstanceIdentifier,Value=$_rds_instance_id")
    local _rds_cpu_utilization=$(echo $_rds_cpu_utilization_result | jq ".Datapoints[0].Average" | xargs printf "%0.3f")
	local _rds_cpu_utilization=$(echo "$_rds_cpu_utilization/100" | bc -l | xargs printf "%0.3f")
    echo "_rds_cpu_utilization=$_rds_cpu_utilization"
    
    local _rds_transactions_result=$(aws pi get-resource-metrics --service-type RDS --identifier $_db_resource_id --start-time $_start_time --end-time $_end_time --period-in-seconds $_period --metric-queries '[{"Metric": "db.Transactions.xact_commit.sum"  }]')
     
    local _rds_transactions=$(echo $_rds_transactions_result | jq ".MetricList[0].DataPoints[0].Value")
    echo "_rds_transactions=$_rds_transactions"
  fi
  
  stats_result="$_db_instance_class,$_cpu_count,$_ram_GB,$_rds_cpu_utilization,$_rds_read_iops_avg,$_rds_read_iops_max,$_rds_write_iops_avg,$_rds_write_iops_max,$_rds_transactions"
  #echo "stats_result=$stats_result"
}
