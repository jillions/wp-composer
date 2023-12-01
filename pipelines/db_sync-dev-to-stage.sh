#!/bin/bash

set -xe

source variables.sh

#Export the DB from DEVELOP
ssh -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no -tt ${WP_DEV_SSH} << EOF
cd ~/sites/${WP_DEV_INSTALL};
wp plugin update --all --dry-run | grep 'Available plugin updates' &> /dev/null
if [ $? == 0 ]; then
   echo "WARNING: PLUGINS ARE NOT UP TO DATE"
fi
wp db export back-for-stage.sql;
exit;
EOF

#Rsync the DB export, Plugins, and Uploads from DEVELOP
cd /var/www/${PROJECT_NAME};
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_DEV_SSH}:sites/${WP_DEV_INSTALL}/back-for-stage.sql /var/www/${PROJECT_NAME}/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_DEV_SSH}:sites/${WP_DEV_INSTALL}/wp-content/plugins /var/www/${PROJECT_NAME}/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_DEV_SSH}:sites/${WP_DEV_INSTALL}/wp-content/uploads /var/www/${PROJECT_NAME}/;

#Export wp_users from PROD
ssh -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no -tt ${WP_PRD_SSH} << EOF
cd ~/sites/${WP_PRD_INSTALL};
wp db export --tables=wp_usermeta,wp_users prod-users.sql;
exit;
EOF

#Rsync prod-users.sql from PROD
cd /var/www/${PROJECT_NAME};
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_PRD_SSH}:sites/${WP_PRD_INSTALL}/prod-users.sql /var/www/${PROJECT_NAME}/;

#Rsync DB exports, Plugins, and Uploads to STAGE
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/back-for-stage.sql ${WP_STG_SSH}:sites/${WP_STG_INSTALL}/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/prod-users.sql ${WP_STG_SSH}:sites/${WP_STG_INSTALL}/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/uploads/ ${WP_STG_SSH}:sites/${WP_STG_INSTALL}/wp-content/uploads/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/plugins/ ${WP_STG_SSH}:sites/${WP_STG_INSTALL}/wp-content/plugins/;

#Import DEVELOP DB and search-replace URLs; then import users
ssh -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no -tt ${WP_STG_SSH} << EOF
cd ~/sites/${WP_STG_INSTALL};
wp db export backup.sql
wp db import back-for-stage.sql;
wp search-replace "://${WP_DEV_URL}" "://${WP_STG_URL}" --all-tables --precise;
wp search-replace "http://${WP_STG_URL}" "https://${WP_STG_URL}" --all-tables --precise;
wp db import prod-users.sql;
wp cache flush;
wp cdn-cache flush;
exit;
EOF

#Cleanup After Yourself
cd /var/www/${PROJECT_NAME};
rm -rf uploads;
rm -rf plugins;
rm -rf *.sql;
echo "all clean."