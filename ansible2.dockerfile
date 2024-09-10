# Use UBI8 as the base image
FROM registry.access.redhat.com/ubi8/ubi:latest

# Environment variables
ENV TERRAFORM_VERSION=1.9.5
ENV PIP_PACKAGES="ansible"
ENV PATH=$PATH:/google-cloud-sdk/bin

# Silence subscription-manager warnings
RUN echo "enabled=0" >> /etc/yum/pluginconf.d/subscription-manager.conf

# Install system packages, core dependencies, and clean up unnecessary services for systemd
RUN yum makecache --timer \
    && yum -y update \
    && yum -y install \
        sudo \
        which \
        hostname \
        python39 \
        python39-pip \
        unzip \
        curl \
        yum-utils \
        initscripts \
        git \
    && yum clean all \
    # Remove unnecessary systemd units
    && (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done) \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/*

# Upgrade pip and install Ansible via pip
RUN python3.9 -m pip install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir $PIP_PACKAGES

# Install Terraform (Manual to avoid unnecessary dependencies)
RUN curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/terraform \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install AWS CLI (version 2)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip ./aws

# Install Google Cloud SDK (Minimal Installation)
RUN curl -O "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz" \
    && tar -xzf google-cloud-cli-linux-x86_64.tar.gz \
    && ./google-cloud-sdk/install.sh \
    && rm -rf google-cloud-cli-linux-x86_64.tar.gz /google-cloud-sdk/.install

# Install Azure CLI via Microsoft repository
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && yum -y install https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm \
    && yum -y install azure-cli \
    && yum clean all

# Set up Ansible inventory for local connections
RUN mkdir -p /etc/ansible \
    && echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts

# Clean up unnecessary files to reduce image size
RUN rm -rf /var/cache/yum /tmp/* /var/tmp/* /google-cloud-sdk/.install

# Set working directory
WORKDIR /workspace

# ? Note sure if either of these are necessary
# Volume for systemd
# VOLUME ["/sys/fs/cgroup"]
# Disable requiretty.
# RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Default CMD to run systemd
CMD ["/usr/lib/systemd/systemd"]
