# install python deps
apt-get install -y python-pip python-pandas python-numpy \
&& pip install --upgrade pip \
&& pip install -r /opt/cryptdb/data/requirements.txt

# install web onion tool
apt-get install -y apache2 \
        apache2-utils apache2-bin \
        libapache2-mod-php5 \
        php5-cli php5-common php5-mysql php5 \
        && /copt/cryptdb/tools/php/install.sh \
        && service apache2 restart \
        && cd $(EDBDIR)