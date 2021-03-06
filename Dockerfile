FROM python:2.7

ENV DEBIAN_VERSION jessie
ENV NGINX_VERSION 1.10.2-1~$DEBIAN_VERSION
ENV UWSGI_VERSION 2.0.14
ENV NEWRELIC_VERSION 2.76.0.55


RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
  && echo "deb http://nginx.org/packages/debian/ ${DEBIAN_VERSION} nginx" >> /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y ca-certificates gettext-base nginx=${NGINX_VERSION} \
  && rm -rf /var/lib/apt/lists/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/

RUN pip install uwsgi==${UWSGI_VERSION}
RUN mkdir /var/log/uwsgi
RUN ln -sf /dev/stdout /var/log/uwsgi/uwsgi.log
COPY uwsgi-emperor.ini /etc/uwsgi/emperor.ini
COPY uwsgi-vassal.ini /etc/uwsgi/vassal.ini
COPY vassals /etc/uwsgi/

COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt
RUN rm /tmp/requirements.txt

RUN pip install newrelic==${NEWRELIC_VERSION}

RUN apt-get update && apt-get install -y supervisor \
  && rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY app /home/site/repository/
WORKDIR /home/site/repository

EXPOSE 80 443 8080

CMD ["/usr/bin/supervisord"]
