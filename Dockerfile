ARG ASTERISK_VERSION=20
ARG BASE_VERSION=8-minimal

FROM public.ecr.aws/docker/library/rockylinux:${BASE_VERSION} AS build

ARG ASTERISK_VERSION
ARG BASE_VERSION

RUN microdnf install -y dnf && microdnf clean all && \
    ln -s /usr/bin/dnf /usr/bin/yum && \
    dnf -y update && \
    dnf -y install wget tar epel-release gcc gcc-c++ make ncurses-devel libxml2-devel sqlite-devel git diffutils && \
    dnf clean all

# Disable SELinux if the config file exists
RUN if [ -f /etc/selinux/config ]; then \
        sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config && \
        setenforce 0; \
    fi

WORKDIR /usr/src

# Clone or download Asterisk based on the version
RUN if [ "${ASTERISK_VERSION}" = "latest" ]; then \
        echo "Cloning Asterisk from GitHub"; \
        git clone --depth 1 https://github.com/asterisk/asterisk.git asterisk && \
        cd asterisk; \
    else \
        echo "Downloading Asterisk version ${ASTERISK_VERSION}"; \
        wget --no-cache http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}-current.tar.gz && \
        tar zxvf asterisk-${ASTERISK_VERSION}-current.tar.gz && \
        rm -rf asterisk-${ASTERISK_VERSION}-current.tar.gz && \
        mv asterisk-${ASTERISK_VERSION}* asterisk && \
        cd asterisk; \
    fi && \
    contrib/scripts/install_prereq install && \
    ./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled && \
    make menuselect.makeopts && \
    menuselect/menuselect --disable BUILD_NATIVE --disable-category MENUSELECT_ADDONS menuselect.makeopts && \
    make && \
    make install && \
    make samples && \
    make basic-pbx

FROM public.ecr.aws/docker/library/rockylinux:${BASE_VERSION}

ARG BASE_VERSION

RUN microdnf install -y dnf && microdnf clean all && \
    dnf -y update && \
    dnf -y install epel-release libedit ncurses libxml2 sqlite gettext && \
    dnf clean all

# Create asterisk user and group
RUN groupadd -r asterisk && useradd -r -g asterisk asterisk

# Copy built files from the build stage
COPY --from=build /usr/lib64 /usr/lib64
COPY --from=build /usr/sbin /usr/sbin
COPY --from=build /var/lib/asterisk /var/lib/asterisk
COPY --from=build /etc/asterisk /etc/asterisk

# Set permissions for Asterisk
RUN chown -R asterisk:asterisk /var/lib/asterisk && chmod -R 750 /var/lib/asterisk

ENTRYPOINT ["/usr/sbin/asterisk", "-U", "asterisk", "-G", "asterisk", "-pvvvdddf"]
