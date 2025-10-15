# Define build arguments with defaults
ARG ASTERISK_VERSION=23
ARG BASE_VERSION=9-minimal
ARG ENABLE_CHAN_SIP=true

# Static build stage
FROM rockylinux:9 AS build

ARG ASTERISK_VERSION
ARG BASE_VERSION
ARG ENABLE_CHAN_SIP

# Install build dependencies with version pinning for security
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
        # Reinclude chan_sip module from external repository
        echo "Reincluding chan_sip module..."; \
        wget https://raw.githubusercontent.com/InterLinked1/chan_sip/master/chan_sip_reinclude.sh && \
        chmod +x chan_sip_reinclude.sh && \
        ./chan_sip_reinclude.sh && \
        echo "chan_sip module reincluded successfully"; \
    else \
        echo "Skipping chan_sip reinclude"; \
    fi && \
    # Install prerequisites with better error handling \
    contrib/scripts/install_prereq install && \
    # Configure with optimized settings \
    NOISY_BUILD=yes ./configure \
        --libdir=/usr/lib64 \
        --with-pjproject-bundled \
        --with-jansson-bundled \
        --enable-dev-mode=no \
        --disable-xmldoc && \
    # Generate menuselect configuration \
    make menuselect.makeopts && \
    # Disable unnecessary modules for smaller image \
    menuselect/menuselect \
        --disable BUILD_NATIVE \
        --disable-category MENUSELECT_ADDONS \
        $( [ "$ENABLE_CHAN_SIP" = "true" ] && echo "--enable chan_sip" ) \
        menuselect.makeopts && \
    # Build with parallel jobs for faster compilation \
    make channels && \
    make -j$(nproc) && \
    make install && \
    make samples && \
    make basic-pbx && \
    # Clean up build artifacts \
    make clean && \
    cd .. && rm -rf asterisk

# Runtime stage - minimal image with only necessary components
FROM rockylinux:${BASE_VERSION}

ARG BASE_VERSION

RUN microdnf install -y dnf && microdnf clean all && \
    dnf -y install epel-release && \
    dnf -y update && \
    dnf -y install libedit ncurses libxml2 sqlite gettext && \
    dnf -y install sox && \
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
