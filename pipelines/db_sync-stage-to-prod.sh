#!/bin/bash

set -xe

source variables.sh

#Export the DB from STAGE
ssh -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no -tt ${WP_STG_SSH} << EOF
cd ~/sites/${WP_STG_INSTALL};
wp db export --exclude_tables=wp_usermeta,wp_users back-for-prod.sql;
touch db_back_.txt;
rm db_back_* &> /dev/null;
mv back-for-prod.sql db_back_$(date '+%m-%d-%Y').sql;
exit;
EOF

#Rsync the DB export from STAGE
cd /var/www/${PROJECT_NAME};
touch db_back_.txt;
rm db_back_* &> /dev/null;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_STG_SSH}:sites/${WP_STG_INSTALL}/db_back_* /var/www/${PROJECT_NAME}/;

#Rsync the DB export, Plugins, and Uploads from STAGE
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_STG_SSH}:sites/${WP_STG_INSTALL}/wp-content/uploads /var/www/${PROJECT_NAME}/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' ${WP_STG_SSH}:sites/${WP_STG_INSTALL}/wp-content/plugins /var/www/${PROJECT_NAME}/;

#Sync the Uploads & Plugins to PROD
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/db_back_* ${WP_PRD_SSH}:sites/${WP_PRD_INSTALL}/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/uploads/ ${WP_PRD_SSH}:sites/${WP_PRD_INSTALL}/wp-content/uploads/;
rsync -rav -e 'ssh -p 22 -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no' /var/www/${PROJECT_NAME}/plugins/ ${WP_PRD_SSH}:sites/${WP_PRD_INSTALL}/wp-content/plugins/;

#Import STAGE DB and search-replace URLs; then import users
ssh -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o StrictHostKeyChecking=no -tt ${WP_PRD_SSH} << EOF
cd ~/sites/${WP_PRD_INSTALL};
wp db export backup.sql
wp db export --tables=wp_usermeta,wp_users prod-users.sql;
wp db import db_back_$(date '+%m-%d-%Y').sql;
wp search-replace "://${WP_STG_URL}" "://${WP_PRD_URL}" --all-tables --precise;
wp search-replace "http://${WP_PRD_URL}" "https://${WP_PRD_URL}" --all-tables --precise;
wp search-replace "https://${WP_PRD_URL}" "https://${WP_PRD_WWW_URL}" --all-tables --precise;
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