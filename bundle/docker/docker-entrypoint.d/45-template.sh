#! /bin/sh
set -e
echo "Setup templates"
cat /usr/local/share/decidim/templates/motd.template | sed -e "s@\$DECIDIM_VERSION@$DECIDIM_VERSION@g"\
  -e "s@\$NODE_VERSION@$NODE_VERSION@g"\
  -e "s@\$RUBY_VERSION@$RUBY_VERSION@g"\
  -e "s@\$RAILS_ENV@$RAILS_ENV@g"\
  -e "s@\$ROOT@$ROOT@g" > /etc/motd

echo "/etc/motd updated"
