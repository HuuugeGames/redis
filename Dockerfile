FROM centos:6
RUN yum -y update && \
        yum install -y  wget gcc make epel-release cronie && \
        yum install -y python-pip

ADD . /opt/redis
WORKDIR /opt/redis
RUN mkdir -p /etc/redis
RUN mkdir -p /data

RUN cp entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
RUN cp redis.conf /etc/redis/redis.conf
RUN pip install -r requirements.txt
RUN make
RUN make install
RUN cp redis.conf /etc/redis/redis.conf && \
  cp -f src/redis-sentinel /usr/local/bin && \
  mkdir -p /etc/redis && \
  cp -f *.conf /etc/redis && \
  rm -rf /tmp/redis-stable* && \
  sed -i 's/^\(dir .*\)$/# \1\ndir \/data/' /etc/redis/redis.conf && \
  sed -i 's/^\(logfile .*\)$/logfile \/var\/log\/redis.log/' /etc/redis/redis.conf && \
  sed -i 's/^\(bind 127.0.0.1\)$/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(protected-mode yes\)$/protected-mode no/' /etc/redis/redis.conf && \
  sed -i 's/^\(slave-read-only yes\)$/slave-read-only no/' /etc/redis/redis.conf && \
  sed -i 's/^\(save 900 1\)/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(save 300 10\)/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(save 60 10000\)/save 86400 1/' /etc/redis/redis.conf

RUN cp cloudwatch_metric.py /etc/redis/cloudwatch_metric.py
RUN chmod a+x /etc/redis/cloudwatch_metric.py
RUN echo -e "*/5 * * * * root . /root/.profile;/etc/redis/cloudwatch_metric.py >> /var/log/metrics_cron.log\n" >> /etc/cron.d/redis_cron
RUN mkdir -p /var/log/cron
RUN touch /var/log/metrics_cron.log

# Define mountable directories.
VOLUME ["/data"]

# Define working directory.
WORKDIR /data

# Define default command.
CMD crond && redis-server /etc/redis/redis.conf && tail -f /var/log/metrics_cron.log

# Expose ports.
EXPOSE 6379