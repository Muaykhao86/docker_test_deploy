# Stage 1: Build with Rust and dependencies
FROM registry.access.redhat.com/ubi8/ubi:latest AS build

# Silence subscription messages
RUN echo "enabled=0" >> /etc/yum/pluginconf.d/subscription-manager.conf

# Install basic dependencies, Python, and curl (for rustup)
RUN yum makecache --timer \
    && yum -y install \
        sudo \
        which \
        hostname \
        python3.12 \
        unzip \
        curl \
        yum-utils \
    && yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo \
    && yum clean all

# Upgrade pip
RUN python3 -m ensurepip --upgrade \
    && pip3 install --upgrade pip

# Install rustup (to get a complete Rust toolchain including cargo)
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Ensure the latest Rust version is installed
RUN rustup update

# Install Ansible and Rust-related dependencies
RUN pip3 install setuptools_rust \
    && pip3 install ansible

# Stage 2: Final runtime image (without Rust)
# FROM registry.access.redhat.com/ubi8/ubi:latest

# Silence subscription messages
# RUN echo "enabled=0" >> /etc/yum/pluginconf.d/subscription-manager.conf

# Install yum dependencies
# RUN yum makecache --timer \
#     && yum -y install \
#         sudo \
#         which \
#         hostname \
#         python3.12 \
#         unzip \
#         curl \
#         yum-utils \
#     && yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo \
#     && yum clean all

# # Upgrade pip
# RUN python3 -m ensurepip --upgrade \
#     && pip3 install --upgrade pip
    
# Copy over Ansible from the build stage
# COPY --from=build /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
# COPY --from=build /usr/local/bin/ansible* /usr/local/bin/

# Install Terraform
RUN yum -y install terraform

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
RUN echo -e "[google-cloud-cli]\n\ 
name=Google Cloud CLI\n\
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=0\n\ 
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"\
> /etc/yum.repos.d/google-cloud-sdk.repo

RUN yum -y install google-cloud-cli 

# Install Azure CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && yum install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm \
    && yum install -y azure-cli

# Volume for systemd
VOLUME ["/sys/fs/cgroup"]

# Start systemd by default.
CMD ["/usr/lib/systemd/systemd"]
