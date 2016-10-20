mkdir -p /VoteSUp/log
/usr/bin/forever /VoteSUp/app.js > /VoteSUp/log/server.log 2>&1 &
