cc-switch

cc-switch-web

curl -fsSL https://raw.githubusercontent.com/Laliet/cc-switch-web/main/scripts/deploy-web.sh | bash -s -- --prebuilt

ALLOW_HTTP_BASIC_OVER_HTTP=1 bash cc-switch-web/scripts/start-web.sh

cat .cc-switch/web_password