export TERM=xterm
export CRYPTDB_MODE=multi
export ENC_BY_DEFAULT=false
export EDBDIR=/opt/cryptdb
#export CRYPTDB_SHADOW=/tmp/shadow-db
export CRYPTDB_PROXY_DEBUG=tru
export LD_LIBRARY_PATH=$EDBDIR/obj/
exec $EDBDIR/bins/proxy-bin/bin/mysql-proxy \
                 --plugins=proxy --event-threads=4 \
                 --max-open-files=1024 \
                 --proxy-lua-script=$EDBDIR/mysqlproxy/wrapper.lua \
                 --proxy-address=127.0.0.1:3307 \
                 --proxy-backend-addresses=127.0.0.1:3306