# install python deps
apt-get update \
&& apt-get install -y python-pip python-pandas python-numpy \
&& pip install --upgrade pip \
&& pip install -r ./research/data/requirements.txt

# install web onion tool
apt-get install -y apache2 \
        apache2-utils apache2.2-bin \
        libapache2-mod-php5 \
        php5-cli php5-common php5-mysql \
        && cd ./tools/php && ./install.sh -n \
        && service apache2 restart \
        && cd ../..