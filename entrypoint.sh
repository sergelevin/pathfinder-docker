#!/bin/bash
function replace_setting() {
    sed -i -E "s/$1/$2/g" $3
}
echo "Replacing settings"
replace_setting "^SERVER\s*=\s*.*$" "SERVER = ${SERVER}" "/var/www/pathfinder/app/environment.ini"
replace_setting "^DB_PF_DNS\s*=\s*.*$" "DB_PF_DNS                         =   mysql:host=${DB_HOST};port=3306;" "/var/www/pathfinder/app/environment.ini"
replace_setting "^DB_UNIVERSE_DNS\s*=\s*.*$" "DB_UNIVERSE_DNS                         =   mysql:host=${DB_HOST};port=3306;" "/var/www/pathfinder/app/environment.ini"
replace_setting "^URL\s*=\s*.*$" "URL                         =   ${SCHEME}${URL}" "/var/www/pathfinder/app/environment.ini"
replace_setting "DB_PF_PASS\s*=\s*.*" "DB_PF_PASS                  =   ${MYSQL_PASSWORD}" "/var/www/pathfinder/app/environment.ini"
replace_setting "DB_PF_USER\s*=\s*.*" "DB_PF_USER                  =   ${MYSQL_USER}" "/var/www/pathfinder/app/environment.ini"
replace_setting "DB_PF_NAME\s*=\s*.*" "DB_PF_NAME           =   ${DB_NAME}" "/var/www/pathfinder/app/environment.ini"
replace_setting "DB_UNIVERSE_NAME\s*=\s*.*" "DB_UNIVERSE_NAME           =   eve_universe" "/var/www/pathfinder/app/environment.ini"
replace_setting "DB_UNIVERSE_PASS\s*=\s*.*" "DB_UNIVERSE_PASS            =   ${MYSQL_PASSWORD}" "/var/www/pathfinder/app/environment.ini"
replace_setting "DB_UNIVERSE_USER\s*=\s*.*" "DB_UNIVERSE_USER            =   ${MYSQL_USER}" "/var/www/pathfinder/app/environment.ini"
replace_setting "CCP_SSO_CLIENT_ID\s*=\s*.*" "CCP_SSO_CLIENT_ID           =   ${CCP_SSO_CLIENT_ID}" "/var/www/pathfinder/app/environment.ini"
replace_setting "CCP_SSO_SECRET_KEY\s*=\s*.*" "CCP_SSO_SECRET_KEY          =   ${CCP_SSO_SECRET_KEY}" "/var/www/pathfinder/app/environment.ini"
replace_setting "CHARACTER\s*=\s*.*" "CHARACTER          =   ${CHARACTER}" "/var/www/pathfinder/app/pathfinder.ini"
replace_setting "CORPORATION\s*=\s*.*" "CORPORATION          =   ${CORPORATION}" "/var/www/pathfinder/app/pathfinder.ini"
replace_setting "ALLIANCE\s*=\s*.*" "ALLIANCE          =   ${ALLIANCE}" "/var/www/pathfinder/app/pathfinder.ini"
replace_setting "domain.com" "${URL}" "/etc/nginx/sites-available/default"
replace_setting "web\s*=\s*.*" "web     = ${CronWebUI}" "/var/www/pathfinder/app/cron.ini"
if [ "${SETUP}" != "True" ]; then
 replace_setting "^GET @setup.*$" "" "/var/www/pathfinder/app/routes.ini"
fi

if [ "${UseRedis}" != "False" ]; then
 #echo "Setting Redis settings: "
 #echo "Updating config.ini redis cache"
 replace_setting "CACHE\s*=\s*.*" "CACHE           =   redis=${REDIS_HOST}:${REDIS_PORT}:${REDIS_DB}" "/var/www/pathfinder/app/config.ini"

 #echo "updating session cache"
 replace_setting "SESSION_CACHE\s*=\s*.*" "SESSION_CACHE = ${SESSION_CACHE}" "/var/www/pathfinder/app/config.ini"
 echo "setting php.ini session.save_path"
 sed -E -i -e "s/session.save_handler\s*=\s*.*/session.save_handler = redis/g" /etc/php/7.2/fpm/php.ini  
 sed -E -i -e "s/session.save_path\s*=\s*.*/session.save_path = \"tcp:\/\/${REDIS_HOST}:${REDIS_PORT}\"/g" /etc/php/7.2/fpm/php.ini  
fi

if [ "${PHP_MAX_INPUT_VARS}" != "" ]; then
 sed -E -i -e "s/max_input_vars\s*=\s*.*/max_input_vars = ${PHP_MAX_INPUT_VARS}/g" /etc/php/7.2/fpm/php.ini
fi

if [ "${SET_ROUTE_TTL}" != "False" ]; then
 #For remote redis cache, need to set the ttl for each route to 1.
 replace_setting "GET\|POST\s*\/api\/@controller\/@action\s*\[ajax\]\s*=\s*.*" "GET|POST \/api\/@controller\/@action                [ajax] = {{ @NAMESPACE }}\\\\Controller\\\\Api\\\\@controller->@action, ${ROUTE_TTL}, 512" "/var/www/pathfinder/app/routes.ini"
 replace_setting "GET\|POST\s*\/api\/@controller\/@action\/@arg1\s*\[ajax\]\s*=\s*.*" "GET|POST \/api\/@controller\/@action\/@arg1          [ajax] = {{ @NAMESPACE }}\\\\Controller\\\\Api\\\\@controller->@action, ${ROUTE_TTL}, 512" "/var/www/pathfinder/app/routes.ini"
 replace_setting "GET\|POST\s*\/api\/@controller\/@action\/@arg1\/@arg2\s*\[ajax\]\s*=\s*.*" "GET|POST \/api\/@controller\/@action\/@arg1\/@arg2    [ajax] = {{ @NAMESPACE }}\\\\Controller\\\\Api\\\\@controller->@action, ${ROUTE_TTL}, 512" "/var/www/pathfinder/app/routes.ini"
 replace_setting "POST\s*\/api\/Map\/updateUnloadData\s*=\s*.*" "POST \/api\/Map\/updateUnloadData                         = {{ @NAMESPACE }}\\\\Controller\\\\Api\\\\Map->updateUnloadData, ${ROUTE_TTL}, 512" "/var/www/pathfinder/app/routes.ini"
 replace_setting "\/api\/rest\/@controller\*\s*\[ajax\]\s*=\s*.*" "\/api\/rest\/@controller*                          [ajax] = {{ @NAMESPACE }}\\\\Controller\\\\Api\\\\Rest\\\\@controller, ${ROUTE_TTL}, 512" "/var/www/pathfinder/app/routes.ini"
 replace_setting "\/api\/rest\/@controller\/@id\s*\[ajax\]\s*=\s*.*" "\/api\/rest\/@controller\/@id                       [ajax] = {{ @NAMESPACE }}\\\\Controller\\\\Api\\\\Rest\\\\@controller, ${ROUTE_TTL}, 512" "/var/www/pathfinder/app/routes.ini"
fi

if [ "${UseWebSockets}" != "False" ]; then
 replace_setting ";SOCKET_HOST" "SOCKET_HOST" "/var/www/pathfinder/app/environment.ini"
 replace_setting ";SOCKET_PORT" "SOCKET_PORT" "/var/www/pathfinder/app/environment.ini"
fi

if [ "${UseCustomSmtpServer}" != "False" ]; then
 replace_setting "CUSTOM_SMTP_HOST\s*=\s*.*" "SMTP_HOST                   =   ${CUSTOM_SMTP_HOST}" "/var/www/pathfinder/app/environment.ini"
 replace_setting "CUSTOM_SMTP_PORT\s*=\s*.*" "SMTP_PORT                   =   ${CUSTOM_SMTP_PORT}" "/var/www/pathfinder/app/environment.ini"
 replace_setting "CUSTOM_SMTP_SCHEME\s*=\s*.*" "SMTP_SCHEME                 =  ${CUSTOM_SMTP_PORT}" "/var/www/pathfinder/app/environment.ini"
 replace_setting "CUSTOM_SMTP_USER\s*=\s*.*" "SMTP_USER                =  ${CUSTOM_SMTP_USER}" "/var/www/pathfinder/app/environment.ini"
 replace_setting "CUSTOM_SMTP_PASS\s*=\s*.*" "SMTP_PASS                =  ${CUSTOM_SMTP_PASS}" "/var/www/pathfinder/app/environment.ini"
 replace_setting "CUSTOM_SMTP_FROM\s*=\s*.*" "SMTP_FROM                =  ${CUSTOM_SMTP_FROM}" "/var/www/pathfinder/app/environment.ini"
 replace_setting "CUSTOM_SMTP_ERROR\s*=\s*.*" "SMTP_ERROR                =  ${CUSTOM_SMTP_ERROR}" "/var/www/pathfinder/app/environment.ini"
fi

echo "[PATHFINDER]" >> /var/www/pathfinder/conf/pathfinder.ini
echo "NAME                        =   ${NAME}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "" >> /var/www/pathfinder/conf/pathfinder.ini
echo "[PATHFINDER.MAP.PRIVATE]" >> /var/www/pathfinder/conf/pathfinder.ini
echo "LIFETIME                         =   ${PrivateLIFETIME}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "MAX_COUNT                       =   ${PrivateMAX_COUNT}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "MAX_SHARED                        =   ${PrivateMAX_SHARED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "MAX_SYSTEMS                        =   ${PrivateMAX_SYSTEMS}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "LOG_ACTIVITY_ENABLED                        =   ${PrivateLOG_ACTIVITY_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "LOG_HISTORY_ENABLED                        =   ${PrivateLOG_HISTORY_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_HISTORY_SLACK_ENABLED                        =   ${PrivateSEND_HISTORY_SLACK_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_RALLY_SLACK_ENABLED                        =   ${PrivateSEND_RALLY_SLACK_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_HISTORY_DISCORD_ENABLED                        =   ${PrivateSEND_HISTORY_DISCORD_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_RALLY_DISCORD_ENABLED                        =   ${PrivateSEND_RALLY_DISCORD_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_RALLY_Mail_ENABLED                        =   ${PrivateSEND_RALLY_Mail_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "[PATHFINDER.MAP.CORPORATION]" >> /var/www/pathfinder/conf/pathfinder.ini
echo "LIFETIME                        =   ${CorpLIFETIME}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "MAX_COUNT                       =   ${CorpMAX_COUNT}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "MAX_SHARED                      =   ${CorpMAX_SHARED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "MAX_SYSTEMS                     =   ${CorpMAX_SYSTEMS}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "LOG_ACTIVITY_ENABLED            =   ${CorpLOG_ACTIVITY_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "LOG_HISTORY_ENABLED             =   ${CorpLOG_HISTORY_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_HISTORY_SLACK_ENABLED      =   ${CorpSEND_HISTORY_SLACK_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_RALLY_SLACK_ENABLED        =   ${CorpSEND_RALLY_SLACK_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_HISTORY_DISCORD_ENABLED    =   ${CorpSEND_HISTORY_DISCORD_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_RALLY_DISCORD_ENABLED      =   ${CorpSEND_RALLY_DISCORD_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_RALLY_Mail_ENABLED         =   ${CorpSEND_RALLY_Mail_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "[PATHFINDER.MAP.ALLIANCE]" >> /var/www/pathfinder/conf/pathfinder.ini
echo "LIFETIME                        =   ${allianceLIFETIME}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "MAX_COUNT                       =   ${allianceMAX_COUNT}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "MAX_SHARED                      =   ${allianceMAX_SHARED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "MAX_SYSTEMS                     =   ${allianceMAX_SYSTEMS}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "LOG_ACTIVITY_ENABLED            =   ${allianceLOG_ACTIVITY_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "LOG_HISTORY_ENABLED             =   ${allianceLOG_HISTORY_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_HISTORY_SLACK_ENABLED      =   ${allianceSEND_HISTORY_SLACK_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_RALLY_SLACK_ENABLED        =   ${allianceSEND_RALLY_SLACK_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_HISTORY_DISCORD_ENABLED    =   ${allianceSEND_HISTORY_DISCORD_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_RALLY_DISCORD_ENABLED      =   ${allianceSEND_RALLY_DISCORD_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini
echo "SEND_RALLY_Mail_ENABLED         =   ${allianceSEND_RALLY_Mail_ENABLED}" >> /var/www/pathfinder/conf/pathfinder.ini

if [ "${AddAdminChar}" != "False" ]; then
 echo "[PATHFINDER.ROLES]" >> /var/www/pathfinder/conf/pathfinder.ini
 echo "CHARACTER.0.ID = ${AdminCharID}" >> /var/www/pathfinder/conf/pathfinder.ini
 echo "CHARACTER.0.ROLE = SUPER" >> /var/www/pathfinder/conf/pathfinder.ini
fi

echo "Starting Services"
if [ "${ENABLE_CRON}" != "False" ]; then
 crontab /home/default_crontab
 service cron start
fi
service php7.2-fpm start
#service redis-server start
service pathfinder-websocket start
nginx -g "daemon off;"
