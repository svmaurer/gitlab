FROM ubuntu:14.04
MAINTAINER svenm85@googlemail.com

# select GitLab version
ENV GITLAB_VERSION gitlab-ce_8.14.0-ce.0_amd64.deb

# proxy settings
#ENV http_proxy http://xxx:1234
#ENV https_proxy https://xxx:1234

# initial ubuntu
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install sudo -y

# Install required packages
RUN apt-get install -y curl openssh-server ca-certificates
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y postfix telnet dnsutils

# Initial postfix
COPY assets/main.cf /etc/postfix/
RUN /etc/init.d/postfix restart

# Download & Install GitLab
RUN curl -LJO https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/trusty/${GITLAB_VERSION}/download
RUN dpkg -i ${GITLAB_VERSION}

RUN rm -f ${GITLAB_VERSION}

# important for non persistant storage
# RUN gitlab-ctl reconfigure

# Manage SSHD through runit
RUN mkdir -p /opt/gitlab/sv/sshd/supervise \
    && mkfifo /opt/gitlab/sv/sshd/supervise/ok \
    && printf "#!/bin/sh\nexec 2>&1\numask 077\nexec /usr/sbin/sshd -D" > /opt/gitlab/sv/sshd/run \
    && chmod a+x /opt/gitlab/sv/sshd/run \
    && ln -s /opt/gitlab/sv/sshd /opt/gitlab/service \
    && mkdir -p /var/run/ssh \
    && mkdir -p /var/run/sshd

# Prepare default configuration
COPY assets/gitlab.rb /assets/gitlab.rb
#RUN ( \
#  echo "" && \
#  echo "# Docker options" && \
#  echo "# Prevent Postgres from trying to allocate 25% of total memory" && \
#  echo "postgresql['shared_buffers'] = '256MB'" ) >> /etc/gitlab/gitlab.rb && \
#  mkdir -p /assets/ && \
#  cp /etc/gitlab/gitlab.rb /assets/gitlab.rb

# Expose web & ssh
EXPOSE 443 20080 22

# Define data volumes
VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

# Copy assets
COPY assets/wrapper /usr/local/bin/
RUN chmod 777 /usr/local/bin/wrapper

# Wrapper to handle signal, trigger runit and reconfigure GitLab
CMD ["/usr/local/bin/wrapper"]
