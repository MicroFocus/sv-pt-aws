#!/bin/bash

# SVS instance global configuration

ami_id=$1
echo "ami_id=$ami_id"
security_group_id=$2
echo "security_group_id=$security_group_id"
key_name=$3
echo "key_name=$key_name"

test_note=$4
echo "test_note=$test_note"

# SETTINGS

svs_user=admin
echo "svs_user=$svs_user"
svs_password=password

# main result file where results are aggregated
results_file=results.csv
http_agent_port=6061
# to have realistic loadavg max and RT max, you should run for at least 3 minutes, 5 is better

# restriction for getting Performance Insights metrics for RDS is the duration must be 1, 60, 300, 3600, 86400
# restriction for getting CloudWatch metrics is that the duration must be divisible by 60
jmeter_test_duration=300
jmeter_think_time=0

loadavg_svserver_file=loadavg-history-svserver
loadavg_jmeter_file=loadavg-history-jmeter
svs_server_statistics_file=svs-server-statistics

pid=`$!`
echo "script process id: $pid"

jmeter_cpu_count=`lscpu | grep -i "^CPU(s):" | xargs | cut -d " " -f2`
echo "jmeter_cpu_count=$jmeter_cpu_count"

# start capturing loadavg from jmeter machine in the background
{
while [ true ]
do
   cat /proc/loadavg >> $loadavg_jmeter_file
   sleep 20
done
} &
loadavg_jmeter_pid=`jobs -p | tail -n1`
echo "loadavg_jmeter_pid=$loadavg_jmeter_pid"

loadavg=0

source get-stats-aws-ec2.sh
source get-stats-aws-rds.sh
source get-stats-jmeter.sh

# create result file and header if it does not exist
if [ ! -f $results_file ]; then
  # TODO: Docker version, container OS, Used RAM,JMeter Loop Count,Number of TX directly from postgres DB via select, PM accuraccy, PM name, DM accuracy, DB latency
  
  getStatsAwsEc2Headers "JM"
  stats_ec2_jmeter_headers=$stats_headers
  
  getStatsAwsEc2Headers "SVS"
  stats_ec2_svs_headers=$stats_headers
  
  getStatsAwsEc2Headers "DB"
  stats_ec2_db_headers=$stats_headers
  
  getStatsJmeterHeaders
  stats_jmeter_header=$stats_headers
  
  getStatsAwsRdsHeaders
  stats_aws_rds_headers=$stats_headers
  
  echo "Start Time,End Time,JM Test,JM Think Time,JM Threads,JM CPU Loadavg Max,DB,DB Type,DB Connection String,DB TXs,DB TX/s,SVS Docker,SVS Version,SVS Data Provider,VS ID,VS Name,VS Protocol ID,VS DM ID,VS DM Name,VS PM ID,VS PM Name,VS DM Accuracy,VS PM Accuracy,SVS CPU Model,SVS Hypervisor Vendor,SVS OS,SVS Errors,SVS CPU Loadavg Max,SVS CPU Utilization (loadavg),SVS CPU Utilization (SV API),SVS DB Response Time,Note,$stats_jmeter_header,$stats_ec2_jmeter_headers,$stats_ec2_svs_headers,$stats_ec2_db_headers,$stats_aws_rds_headers">$results_file
fi

# this uglyness deals properly with the last line not being accounted for when not terminated by new line
# https://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable/10929511#10929511
while IFS= read -r -u 3 instance_type || [[ -n "$instance_type" ]]; do
  if [[ "$instance_type" =~ ^"#" ]]; then
    echo "skipping $instance_type"
	continue
  fi
  
  # running via source to get variables defined there into the context of this script
  source aws-create-svs-instance.sh $instance_type $ami_id $key_name $security_group_id
  echo "svs_public_dns=$svs_public_dns"
  echo "svs_instance_id=$svs_instance_id"
  
  echo "Deploying test helper virtual services..."	
  
  # deploy test infrastructure services
  ./sv-deploy-sv-project.sh virtual-services-test-infrastructure/aws/aws https://$svs_public_dns:6085/api $svs_user $svs_password
  ./sv-deploy-sv-project.sh virtual-services-test-infrastructure/linux-stats/linux-stats https://$svs_public_dns:6085/api $svs_user $svs_password
  ./sv-deploy-sv-project.sh virtual-services-test-infrastructure/pt-helper/pt-helper https://$svs_public_dns:6085/api $svs_user $svs_password
  ./sv-deploy-sv-project.sh virtual-services-test-infrastructure/sv-api-ext-logs/sv-api-ext-logs-project https://$svs_public_dns:6085/api $svs_user $svs_password
  
  # switch infrastructure services to simulation
  ./sv-change-vs-mode.sh abce5250-415a-4826-b2bb-04e6138c4400 Simulating https://$svs_public_dns:6085/api $svs_user $svs_password
  ./sv-change-vs-mode.sh 3f2fdfae-b7ff-4844-af6b-5da8caae47ed Simulating https://$svs_public_dns:6085/api $svs_user $svs_password
  ./sv-change-vs-mode.sh 9baf3683-1b6a-437b-bbfd-c617235a0712 Simulating https://$svs_public_dns:6085/api $svs_user $svs_password
  ./sv-change-vs-mode.sh 4f43d4ae-94a8-41e5-9461-62eeeb1c772f Simulating https://$svs_public_dns:6085/api $svs_user $svs_password

  svs_cpu_count=$(curl -s "http://$svs_public_dns:$http_agent_port/linux-stats/lscpu" | grep -i "^CPU(s):" | xargs | cut -d " " -f2)
  echo "svs_cpu_count=$svs_cpu_count"
  
  #echo "Waiting 10 seconds to finish changing state of VSs to simulation"
  #sleep 10
  echo "Deploying test helper virtual services DONE"
  
  # start capturing loadavg from sv-server in the background
  {
  while [ true ]
  do
     curl -s "http://$svs_public_dns:$http_agent_port/linux-stats/proc/loadavg" >> $loadavg_svserver_file
     sleep 20
  done
  } &
  loadavg_svserver_pid=$(jobs -p | tail -n1)
  echo "loadavg_svserver_pid=$loadavg_svserver_pid"
  
  # start capturing SVS load via SV Server API
  {
  while [ true ]
  do 
    _server_stats=$(curl --insecure -s https://$svs_public_dns:6085/api/serverStatistics)
    _svs_cpu_utilization=$(echo "$_server_stats" | xmllint --xpath "string(/*[local-name()='serverStatistics']/@cpuUsage)" -)
	_svs_db_response_time=$(echo "$_server_stats" | xmllint --xpath "string(/*[local-name()='serverStatistics']/@dbResponseTime)" -)
	echo "$_svs_cpu_utilization $_svs_db_response_time" >> $svs_server_statistics_file
	sleep 20
  done
  } &
  svs_cpu_utilization_api_pid=$(jobs -p | tail -n1)
  echo "svs_cpu_utilization_api_pid=$svs_cpu_utilization_api_pid"
  
  host_os=$(curl -s http://$svs_public_dns:$http_agent_port/pt-helper/host-data | grep host | cut -c 10-)
  echo "host_os=$host_os"
  
  cpu_model=$(curl -s "http://$svs_public_dns:$http_agent_port/linux-stats/lscpu" | grep "Model name:" | xargs | cut -c 13-)
  echo "cpu_model=$cpu_model"
  
  hypervisor_vendor=$(curl -s "http://$svs_public_dns:$http_agent_port/linux-stats/lscpu" | grep "Hypervisor vendor:" | xargs | cut -c 20-)
  echo "hypervisor_vendor=$hypervisor_vendor"
  
  server_data_provider=$(curl -s "http://$svs_public_dns:$http_agent_port/sv-api-ext/log/server/view" | grep ServiceCallDataProviderProxy)
  if [[ $server_data_provider == *"inMemory"* ]]; then
    server_data_provider="inMemory"
  else
    server_data_provider="inDatabase"
  fi
  
  db_signature=$(curl -s "http://$svs_public_dns:$http_agent_port/sv-api-ext/log/server/view" | grep "Database version:" -A 1 | grep -v "Database version:" | xargs)
  echo "db_signature=$db_signature"
  
  db_connection_string=$(curl -s "http://$svs_public_dns:$http_agent_port/sv-api-ext/log/server/view" | grep -i "Connection string:" | sed -n -e 's/^.*Connection string: //p')
  echo "db_connection_string=$db_connection_string"
  
  if [[ $db_connection_string == *"rds.amazonaws.com"* ]]; then
    db_type="RDS"
  else
    db_type="other"
  fi
  echo "db_type=$db_type"
  
  sv_version=$(curl --insecure -s "https://$svs_public_dns:6085/api/" | cut -c 53-62)
  echo "sv_version=$sv_version"
  
  # this uglyness deals properly with the last line not being accounted for when not terminated by new line
  # https://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable/10929511#10929511
  while IFS= read -r -u 4 test_service_line || [[ -n "$test_service_line" ]]; do
    if [[ "$test_service_line" =~ ^"#" ]]; then
      echo "skipping $test_service_line"
	  continue
    fi
  
    # need to add a space so that cut actually returns nothing for non-existent columns. See https://unix.stackexchange.com/questions/465583/what-does-cut-return-if-the-specified-field-does-not-exist
    test_service=$(echo "$test_service_line " | cut -d " " -f 1)
	echo "test_service=$test_service"
  
    echo "====================================================================================="
    echo "Going to test $test_service ($instance_type)"
    echo "====================================================================================="

	dm_id=$(echo "$test_service_line " | cut -d " " -f 2)
	echo "dm_id=$dm_id"
	pm_id=$(echo "$test_service_line " | cut -d " " -f 3)
	echo "pm_id=$pm_id"
	
    jmeter_test_file="$test_service.jmx"
	jmeter_test_path="jmeter-tests/$jmeter_test_file"
    if [ ! -f $jmeter_test_path ]; then
      echo "ERROR: Test $jmeter_test_path not found!"
	  continue
    fi
    echo "jmeter_test_path=$jmeter_test_path"
	
	vs_file_path="virtual-services/$test_service/$test_service/$test_service.vs"
    if [ ! -f $vs_file_path ]; then
      echo "ERROR: VS $vs_file_path not found!"
	  continue
    fi
	echo "vs_file_path=$vs_file_path"
	
    vsid=$(xmllint --xpath "string(/*[local-name()='virtualService']/@id)" $vs_file_path)
    echo "vsid=$vsid"
	
	vs_name=$(xmllint --xpath "string(/*[local-name()='virtualService']/@name)" $vs_file_path)
	echo "vs_name=$vs_name"
	
	sv_project_folder="virtual-services/$test_service/$test_service"
	echo "sv_project_folder=$sv_project_folder"

    echo "Deploying virtual service $vs_name..."
	./sv-deploy-sv-project.sh $sv_project_folder https://$svs_public_dns:6085/api $svs_user $svs_password
	./sv-change-vs-mode.sh $vsid Simulating https://$svs_public_dns:6085/api $svs_user $svs_password $dm_id $pm_id
	
	protocol_id=$(curl -s --insecure "https://$svs_public_dns:6085/api/v2/services/$vsid" -H "accept: application/json" -u "$svs_user:$svs_password" | jq ".protocol" | xargs)
	echo "protocol_id=$protocol_id"
	
	# FIXME: data_model_id is empty sometimes
	data_model_id=$(curl -s --insecure "https://$svs_public_dns:6085/api/v2/services/$vsid" -H "accept: application/json" -u "$svs_user:$svs_password" | jq -r ".dataModels[] | select(.selected == true).id")
    echo "data_model_id=$data_model_id"
	
	performance_model_id=$(curl -s --insecure "https://$svs_public_dns:6085/api/v2/services/$vsid" -H "accept: application/json" -u "$svs_user:$svs_password" | jq -r ".performanceModels[] | select(.selected == true).id")
    echo "performance_model_id=$performance_model_id"
	
	data_model_name=$(curl -s --insecure https://$svs_public_dns:6085/api/services/$vsid/dataModel/$data_model_id | xmllint --xpath "string(/*[local-name()='dataModel']/@name)" -) 
	echo "data_model_name=$data_model_name"
	
	performance_model_name=$(curl -s --insecure https://$svs_public_dns:6085/api/services/$vsid/dataModel/$performance_model_id | xmllint --xpath "string(/*[local-name()='performanceModel']/@name)" -) 
	echo "performance_model_name=$performance_model_name"
	
    max_tps=0
    
	# make the thread_increment bigger with more CPUs
	thread_increment=$((svs_cpu_count/8))
	if (( $thread_increment == 0 )) then
	  thread_increment=1
	fi
	echo "thread_increment=$thread_increment"
	
	#now lets sleep for a minute to cooldown the machine
    echo "SV Server ready. Cooling down the CPU for 60 seconds before the first test..."
	sleep 60
	
    #for threads in {1..1000..4}
	#for threads in 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 100 200 300
	#for threads in 200
	#for threads in 5 6 7 8 9 10 11 12 13 16 17 18 19 100 200 300
	#for threads in $(seq 200 1 200)
	#for threads in $(seq 1 $thread_increment 200)
	#for threads in 1 2 4 8 16 32 64 128 256 512 1024
	#for threads in 4 5 6
	#for threads in 1
	threads=0;
	
	# I want to continue for a while after we hit the max TPS threshold to see how everything behaves once peak TPS reached
	stop_in=-1
    while true
    do
	
      # cleanup
      echo "cleaning..."
      rm $loadavg_svserver_file
	  rm $loadavg_jmeter_file
	  rm $svs_server_statistics_file
	  rm -f /home/ec2-user/jmeter-result-* >/dev/null
      rm -rf /home/ec2-user/jmeter-web-report-* >/dev/null

      #increase load by 10%
	  threads_new=$(echo "$threads*1.1" | bc | xargs printf "%0.0f")
	  if [ "$threads_new" -eq "$threads" ] ; then
	    threads=$(($threads+1))
	  else
	    threads=$threads_new
	  fi

      echo "--------------------------------------------------------------------------------------------------"
      echo "Running $jmeter_test_file test for $threads threads on $svs_instance_id ($instance_type)..."
      echo "--------------------------------------------------------------------------------------------------"

      db_xact_commit_start=$(curl -s --insecure http://$svs_public_dns:$http_agent_port/pt-helper/db-stats-pg | grep xact_commit | cut -d : -f2)
	  echo "db_xact_commit_start=$db_xact_commit_start"

      ./update-test-parameters.sh $svs_public_dns $http_agent_port $threads $jmeter_test_duration $jmeter_think_time
      cat $jmeter_test_path | grep HTTPSampler.domain
      cat $jmeter_test_path | grep HTTPSampler.port
      cat $jmeter_test_path | grep ThreadGroup.num_threads
      cat $jmeter_test_path | grep ThreadGroup.duration
	  cat $jmeter_test_path | grep ConstantTimer.delay
  
      svs_error_count_start=$(curl -s "http://$svs_public_dns:$http_agent_port/sv-api-ext/log/server/view" | grep "ERROR " | wc -l)
	  echo "svs_error_count_start=$svs_error_count_start"
  
      jmeter_result_file=jmeter-result-$instance_type-$threads
      echo "jmeter_result_file=$jmeter_result_file"
  
      ./jmeter/bin/jmeter -n -t /home/ec2-user/$jmeter_test_path -l /home/ec2-user/$jmeter_result_file -e -o /home/ec2-user/jmeter-web-report-$instance_type-$threads
    
      db_xact_commit_end=$(curl -s --insecure http://$svs_public_dns:$http_agent_port/pt-helper/db-stats-pg | grep xact_commit | cut -d : -f2)
	  echo "db_xact_commit_end=$db_xact_commit_end"
	  
	  dm_accuracy=$(curl -s --insecure https://$svs_public_dns:6085/SiteScope/cgi/go.exe/SiteScope | xmllint --xpath "string(//object[@name='$vs_name' and @class='monitor']/counter[@name='DataSimulationAccuracy']/@val)" -)
	  echo "dm_accuracy=$dm_accuracy"
	  pm_accuracy=$(curl -s --insecure https://$svs_public_dns:6085/SiteScope/cgi/go.exe/SiteScope | xmllint --xpath "string(//object[@name='$vs_name' and @class='monitor']/counter[@name='PerformanceSimulationAccuracy']/@val)" -)
	  echo "pm_accuracy=$pm_accuracy"
	
	  # FIXME: API bug: we must remove empty lines from the captured data as there seem to be a bug in SV API when cpuUsage is missing sometimes
	  svs_cpu_utilization_api=$(cat $svs_server_statistics_file | cut -d " " -f 1 | grep -v '^[[:space:]]*$' | st --avg)
	  echo "svs_cpu_utilization_api=$svs_cpu_utilization_api"
	  svs_cpu_utilization_api=$(echo "$svs_cpu_utilization_api/100" | bc -l | xargs printf "%0.3f")
	  echo "svs_cpu_utilization_api=$svs_cpu_utilization_api"
	  svs_db_response_time=$(cat $svs_server_statistics_file | cut -d " " -f 2 | grep -v '^[[:space:]]*$' | st --avg)
	  echo "svs_db_response_time=$svs_db_response_time"
	
	  svs_error_count_end=$(curl -s "http://$svs_public_dns:$http_agent_port/sv-api-ext/log/server/view" | grep "ERROR " | wc -l)
	  echo "svs_error_count_end=$svs_error_count_end"
	  
	  svs_error_count=$((svs_error_count_start - svs_error_count_end))
	  echo "svs_error_count=$svs_error_count"
	
      # get maximum 1 minute loadavg
      loadavg_svs=`cut -c 1-4 $loadavg_svserver_file | st --max`
      echo "max SVS loadavg:  $loadavg_svs (cpucount: $svs_cpu_count)"
	  
	  cpu_utilization_loadavg_svs=$(echo "$loadavg_svs/$svs_cpu_count" | bc -l | xargs printf "%0.3f")
	  echo "cpu_utilization_loadavg_svs=$cpu_utilization_loadavg_svs"
  	
      loadavg_jmeter=`cut -c 1-4 $loadavg_jmeter_file | st --max`
      echo "max JMeter loadavg:  $loadavg_jmeter (cpucount: $jmeter_cpu_count)"
    
      # get total elapsed time in seconds
      start_time=`tail -n +2 $jmeter_result_file | head -n 1 | cut -d "," -f1 | cut -c1-10`
      echo "start_time=$start_time"
      end_time=`tail -n 1 $jmeter_result_file | cut -d "," -f1 | cut -c1-10`
      echo "end_time=$end_time"
      total_elapsed="$(($end_time-$start_time))"
	  echo "total_elapsed=$total_elapsed"
    
	  db_xact_commit="$(($db_xact_commit_end-$db_xact_commit_start))"
	  echo "db_xact_commit=$db_xact_commit"
	  
	  db_xact_commit_per_second=$(echo "$db_xact_commit/$total_elapsed" | bc -l | xargs printf "%0.3f")
	  echo "db_xact_commit_per_second=$db_xact_commit_per_second"
	
      # write data to result file
      start_time_formatted=`date --date=@$start_time +"%Y-%m-%d %H:%M:%S"`
      end_time_formatted=`date --date=@$end_time +"%Y-%m-%d %H:%M:%S"`
	  
	  start_time_formatted_iso=`date --date=@$start_time +"%Y-%m-%dT%H:%M:%S"`
      end_time_formatted_iso=`date --date=@$end_time +"%Y-%m-%dT%H:%M:%S"`
	  
	  # get EC2 related SVS data
	  getStatsAwsEc2 $svs_instance_id $start_time_formatted_iso $end_time_formatted_iso $jmeter_test_duration
	  stats_ec2_svs=$stats_result
	  echo "stats_ec2_svs=$stats_ec2_svs"
	  
	  # get EC2 related JM data
	  instance_id_jm=$(ec2-metadata -i | cut -d " " -f2)
	  echo "instance_id_jm=$instance_id_jm"
	  getStatsAwsEc2 $instance_id_jm $start_time_formatted_iso $end_time_formatted_iso $jmeter_test_duration
	  stats_ec2_jm=$stats_result
	  echo "stats_ec2_jm=$stats_ec2_jm"
	  
	  # get EC2 related DB stats
	  db_hostname=$(echo $db_connection_string | tr ";" "\n" | grep -i "Host=." | cut -c 6-)
	  echo "db_hostname=$db_hostname"
	  # FIXME following is not enough, we should search also by private DNS and public/private IP... but OK for now since this setup was not yet tested...
	  instance_id_db=$(aws ec2 describe-instances --filters Name=dns-name,Values=$db_hostname | jq ".Reservations[0].Instances[0].InstanceId" | xargs)
	  echo "instance_id_db=$instance_id_db"
	  getStatsAwsEc2 "$instance_id_db" $start_time_formatted_iso $end_time_formatted_iso $jmeter_test_duration
	  stats_ec2_db=$stats_result
	  echo "stats_ec2_db=$stats_ec2_db"
	  
	  # get RDS stats
      rds_instance_id=$(echo $db_connection_string | tr ";" "\n" | grep rds.amazonaws | cut -c 6- | tr "." "\n" | head -n 1)
	  echo "rds_instance_id=$rds_instance_id"
	  getStatsAwsRds "$rds_instance_id" $start_time_formatted_iso $end_time_formatted_iso $jmeter_test_duration
	  stats_aws_rds=$stats_result
	  echo "stats_aws_rds=$stats_aws_rds"
	  
	  # get JMeter test stats
	  getStatsJmeter $jmeter_result_file $jmeter_test_duration
	  stats_jmeter=$stats_result
	  echo "stats_jmeter=$stats_jmeter"
	  
      result_csv_line="$start_time_formatted,$end_time_formatted,$jmeter_test_file,$jmeter_think_time,$threads,$loadavg_jmeter,\"$db_signature\",$db_type,\"$db_connection_string\",$db_xact_commit,$db_xact_commit_per_second,Yes,$sv_version,$server_data_provider,$vsid,$vs_name,$protocol_id,$data_model_id,$data_model_name,$performance_model_id,$performance_model_name,$dm_accuracy,$pm_accuracy,$cpu_model,$hypervisor_vendor,$host_os,$svs_error_count,$loadavg_svs,$cpu_utilization_loadavg_svs,$svs_cpu_utilization_api,$svs_db_response_time,\"$test_note\",$stats_jmeter,$stats_ec2_jm,$stats_ec2_svs,$stats_ec2_db,$stats_aws_rds"
      echo "result=$result_csv_line"
      echo "$result_csv_line" >> $results_file
    
      # just print out if CPU is overloaded
      if (( $(echo "$loadavg_svs > $svs_cpu_count" | bc -l) ))
      then
        echo "CPU overloaded!"
      fi
    
	  # Stops the loop of current TPS is lower then 99% of max TPS
	  # It is necessary to test to less then max TPS because on machines with many CPUs (think 64 CPUs), 
	  # when we are adding just 1 user it has so small impact on overall TPS especially if we are above 50% load, 
	  # that we can actually measure less TPS even if the CPU has still some headroom. 
	  # This is especially true when we are testing for short periods (think 2 minutes), where certain fluctiations
	  # might not average out.
	  # Recommendation:
	  # - test for more then 3 minutes
	  # - make the thread increment larger on high CPU machines
      #if [ $(( $max_tps * 0.99 )) -le "$TPS" ] ; then
	  #  # checks if we have new max TPS
      #  echo "TPS did not drop below 99% of max TPS ($max_tps) -> Increasing load!"
      #else
      #  echo "TPS less then 98% of MAX TPS -> Breaking!"
      #  break
      #fi
	  
	  stop_in="$(($stop_in-1))"
	  echo "stop_in=$stop_in"
	  
	  # above is not yet tested, so comment out for now and using below
	  # Stops the loop if current TPS is lower then max TPS
	  # integer comparison is not enough with low TPS numbers 1-20:
	  #if [ "$max_tps" -le "$jmeter_TPS" ] ; then
	  if (( $(echo "$max_tps < $jmeter_TPS" | bc -l) )); then
	    echo "New Max TPS!"
		max_tps=$jmeter_TPS
      else
	    if [ "$stop_in" -lt  "0" ]; then
          echo "Scheduling cycle break after 10 more iterations!"
		  stop_in=10
		fi
      fi
	  
	  echo "max_tps=$max_tps"
	  
      #sleep 1 minute to lower loadavg. Should not matter that much if load is continually increasing
      echo "Cooldown time for 60 seconds..."
      sleep 60
	  
	  if [ "$stop_in" -eq "0" ] ; then
	    echo "Breaking now!"
	    break
      fi
    
    done
	
	# undeploy tested VS
	./sv-undeploy-vs.sh $vsid https://$svs_public_dns:6085/api $svs_user $svs_password
    
  done 4< test-services.txt
  
  kill $loadavg_svserver_pid
  kill $svs_cpu_utilization_api_pid
  ./aws-terminate-instance.sh $svs_instance_id

done 3< test-instance-types.txt

echo "Finished"
date

# need to kill, so the loadavg background jobs are killed as well
kill $loadavg_jmeter_pid
