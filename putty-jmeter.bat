call env.bat
start putty.exe -ssh -2 -i "%CERTIFICATE_PPK%" -l ec2-user %JMETER_HOST%