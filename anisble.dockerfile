FROM registry.access.redhat.com/ubi8/ubi:latest

ENV container=docker
ENV pip_packages "ansible"

# Silence annoying subscription messages.
RUN echo "enabled=0" >> /etc/yum/pluginconf.d/subscription-manager.conf

# Install systemd and clean up unnecessary services.
RUN yum -y update; yum clean all; \
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# Install basic dependencies.
RUN yum makecache --timer \
 && yum -y install initscripts \
 && yum -y update \
 && yum -y install \
      sudo \
      which \
      hostname \
      python3 \
      unzip \
      curl \
      yum-utils \
 && yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo \
 && yum clean all

# Install Terraform
RUN yum -y install terraform

# Install Ansible via pip.
RUN pip3 install $pip_packages

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts

# Install AWS CLI (version 2)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -f awscliv2.zip

# Install Google Cloud SDK (gcloud CLI)
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && yum -y install google-cloud-sdk

# Install Azure CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm \
    && dnf install -y azure-cli

# Volume for systemd
VOLUME ["/sys/fs/cgroup"]

# Start systemd by default.
CMD ["/usr/lib/systemd/systemd"]
