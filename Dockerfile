# https://github.com/CSIRO-enviro-informatics/docker-geoserver
FROM csiroenvinf/geoserver:latest
RUN apt-get -y install ssh 

#Clone this repository for internals 
RUN git clone https://github.com/CSIRO-enviro-informatics/aurin62-code-resources.git
ADD aurin62-data /aurin62-data
RUN cd /aurin62-code-resources && git pull

#Install apache with ssl (from https://registry.hub.docker.com/u/eboraas/apache/dockerfile) and proxy_ajp
#need to remove this file since apt-get update returns error due to 404
RUN rm -f /etc/apt/sources.list.d/pitti-postgresql-trusty.list
RUN apt-get update && apt-get -y install apache2 apache2-utils && apt-get clean  
ENV APACHE_PASSWORD aurin 
ENV APACHE_USER aurin 
RUN /usr/bin/htpasswd -bc /etc/apache2/htpasswd ${APACHE_USER} ${APACHE_PASSWORD}

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

RUN /bin/ln -sf ../sites-available/default-ssl /etc/apache2/sites-enabled/001-default-ssl
RUN /bin/ln -sf ../mods-available/ssl.conf /etc/apache2/mods-enabled/
RUN /bin/ln -sf ../mods-available/ssl.load /etc/apache2/mods-enabled/
RUN a2enmod proxy_ajp
RUN a2enmod socache_shmcb.load
RUN a2enmod headers 

# configure proxy to tomcat 
RUN /bin/ln -sf /aurin62-code-resources/docker/25-siss-ssl.conf /etc/apache2/sites-available/25-siss-ssl.conf 
RUN /bin/ln -sf /aurin62-code-resources/docker/25-siss-ssl.conf /etc/apache2/sites-enabled/25-siss-ssl.conf 

# configure tomcat
RUN /bin/ln -sf /aurin62-code-resources/docker/server.xml /opt/tomcat7/conf/server.xml

#Setup Python 
RUN locale-gen en_AU.utf8
RUN apt-get install -y python python-pip python-dev python-pandas
RUN pip install xlrd pint petl 


#Set geoserver postgres password
ENV PGPASSWORD geoserver 

# create postgres user and database
USER postgres
ADD wait-for-it.sh /wait-for-it.sh
RUN /etc/init.d/postgresql start && ./wait-for-it.sh postgres:5432 -- echo "postgres is up"\
     && psql --command "CREATE USER \"geoserver-admin\" WITH SUPERUSER PASSWORD 'geoserver';" \
     && createdb -O geoserver-admin geoserver && psql geoserver -c "CREATE EXTENSION postgis;CREATE EXTENSION postgis_topology;" && /etc/init.d/postgresql stop
USER root 

# create wesc database structure
USER postgres 
RUN /etc/init.d/postgresql start && ./wait-for-it.sh postgres:5432 -- echo "postgres is up" \
    && psql -h localhost -d geoserver -U geoserver-admin -w -f /aurin62-code-resources/WESCDDL.sql && /etc/init.d/postgresql stop
USER root 

# configure geoserver 
RUN rm -rf /opt/geoserver_data && rm -rf /opt/tomcat7/webapps/geoserver/data && /bin/ln -sf /aurin62-code-resources/docker/geoserver-data /opt/geoserver_data
 

# import selected AURIN 6/2 data 
ADD dataimportcfg.json /aurin62-code-resources/dataimportcfg.json
ADD dataimportselection.txt /aurin62-code-resources/dataimportselection.txt
RUN /etc/init.d/postgresql start  && ./wait-for-it.sh postgres:5432 -- echo "postgres is up" \
   && /usr/bin/python /aurin62-code-resources/selectedbatchimport.py /aurin62-data /aurin62-code-resources/dataimportcfg.json /aurin62-code-resources/dataimportselection.txt 


ENV GEOSERVER_DATA_DIR  /opt/geoserver_data
#ADD geoserver_data  ${GEOSERVER_DATA_DIR}
VOLUME ${GEOSERVER_DATA_DIR}
USER root

#Supervisord
RUN apt-get -y install supervisor
RUN apt-get -y install openssh-server
RUN mkdir -p /var/run/sshd
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /etc/supervisor/conf.d
RUN printf '[supervisord]\n\
nodaemon=true\n\
[program:sshd]\n\
command=/usr/sbin/sshd -D\n\
[program:tomcat]\n\
command=/opt/tomcat7/bin/catalina.sh run\n\
[program:apache2]\n\
command=apachectl -D "FOREGROUND" -k start\n\
[program:postgresql]\n\
command=su postgres -c "/usr/lib/postgresql/9.6/bin/postgres -D /var/lib/postgresql/9.6/main -c config_file=/etc/postgresql/9.6/main/postgresql.conf" /usr/local/pgsql/data\n\
\n\
[include]\n\
files = /etc/supervisor/conf.d/*.conf' > /etc/supervisor/conf.d/supervisord.conf
RUN echo 'root:root' | chpasswd


EXPOSE 5432
EXPOSE 22 
EXPOSE 80 
EXPOSE 443

CMD ["/usr/bin/supervisord"]
