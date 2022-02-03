#!/usr/bin/env sh

# This should be passed in from docker run, useful for correct file ownership
# in your datavol on the host.
# -e MOIN_UID=jbloggs -e MOIN_GID=jbloggs
UWSGI_UID="${MOIN_UID:-www-data}"
UWSGI_GID="${MOIN_GID:-www-data}"

# If the data folder does not contain file 'initialized' it is most likely because
# the container is fresh and has been started with
# the volume option
if ! [ "$(ls -A /usr/local/share/moin/data/initialized 2>/dev/null)" ]; then
    cp -r /usr/local/share/moin/bootstrap-data/* /usr/local/share/moin/data/
    touch /usr/local/share/moin/data/initialized
    chown -R "${UWSGI_UID}:${UWSGI_GID}" /usr/local/share/moin/data
fi

# Correct filesystem ownership if given
# XXX: data could be very slow if there's lots of pages
chown -R "${UWSGI_UID}:${UWSGI_GID}" /usr/local/share/moin/data
chown -R "${UWSGI_UID}:${UWSGI_GID}" /usr/local/share/moin/underlay

service rsyslog start && service nginx start && uwsgi \
    --uid "${UWSGI_UID}" \
    --gid "${UWSGI_GID}" \
    -s /tmp/uwsgi.sock \
    --chown-socket www-data:www-data \
    --plugins python \
    --pidfile /var/run/uwsgi-moinmoin.pid \
    --wsgi-file server/moin.wsgi \
    -M -p 4 \
    --chdir /usr/local/share/moin \
    --python-path /usr/local/share/moin \
    --harakiri 30 \
    --die-on-term
