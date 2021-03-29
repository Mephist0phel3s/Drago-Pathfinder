#!/usr/bin/env bash
set -e

echo -e "\t\tYour pathfinder is up! Visit it at https://$DOMAIN"
cat << "EOF"

                           .       .
                          / `.   .' \
                  .---.  <    > <    >  .---.
                  |    \  \ - ~ ~ - /  /    |
                   ~-..-~             ~-..-~
               \~~~\.'                    `./~~~/
     .-~~^-.    \__/                        \__/
   .'  O    \     /               /       \  \
  (_____,    `._.'               |         }  \/~~~/
   `----.          /       }     |        /    \__/
         `-.      |       /      |       /      `. ,~~|
             ~-.__|      /_ - ~ ^|      /- _      `..-'   f: f:
                  |     /        |     /     ~-.     `-. _||_||_
                  |_____|        |_____|         ~ - . _ _ _ _ _>
                    (c) Stegosaurus by Michael John Wagoner
                                                         
EOF
printf "${NC}"

envsubst '$DOMAIN' </etc/nginx/sites_enabled/templateSite.conf >/etc/nginx/sites_enabled/site.conf
envsubst  </var/www/html/pathfinder/app/templateEnvironment.ini >/var/www/html/pathfinder/app/environment.ini
envsubst  </var/www/html/pathfinder/app/templateConfig.ini >/var/www/html/pathfinder/app/config.ini
envsubst  </etc/zzz_custom.ini >/etc/php7/conf.d/zzz_custom.ini
htpasswd   -c -b -B  /etc/nginx/.setup_pass pf "$APP_PASSWORD"
crontab  /var/crontab.txt
exec "$@"
