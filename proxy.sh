$(pwd)/mysql-src/mysql-proxy-0.8.5/bin/mysql-proxy         \
                     --plugins=proxy --event-threads=4             \
                     --max-open-files=1024                         \
                     --proxy-lua-script=$EDBDIR/mysqlproxy/wrapper.lua \
                     --proxy-address=127.0.0.1:3307                \
                     --proxy-backend-addresses=localhost:3306
