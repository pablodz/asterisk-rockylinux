# Stage 1: Build Asterisk
FROM rockylinux:9-minimal AS build

ARG ASTERISK_VERSION=22

# Install build dependencies
RUN microdnf install -y dnf && microdnf clean all && \
    ln -s /usr/bin/dnf /usr/bin/yum && \
    dnf -y update && \
    dnf -y install wget tar epel-release chkconfig libedit-devel gcc gcc-c++ make ncurses-devel \
    libxml2-devel sqlite-devel git diffutils && \
    dnf clean all

# Disable SELinux (only if the config file exists)
RUN if [ -f /etc/selinux/config ]; then \
        sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config && \
        setenforce 0; \
    fi

# Download and compile Asterisk
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
FROM rockylinux:9-minimal

# Install runtime dependencies
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

# Set ownership and permissions
RUN chown -R asterisk:asterisk /var/lib/asterisk && \
    chmod -R 750 /var/lib/asterisk

# Set the entrypoint to start Asterisk with specified user, group, and verbosity
ENTRYPOINT ["/usr/sbin/asterisk", "-U", "asterisk", "-G", "asterisk", "-pvvvdddf"]
