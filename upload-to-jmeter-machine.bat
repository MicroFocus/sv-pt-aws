call env.bat
ssh ec2-user@%JMETER_HOST% -i "%CERTIFICATE_PEM%" "rm -rf /home/ec2-user/jmeter-tests"
ssh ec2-user@%JMETER_HOST% -i "%CERTIFICATE_PEM%" "rm -rf /home/ec2-user/virtual-services"
ssh ec2-user@%JMETER_HOST% -i "%CERTIFICATE_PEM%" "rm -rf /home/ec2-user/SVConfigurator"
pscp -r -i %CERTIFICATE_PPK% upload-to-jmeter-machine\* ec2-user@%JMETER_HOST%:/home/ec2-user/
ssh ec2-user@%JMETER_HOST% -i "%CERTIFICATE_PEM%" "find /home/ec2-user -type f -name '*.sh' -exec chmod +x {} \;"