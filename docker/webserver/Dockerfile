FROM phusion/passenger-ruby33:3.0.2
MAINTAINER Robert Vidar Bjarnason <robert@citizens.is>

RUN echo 'version 5.4.5'

ENV HOME /root
ENV APP_DB_HOST 10.10.11.101
ENV DISABLE_DATABASE_ENVIRONMENT_CHECK 1
CMD ["/sbin/my_init"]

RUN apt-get clean
RUN apt-get update
RUN apt-get --assume-yes install libyaml-dev
RUN apt-get --assume-yes install build-essential patch
RUN apt-get --assume-yes install ruby-dev zlib1g-dev liblzma-dev
RUN apt-get --assume-yes install ca-certificates
RUN apt-get --assume-yes install mysql-client
RUN apt-get --assume-yes install sudo
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default

ADD docker/webserver/nginx.conf /etc/nginx/sites-enabled/oav_website.conf
ADD docker/webserver/rails-env.conf /etc/nginx/main.d/rails-env.conf

RUN mkdir -p /etc/my_init.d
ADD docker/webserver/setup_app.sh /etc/my_init.d/setup_app.sh

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80
