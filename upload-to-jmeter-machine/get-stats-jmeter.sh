getStatsJmeterHeaders() {
  echo "=== getStatsJmeterHeaders() ========="
  stats_headers="JM TPS,JM Requests,JM RT Min,JM RT Max,JM RT Avg,JM Std Dev,JM Errors,JM Req Bytes Avg,JM Res Bytes Avg,JM In MB/s,JM Out MB/s,JM In MB,JM Out MB"
  echo "stats_headers=$stats_headers"
}

getStatsJmeter() {
  echo "=== getStatsJmeter($1,$2) ========="

  local _jmeter_result_file=$1
  echo "_jmeter_result_file=$_jmeter_result_file"
  local _jmeter_test_duration=$2
  echo "_jmeter_test_duration=$_jmeter_test_duration"
  
  local _response_time_stats=$(tail -n +2 $_jmeter_result_file | cut -d "," -f2 | st --no-header --N --min --max --avg --stddev --delimiter "," --format "%0.3f")
  # following var used outside
  N=$(echo $_response_time_stats | cut -d "," -f1 | xargs printf "%0.0f")
  echo "N=$N"
  
  # following var used outside
  jmeter_TPS=$(echo "$N/$_jmeter_test_duration" | bc -l | xargs printf "%0.2f")
  echo "jmeter_TPS=$jmeter_TPS";
  
  local _jmeter_error_count=$(tail -n +2 $_jmeter_result_file | cut -d "," -f8 | grep false | wc -l)
  echo "_jmeter_error_count=$_jmeter_error_count"
  	  
  local _jmeter_bytes_in_stats=$(tail -n +2 $_jmeter_result_file | cut -d "," -f10 | st --no-header --sum --avg --delimiter "," --format "%f")
  local _jmeter_bytes_in_sum=$(echo $_jmeter_bytes_in_stats | cut -d "," -f1)
  local _jmeter_Mbytes_in_sum=$(echo "$_jmeter_bytes_in_sum/1000000" | bc -l | xargs printf "%0.4f")
  echo "_jmeter_Mbytes_in_sum=$_jmeter_Mbytes_in_sum"
  
  local _jmeter_bytes_in_avg=$(echo $_jmeter_bytes_in_stats | cut -d "," -f2 | xargs printf "%0.4f")
  echo "_jmeter_bytes_in_avg=$_jmeter_bytes_in_avg"
  local _jmeter_bytes_in_MBps=$(echo "$_jmeter_bytes_in_sum/$_jmeter_test_duration/1000000" | bc -l | xargs printf "%0.4f")
  echo "_jmeter_bytes_in_MBps=$_jmeter_bytes_in_MBps"
  
  local _jmeter_bytes_out_stats=$(tail -n +2 $_jmeter_result_file | cut -d "," -f11 | st --no-header --sum --avg --delimiter "," --format "%f")
  local _jmeter_bytes_out_sum=$(echo $_jmeter_bytes_out_stats | cut -d "," -f1)
  local _jmeter_Mbytes_out_sum=$(echo "$_jmeter_bytes_out_sum/1000000" | bc -l | xargs printf "%0.4f")
  echo "_jmeter_Mbytes_out_sum=$_jmeter_Mbytes_out_sum"
  local _jmeter_bytes_out_avg=$(echo $_jmeter_bytes_out_stats | cut -d "," -f2 | xargs printf "%0.4f")
  echo "_jmeter_bytes_out_avg=$_jmeter_bytes_out_avg"
  local _jmeter_bytes_out_MBps=$(echo "$_jmeter_bytes_out_sum/$_jmeter_test_duration/1000000" | bc -l | xargs printf "%0.4f")
  echo "_jmeter_bytes_out_MBps=$_jmeter_bytes_out_MBps"
  
  stats_result="$jmeter_TPS,$_response_time_stats,$_jmeter_error_count,$_jmeter_bytes_out_avg,$_jmeter_bytes_in_avg,$_jmeter_bytes_in_MBps,$_jmeter_bytes_out_MBps,$_jmeter_Mbytes_in_sum,$_jmeter_Mbytes_out_sum"
  #echo "stats_result=$stats_result"
}