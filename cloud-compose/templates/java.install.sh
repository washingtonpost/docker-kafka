# java.install.sh
yum install -y java-1.8.0-openjdk-devel
echo 'export JAVA_HOME=/usr/lib/jvm/java' > /etc/profile.d/java_home.sh
