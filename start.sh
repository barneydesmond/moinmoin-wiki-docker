#!/usr/bin/env sh

# If the data folder does not contain file 'initialized' it is most likely because
# the container is fresh and has been started with
# the volume option
if ! [ "$(ls -A /usr/local/share/moin/data/initialized 2>/dev/null)" ]; then
    cp -r /usr/local/share/moin/bootstrap-data/* /usr/local/share/moin/data/
    touch /usr/local/share/moin/data/initialized
    chown -R www-data:www-data /usr/local/share/moin/data
fi

# Link active vhost into sites-enabled
ln -sf /etc/nginx/sites-available/moinmoin-nossl.conf \
    /etc/nginx/sites-enabled/moinmoin.conf

service rsyslog start && service nginx start && uwsgi \
    --uid www-data \
    -s /tmp/uwsgi.sock \
    --plugins python \
    --pidfile /var/run/uwsgi-moinmoin.pid \
    --wsgi-file server/moin.wsgi \
    -M -p 4 \
    --chdir /usr/local/share/moin \
    --python-path /usr/local/share/moin \
    --harakiri 30 \
    --die-on-term
