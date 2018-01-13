# one-liners

This is a place to store useful command line commands.  Feel free to fork and/or PR if you have any additions.

Please check out the [script](https://github.com/jmreicha/oneliners/tree/master/script) directory for more examples.

**Check which ports are listening**

 * `ss -ltn`
 * `lsof -ni | grep LISTEN`

**Check a public IP**

 * `curl http://whatismyip.org/`
 * `curl ifconfig.me`

**Return the IP of an interface**

 * `ifconfig en0 | grep --word-regexp inet | awk '{print $2}'`
 * `ip add show eth0 | awk '/inet/ {print $2}' | cut -d/ -f1 | head -1`
 
 
**Replace all occurrences of string in a directory**

 * Find and replace string - `grep -rl "oldstring" ./ | xargs sed -i "" "s/oldstring/newstring/g"`

**Dig**

 * Check domain with specific NS - `dig <domain.com> @<ns-server>`
 * Get NS records for a site - `dig <domain.com> ns`

**Disk checks**

 * Top 50 file sizes - `du -ah / | sort -n -r | head -n 50`
 * Show directory sizes (must not be in root directory) - `du -sh  *`
 * Check disk usage per directory - `du -h <dir> | grep '[0-9\.]\+G’`
 * Look for growing directories - `watch -n 10 df -ah`
 * Ncurses based disk usage - `ncdu -q`
 * Colorized output of du - `du -x --max-depth=1|sort -rn|awk -F / -v c=$COLUMNS 'NR==1{t=$1} NR>1{r=int($1/t*c+.5); b="\033[1;31m"; for (i=0; i<r; i++) b=b"#"; printf " %5.2f%% %s\033[0m %s\n", $1/t*100, b, $2}'|tac`

**Docker**

 * Remove a group of images - `docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi`
 * Remove all untagged containers - `docker rm $(docker ps -aq --filter status=exited)`
 * Remove all untagged images - `docker rmi $(docker images -q --filter dangling=true)`
 * Install on Ubuntu - `curl -sSL https://get.docker.com/ubuntu/ | sudo sh`
 * Get stats from all containers on a host - `docker ps -q | xargs docker stats`
 * Tail last 300 lines of logs for a container - `docker logs --tail=300 -f <container_id>`
 * Remove old (dangling) Docker volumes - `docker volume rm $(docker volume ls -qf dangling=true)`

**Git**

 * Remove deleted files from repo - `git rm $(git ls-files --deleted)`
 * Reset git repo (dangerous) - `git reset --hard HEAD`
 * Reset and remove untracked changes in repo - `git clean -xdf`
 * Ignore certificates when cloning via HTTPS - `git config --global http.sslVerify false`
 * Pull changes and remove stale branches - `git pull --prune`

**Grep**

 * Look through all files in current dir for word “foo” - `grep -R "foo” .`
 * View last ten lines of output - `grep -i -C 10 "invalid view source” /var/log/info.log`
 * Display line number of message - `grep -n “pattern” <file>`

**Iptables**

 * Check nat rules for ip redirection - `iptables -nvL -t nat`

**Nginx**

 * Check installed modules - `nginx -V`
 * Pretty print installed modules - `2>&1 nginx -V | xargs -n1`
 * Test a configuration without reloading - `nginx -t`
 * Stop all nginx processes - `nginx -s stop`
 * Start all nginx processes - `nginx -s start`
 * Restart all nginx processes - `nginx -s restart`
 * Realod nginx configuration (without restarting) - `nginx -s reload`

**Nmap**

* Check single port on single host - `nmap -p <port> <host/IP>`
* Intrusive port scan on a single host - `nmap -sS <host/IP>`
* Top ten port on a single host - `nmap --top-ports 10 <host/IP>`

**Password generation**

 * Create hash from password - `openssl passwd -crypt <password>`
 * Generate random 8 character password (Ubuntu) - `makepasswd -count 1 -minchars 8`
 * Create .passwd file with user and random password - `sudo htpasswd -c /etc/nginx/.htpasswd <user>`

**Removing files**

 * Remove files over 30 days old - `find . -mtime +30 | xargs rm -rf`
 * Remove files older than 7 day starting with 'backup' - `find . -type f -name "backup*" -mtime +7 -exec rm {} \;`
 
**SS (socket info)**

 * Check ports that are listening - `ss -ltn`
 * Print process and listening port - `ss -ltp`

**SSH**

 * Generate generic ssh key pair - `ssh-keygen -q -t rsa -f ~/.ssh/<name> -N '' -C <name>`

**Tail log with colored output**

 * `grc tail -f /var/log/filename`

**Tmux**

 * Kill stuck tmux window - `tmux kill-window -t X`

**vim**

 * Change/update contents of a line - `Vc`
 * Select text inside quotes - `vi"`
