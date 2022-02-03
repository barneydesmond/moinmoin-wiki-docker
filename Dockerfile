# VERSION 0.8
# AUTHOR:         Olav Grønås Gjerde <olav@backupbay.com>
# DESCRIPTION:    Image with MoinMoin wiki, uwsgi, nginx, customised for MeidokonWiki
# TO_BUILD:       docker build -t meidokon_wiki .
# TO_RUN:         docker run -d -p 80:80 -v /path/to/datavol:/usr/local/share/moin/data --name my_wiki meidokon_wiki

FROM debian:buster-slim
MAINTAINER Barney Desmond <barneydesmond@gmail.com>

# Set the version you want of MoinMoin
ENV MM_VERSION 1.9.11
ENV MM_CSUM 3eb13b4730bd97259a41c4cd500f8433778ff8cf

# Set theme package to download
ENV THEME_URL https://github.com/dossist/moinmoin-memodump/archive/refs/tags/v0.2.2.tar.gz
ENV THEME_CSUM c6623da49fccb60624d31aa3856229f87d7c91a9

# Install software
RUN apt-get update && apt-get install -qqy --no-install-recommends \
  python2.7 \
  curl \
  procps \
  openssl \
  nginx \
  uwsgi \
  uwsgi-plugin-python \
  rsyslog \
  busybox

# Download MoinMoin
RUN curl -OkL \
  https://github.com/moinwiki/moin-1.9/releases/download/$MM_VERSION/moin-$MM_VERSION.tar.gz
RUN if [ "$MM_CSUM" != "$(sha1sum moin-$MM_VERSION.tar.gz | awk '{print($1)}')" ];\
  then exit 1; fi;
RUN mkdir moinmoin
RUN tar xf moin-$MM_VERSION.tar.gz -C moinmoin --strip-components=1

# Download theme
RUN curl -kL -o memodump.tar.gz $THEME_URL
RUN if [ "$THEME_CSUM" != "$(sha1sum memodump.tar.gz | awk '{print($1)}')" ];\
  then exit 1; fi;
RUN mkdir memodump
RUN tar xf memodump.tar.gz -C memodump --strip-components=1

# Install MoinMoin
RUN cd moinmoin && python2.7 setup.py install --force --prefix=/usr/local
RUN chown -Rh www-data:www-data /usr/local/share/moin/underlay
USER root

# Install theme
RUN chown -R www-data:www-data memodump
RUN mv memodump/memodump /usr/local/lib/python2.7/dist-packages/MoinMoin/web/static/htdocs/
RUN mv memodump/memodump.py /usr/local/lib/python2.7/dist-packages/MoinMoin/theme/memodump.py
# Tweak theme
RUN rm /usr/local/lib/python2.7/dist-packages/MoinMoin/web/static/htdocs/memodump/css/memodump.css
ADD memodump.css /usr/local/lib/python2.7/dist-packages/MoinMoin/web/static/htdocs/memodump/css/
RUN chown www-data:www-data /usr/local/lib/python2.7/dist-packages/MoinMoin/web/static/htdocs/memodump/css/memodump.css


# Copy default data into a new folder, we will use this to add content
# if you start a new container using volumes
RUN cp -r /usr/local/share/moin/data /usr/local/share/moin/bootstrap-data

RUN chown -R www-data:www-data /usr/local/share/moin/data
ADD logo.png /usr/local/lib/python2.7/dist-packages/MoinMoin/web/static/htdocs/common/

# Symlink for convenience
RUN ln -s /usr/local/share/moin /moin

# Configure nginx
ADD nginx.conf /etc/nginx/
ADD moinmoin.conf /etc/nginx/sites-enabled/
RUN rm /etc/nginx/sites-enabled/default
RUN mkdir -p /var/cache/nginx/cache

# Cleanup
RUN rm -rf moin-$MM_VERSION.tar.gz /moinmoin memodump.tar.gz /memodump
RUN apt-get purge -qqy curl
RUN apt-get autoremove -qqy && apt-get clean
RUN rm -rf /tmp/* /var/lib/apt/lists/*

# Configure the wiki
ADD wikiconfig.py /usr/local/share/moin/

# Add the start shell script
ADD start.sh /usr/local/bin/

VOLUME /usr/local/share/moin/data

EXPOSE 80

CMD start.sh
