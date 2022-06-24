FROM registry:5000/rhscl/python-35-rhel7

# DBS env
ARG PIP_INDEX=https://nexus.com:8443/nexus/repository/pypi-all/simple
ENV PIP_INDEX $PIP_INDEX
ENV LD_LIBRARY_PATH=/opt/rh/rh-python35/root/usr/lib64/
ENV GUNICORN_BIND=0.0.0.0:8088 \
    GUNICORN_LIMIT_REQUEST_FIELD_SIZE=0 \
    GUNICORN_LIMIT_REQUEST_LINE=0 \
    GUNICORN_TIMEOUT=600 \
    GUNICORN_WORKERS=1 \
    SUPERSET_HOME=/opt/superset

COPY files/krb5.conf /etc/krb5.conf
COPY files/required.txt /tmp/
COPY files/dbs.repo /etc/yum.repos.d/
COPY files/redis-stable.tar.gz /tmp/
USER root
RUN echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
RUN mkdir /redis
RUN chmod 777 /redis

RUN mkdir /opt/superset/
COPY files/entrypoint.sh /opt/superset/
COPY files/start.sh /opt/superset/
COPY files/rpm_list /tmp/
COPY files/pip /tmp/
COPY files/rpm /tmp/

#RUN find / -name libpython3.5m.so.rh-python35-1.0
##Added Redis
RUN tar xvf /tmp/redis-stable.tar.gz -C /redis/
RUN cd /redis/redis-stable/ && make && make install

##install python
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
     yum install -y https://centos7.iuscommunity.org/ius-release.rpm && \
    yum install -y python36u python36u-libs python36u-devel python36u-pip krb5-workstation openldap-devel openldap net-tools
#RUN yum install -y $(cat /tmp/rpm)
#RUN yum install -y libpython3*
RUN pip3.6 install gevent
RUN pip3.6 install -r /tmp/required.txt
#RUN pip3.6 install -r /tmp/pip

COPY file/config.py /usr/lib/python3.6/site-packages/superset/config.py
#RUN pip3.6 install superset
EXPOSE 8088
WORKDIR /opt/superset

ENTRYPOINT [ "/opt/superset/entrypoint.sh" ]
#CMD /opt/superset/start.sh
#CMD /redis/redis-stable/src/redis-server > /tmp/redis.log 2>&1
#RUN echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
