#!/bin/bash

set -xe

source variables.sh

#Export the DB from PRODUCTION
ssh -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no -tt ${WP_PRD_SSH} << EOF
cd ~/sites/${WP_PRD_INSTALL};
wp db export back-for-dev.sql;
exit;
EOF

#Rsync the DB export, Plugins, and Uploads from PRODUCTION
cd /var/www/${PROJECT_NAME};
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_PRD_SSH}:sites/${WP_PRD_INSTALL}/back-for-dev.sql /var/www/${PROJECT_NAME}/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_PRD_SSH}:sites/${WP_PRD_INSTALL}/wp-content/uploads /var/www/${PROJECT_NAME}/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_PRD_SSH}:sites/${WP_PRD_INSTALL}/wp-content/plugins /var/www/${PROJECT_NAME}/;

#Rsync the DB export, Plugins, and Uploads to DEV
cd /var/www/${PROJECT_NAME};
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/back-for-dev.sql ${WP_DEV_SSH}:sites/${WP_DEV_INSTALL}/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/uploads/ ${WP_DEV_SSH}:sites/${WP_DEV_INSTALL}/wp-content/uploads/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/plugins/ ${WP_DEV_SSH}:sites/${WP_DEV_INSTALL}/wp-content/plugins/;

#Import PROD DB and search-replace URLs; then import users
ssh -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no -tt ${WP_DEV_SSH} << EOF
cd ~/sites/${WP_DEV_INSTALL};
wp db export --tables=wp_usermeta,wp_users dev-users.sql;
wp db import back-for-dev.sql;
wp search-replace "://${WP_PRD_URL}" "://${WP_DEV_URL}" --all-tables --precise;
wp search-replace "://${WP_PRD_WWW_URL}" "://${WP_DEV_URL}" --all-tables --precise;
wp search-replace "http://${WP_DEV_URL}" "https://${WP_DEV_URL}" --all-tables --precise;
wp db import dev-users.sql;
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