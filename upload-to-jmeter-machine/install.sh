sudo dnf install java -y
wget https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.6.2.tgz
tar zxvf apache-jmeter-5.6.2.tgz
mv apache-jmeter-5.6.2 jmeter

# install statistics CLI tool
sudo dnf install git -y
git clone https://github.com/nferraz/st.git
cd st
sudo dnf install perl-devel
perl Makefile.PL
make
make test
sudo make install