call env.bat
pscp -i %CERTIFICATE_PPK% upload-to-sv-machine\* ec2-user@%SV_SERVER_HOST%:/home/ec2-user/