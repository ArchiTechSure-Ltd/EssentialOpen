# Essential Open Viewer + Import Utility
# Based on Tomcat 8.5 / Java 8
FROM tomcat:8.5-jre8


# -------------------------------------------------------------------
# Operating system packages
# -------------------------------------------------------------------

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        dialog \
        openssh-server \
        vim \
        graphviz \
        netcat \
        unzip \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*


# -------------------------------------------------------------------
# SSH support
#
# Retained from the original EssentialOpen image.
# ssh root@127.0.0.1 -p 2222 -c aes256-cbc
# -------------------------------------------------------------------

ENV SSH_PASSWD="root:Docker!"

RUN echo "$SSH_PASSWD" | chpasswd

COPY sshd_config /etc/ssh/


# -------------------------------------------------------------------
# Exposed ports
# -------------------------------------------------------------------

EXPOSE 80 8080 2222


# -------------------------------------------------------------------
# Essential Viewer
#
# Expand a pristine Viewer into /opt. At startup it will be copied
# into the persistent Viewer webapp directory when required.
# -------------------------------------------------------------------

COPY ./downloads/essential_viewer_6217.war \
    /tmp/essential_viewer.war

RUN mkdir -p /opt/essential-viewer-defaults \
    && unzip -q /tmp/essential_viewer.war \
        -d /opt/essential-viewer-defaults \
    && rm /tmp/essential_viewer.war \
    && mkdir -p /usr/local/tomcat/webapps/essential_viewer


# -------------------------------------------------------------------
# Essential Import Utility
#
# Explicitly explode the Import Utility during image construction.
#
# This ensures that the complete application exists before Docker
# mounts persistent runtime directories.
# -------------------------------------------------------------------

COPY ./downloads/essential_import_utility_2101.war \
    /tmp/essential_import_utility.war

RUN mkdir -p /usr/local/tomcat/webapps/essential_import_utility \
    && unzip -q /tmp/essential_import_utility.war \
        -d /usr/local/tomcat/webapps/essential_import_utility \
    && rm /tmp/essential_import_utility.war


# -------------------------------------------------------------------
# Import Utility persistent configuration
#
# Keep pristine copies of the configuration supplied by the version
# of the Import Utility baked into this image.
#
# At container startup these are copied to persistent storage only
# when the persistent copies do not already exist.
#
# This means:
#
#   First start:
#       image defaults -> persistent storage
#
#   Subsequent starts:
#       existing persistent configuration is retained
#
#   Image upgrade:
#       new defaults are available in the image but existing instance
#       configuration is not overwritten.
# -------------------------------------------------------------------

RUN mkdir -p /opt/essential-import-defaults \
    && cp -a \
        /usr/local/tomcat/webapps/essential_import_utility/config/. \
        /opt/essential-import-defaults/


# -------------------------------------------------------------------
# Link mutable Import Utility configuration to persistent storage
#
# Only config.xml and system_config.xml are persisted.
#
# Other application configuration files remain supplied by the image,
# which means upgrades can replace those files normally.
# -------------------------------------------------------------------


# -------------------------------------------------------------------
# Essential repository seed
#
# Download the clean Essential baseline repository at image build time.
#
# The repository is kept as an immutable seed within the image.
# startup.sh copies it into the persistent Live and QA repositories
# only when those repositories do not already exist.
# -------------------------------------------------------------------

ARG ESSENTIAL_BASELINE_VERSION=6_21
ARG ESSENTIAL_BASELINE_URL=https://cdn.enterprise-architecture.org/meta-model/essential_baseline_6_21.zip

RUN mkdir -p \
        /opt/essential-repository-defaults/source \
    && echo "Downloading Essential baseline ${ESSENTIAL_BASELINE_VERSION}..." \
    && curl -fL \
        "${ESSENTIAL_BASELINE_URL}" \
        -o /tmp/essential_baseline.zip \
    && unzip -q \
        /tmp/essential_baseline.zip \
        -d /opt/essential-repository-defaults/source \
    && rm /tmp/essential_baseline.zip \
    && echo "Essential baseline repository installed:" \
    && find /opt/essential-repository-defaults/source -maxdepth 2 -type f -print
    
# -------------------------------------------------------------------
# Default root redirect
#
# Requests reaching the Tomcat root context are redirected to Viewer.
# -------------------------------------------------------------------

RUN mkdir -p /usr/local/tomcat/webapps/ROOT \
    && printf '%s\n' \
       '<% response.sendRedirect("/essential_viewer/"); %>' \
       > /usr/local/tomcat/webapps/ROOT/index.jsp


# -------------------------------------------------------------------
# Tomcat HTTP connector configuration
#
# maxHttpHeaderSize:
#   Increased to accommodate Authentik/OAuth headers.
#
# maxPostSize:
#   20 MiB maximum POST size handled by Tomcat parameter parsing.
#
# maxSwallowSize:
#   20 MiB maximum request body Tomcat will consume when an upload
#   is aborted/rejected.
#
# These values align with:
#
#   nginx: client_max_body_size 20m;
# -------------------------------------------------------------------

RUN sed -i \
    's/connectionTimeout="20000"/connectionTimeout="20000" maxHttpHeaderSize="24576" maxPostSize="20971520" maxSwallowSize="20971520"/' \
    /usr/local/tomcat/conf/server.xml


# -------------------------------------------------------------------
# Tomcat users
# -------------------------------------------------------------------

COPY tomcat-users.xml \
    /usr/local/tomcat/conf/tomcat-users.xml


# -------------------------------------------------------------------
# Startup
#
# startup.sh:
#   - seeds Import Utility persistent configuration when required
#   - starts SSH
#   - starts Tomcat
# -------------------------------------------------------------------

COPY startup.sh /usr/local/bin/startup.sh

RUN sed -i 's/\r$//' /usr/local/bin/startup.sh \
    && chmod +x /usr/local/bin/startup.sh

ENTRYPOINT ["/usr/local/bin/startup.sh"]