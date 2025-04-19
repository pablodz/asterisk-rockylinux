# Stage 1: Build Asterisk
ARG BASE_VERSION=9-minimal
FROM rockylinux:${BASE_VERSION} AS build

ARG ASTERISK_VERSION=22

# Install build dependencies and disable SELinux in a single step
RUN microdnf install -y dnf && microdnf clean all && \
    ln -s /usr/bin/dnf /usr/bin/yum && \
    dnf -y update && \
    dnf -y install wget tar epel-release chkconfig libedit-devel gcc gcc-c++ make ncurses-devel \
    libxml2-devel sqlite-devel git diffutils && \
    if [ -f /etc/selinux/config ]; then \
        sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config && \
        setenforce 0; \
    fi && \
    dnf clean all

# Download, compile, and install Asterisk in a single step
WORKDIR /usr/src
RUN wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}-current.tar.gz && \
    tar zxvf asterisk-${ASTERISK_VERSION}-current.tar.gz && \
    rm -rf asterisk-${ASTERISK_VERSION}-current.tar.gz && \
    cd asterisk-${ASTERISK_VERSION}* && \
    contrib/scripts/install_prereq install && \
    ./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled && \
    make menuselect.makeopts && \
    menuselect/menuselect --disable BUILD_NATIVE --disable-category MENUSELECT_ADDONS menuselect.makeopts && \
    make -j$(nproc) && \
    make install && \
    make samples && \
    make basic-pbx

# Stage 2: Create runtime image
FROM rockylinux:${BASE_VERSION}

# Install runtime dependencies in a single step
RUN microdnf install -y dnf && microdnf clean all && \
    dnf -y update && \
    dnf -y install epel-release libedit ncurses libxml2 sqlite gettext && \
    dnf clean all

# Create asterisk user and group
RUN groupadd -r asterisk && useradd -r -g asterisk asterisk

# Copy Asterisk from the build stage
COPY --from=build /usr/lib64 /usr/lib64
COPY --from=build /usr/sbin /usr/sbin
COPY --from=build /var/lib/asterisk /var/lib/asterisk
COPY --from=build /etc/asterisk /etc/asterisk

# Set ownership and permissions in a single step
RUN chown -R asterisk:asterisk /var/lib/asterisk && chmod -R 750 /var/lib/asterisk

# Set the entrypoint to start Asterisk
ENTRYPOINT ["/usr/sbin/asterisk", "-U", "asterisk", "-G", "asterisk", "-pvvvdddf"]
