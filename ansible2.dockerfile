FROM registry.access.redhat.com/ubi8/ubi:latest

# Silence subscription messages
RUN echo "enabled=0" >> /etc/yum/pluginconf.d/subscription-manager.conf

RUN yum -y install \
    sudo \
    python39 \
    python39-pip \
    unzip \
    tar \
    curl \
    git \
    yum-utils \
    && yum clean all

# Upgrade pip to the latest version
RUN python3.9 -m pip install --upgrade pip

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers
        
# Install Ansible via pip
RUN pip3 install ansible
# Install Terraform
RUN curl -LO "https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip" \
&& unzip terraform_1.9.5_linux_amd64.zip \
&& mv terraform /usr/local/bin/terraform \
&& rm terraform_1.9.5_linux_amd64.zip

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip ./aws

# # Install Google Cloud SDK (gcloud CLI)
RUN curl -O "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz" \
    && tar -xzf google-cloud-cli-linux-x86_64.tar.gz \
    && ./google-cloud-sdk/install.sh \
    && rm google-cloud-cli-linux-x86_64.tar.gz

ENV PATH $PATH:/google-cloud-sdk/bin


# Install Google Cloud SDK (gcloud CLI)
# RUN echo -e "[google-cloud-cli]\n\ 
# name=Google Cloud CLI\n\
# baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64\n\
# enabled=1\n\
# gpgcheck=1\n\
# repo_gpgcheck=0\n\ 
# gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"\
# > /etc/yum.repos.d/google-cloud-sdk.repo

# RUN yum -y install google-cloud-cli 

# Install Azure CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && yum install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm \
    && yum install -y azure-cli

# Set up Ansible inventory
RUN mkdir -p /etc/ansible \
    && echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts

# Clean up any unnecessary files
RUN rm -rf /var/cache/yum /tmp/* /var/tmp/* /google-cloud-sdk/.install

# Set working directory
WORKDIR /workspace

# Volume for systemd
VOLUME ["/sys/fs/cgroup"]

# Start systemd by default.
CMD ["/usr/lib/systemd/systemd"]
