# Define build arguments with defaults
ARG ASTERISK_VERSION=23
ARG BASE_VERSION=9-minimal
ARG ENABLE_CHAN_SIP=true

# Static build stage
FROM rockylinux:9 AS build

ARG ASTERISK_VERSION
ARG BASE_VERSION
ARG ENABLE_CHAN_SIP

# Install build dependencies with dnf
RUN dnf -y update && \
    dnf -y install \
        wget \
        epel-release \
        gcc \
        gcc-c++ \
        make \
        ncurses-devel \
        libxml2-devel \
        sqlite-devel \
        git \
        diffutils \
        libedit-devel \
        openssl-devel \
        libuuid-devel \
        autoconf \
        automake \
        libtool \
        pkgconfig && \
    dnf clean all && \
    rm -rf /var/cache/dnf/*

# Disable SELinux if the config file exists (build context only)
RUN if [ -f /etc/selinux/config ]; then \
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config && \
        setenforce 0 2>/dev/null || true; \
    fi

WORKDIR /usr/src

# Clone Asterisk from GitHub tree based on the version
RUN set -ex && \
    echo "Cloning Asterisk from GitHub tree (version ${ASTERISK_VERSION})"; \
    git clone --depth 1 --single-branch --branch ${ASTERISK_VERSION} https://github.com/asterisk/asterisk.git asterisk && \
    cd asterisk && \
    if [ "$ENABLE_CHAN_SIP" = "true" ]; then \
        echo "Reincluding chan_sip module..."; \
        wget https://raw.githubusercontent.com/InterLinked1/chan_sip/master/chan_sip_reinclude.sh && \
        chmod +x chan_sip_reinclude.sh && \
        ./chan_sip_reinclude.sh && \
        echo "chan_sip module reincluded successfully"; \
    else \
        echo "Skipping chan_sip reinclude"; \
    fi && \
    contrib/scripts/install_prereq install && \
    NOISY_BUILD=yes ./configure \
        --libdir=/usr/lib64 \
        --with-pjproject-bundled \
        --with-jansson-bundled \
        --enable-dev-mode=no \
        --disable-xmldoc && \
    make menuselect.makeopts && \
    menuselect/menuselect \
        --disable BUILD_NATIVE \
        --disable-category MENUSELECT_ADDONS \
        $( [ "$ENABLE_CHAN_SIP" = "true" ] && echo "--enable chan_sip" ) \
        menuselect.makeopts && \
    make channels && \
    make -j$(nproc) && \
    make install && \
    make samples && \
    make basic-pbx && \
    make clean && \
    cd .. && rm -rf asterisk

# Runtime stage - minimal image with only necessary components
FROM rockylinux:${BASE_VERSION}

ARG BASE_VERSION

RUN microdnf install dnf && \
    dnf -y update && \
    dnf -y install epel-release libedit ncurses libxml2 sqlite gettext sox && \
    dnf clean all

RUN groupadd -r asterisk && useradd -r -g asterisk asterisk

COPY --from=build /usr/lib64 /usr/lib64
COPY --from=build /usr/sbin /usr/sbin
COPY --from=build /var/lib/asterisk /var/lib/asterisk
COPY --from=build /etc/asterisk /etc/asterisk

RUN chown -R asterisk:asterisk /var/lib/asterisk && chmod -R 750 /var/lib/asterisk

ENTRYPOINT ["/usr/sbin/asterisk", "-U", "asterisk", "-G", "asterisk", "-pvvvdddf"]
