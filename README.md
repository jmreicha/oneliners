# one-liners

This is a place to store useful command line commands.  Feel free to fork and/or PR if you have any additions.

**Check a public IP**

 * `curl http://whatismyip.org/`
 * `curl ifconfig.me`

**Dig**

 * Check domain with specific NS - `dig <domain.com> @<ns-server>`
 * Get NS records for a site - `dig <domain.com> ns`

**Disk checks**

 * Top 50 file sizes - `du -ah / | sort -n -r | head -n 50`
 * Show directory sizes (must not be in root directory) - `du -sh  *`
 * Check disk usage per directory - `du -h <dir> | grep '[0-9\.]\+G’`
 * Look for growing directories - `watch -n 10 df -ah`
 * Ncurses based disk usage - `ncdu -q`

**Docker**

 * Remove a group of images - `docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi`
 * Remove all untagged containers - `docker rm $(docker ps -aq --filter status=exited)`
 * Remove all untagged images - `docker rmi $(docker images -q --filter dangling=true)`
 * Install on Ubuntu - `curl -sSL https://get.docker.com/ubuntu/ | sudo sh`
 * Get stats from all containers on a host - `docker ps -q | xargs docker stats`

**Git**

 * Remove deleted files from repo - `git rm $(git ls-files --deleted)`
 * Reset git repo (dangerous) - `git reset --hard HEAD`
 * Reset and remove untracked changes in repo - `git clean -xdf`

**Grep**

 * Look through all files in current dir for word “foo” - `grep -R "foo” .`
 * View last ten lines of output - `grep -i -C 10 "invalid view source” /var/log/info.log`
 * Display line number of message - `grep -n “pattern” <file>`
 * Find and replace string - `grep -rl "somestring" ./ | xargs sed -i "" "s/somestring/newstring/g"`

**Iptables**

 * Check nat rules for ip redirection - `iptables -nvL -t nat`

**Password generation**

 * Create hash from password - `openssl passwd -crypt <password>`
 * Generate random 8 character password - `makepasswd -count 1 -minchars 8`
 * Create .passwd file with user and random password - `sudo htpasswd -c /etc/nginx/.htpasswd <user>`

**Remove files over 30 days old**

 * `find . -mtime +30 | xargs rm -rf`

**SS (socket info)**

 * Check ports that are listening - `ss -ltn`
 * Print process and listening port - `ss -ltp`

**SSH**

 * Generate generic ssh key pair - `ssh-keygen -q -t rsa -f ~/.ssh/<name> -N '' -C <name>`

**Tail log with colored output**

 * `grc tail -f /var/log/filename`

**Tmux**

 * Kill stuck tmux window - `tmux kill-window -t X`

