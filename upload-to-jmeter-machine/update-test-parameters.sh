echo "Updating test parameters..."
sed --in-place -e "s/<stringProp name=\"HTTPSampler.domain\">.*<\/stringProp>/<stringProp name=\"HTTPSampler.domain\">$1<\/stringProp>/g" jmeter-tests/*.jmx
sed --in-place -e "s/<stringProp name=\"HTTPSampler.port\">.*<\/stringProp>/<stringProp name=\"HTTPSampler.port\">$2<\/stringProp>/g" jmeter-tests/*.jmx
sed --in-place -e "s/<stringProp name=\"ThreadGroup.num_threads\">.*<\/stringProp>/<stringProp name=\"ThreadGroup.num_threads\">$3<\/stringProp>/g" jmeter-tests/*.jmx
sed --in-place -e "s/<stringProp name=\"ThreadGroup.duration\">.*<\/stringProp>/<stringProp name=\"ThreadGroup.duration\">$4<\/stringProp>/g" jmeter-tests/*.jmx
sed --in-place -e "s/<stringProp name=\"ConstantTimer.delay\">.*<\/stringProp>/<stringProp name=\"ConstantTimer.delay\">$5<\/stringProp>/g" jmeter-tests/*.jmx

echo "Done."