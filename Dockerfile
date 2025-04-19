ARG ASTERISK_VERSION=latest
ARG BASE_VERSION=9-minimal

FROM rockylinux:${BASE_VERSION} AS build

ARG ASTERISK_VERSION
ARG BASE_VERSION

RUN if [[ "${BASE_VERSION}" == *minimal ]]; then \
        echo "Minimal version detected, installing dnf..." && \
        microdnf install -y dnf && microdnf clean all && \
        ln -s /usr/bin/dnf /usr/bin/yum && \
        dnf -y update && \
        dnf -y install wget tar epel-release chkconfig libedit-devel gcc gcc-c++ make ncurses-devel \
        libxml2-devel sqlite-devel git diffutils && \
        dnf clean all; \
    else \
        echo "Standard version detected, installing dnf..." && \
        dnf -y update && \
        dnf -y install wget tar epel-release chkconfig gcc gcc-c++ make ncurses-devel \
        libxml2-devel sqlite-devel git diffutils && \
        dnf clean all; \
    fi

RUN if [ -f /etc/selinux/config ]; then \
        sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config && \
        setenforce 0; \
    fi

WORKDIR /usr/src
RUN if [ "${ASTERISK_VERSION}" = "latest" ]; then \
        git clone --depth 1 https://github.com/asterisk/asterisk.git && \
        cd asterisk; \
    else \
        wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}-current.tar.gz && \
        tar zxvf asterisk-${ASTERISK_VERSION}-current.tar.gz && \
        rm -rf asterisk-${ASTERISK_VERSION}-current.tar.gz && \
        cd asterisk-${ASTERISK_VERSION}*; \
    fi && \
    contrib/scripts/install_prereq install && \
    ./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled && \
    make menuselect.makeopts && \
    menuselect/menuselect --disable BUILD_NATIVE --disable-category MENUSELECT_ADDONS menuselect.makeopts && \
    make -j$(nproc) && \
    make install && \
    make samples && \
    make basic-pbx

FROM rockylinux:${BASE_VERSION}

ARG BASE_VERSION

RUN if [[ "${BASE_VERSION}" == *minimal ]]; then \
        echo "Minimal version detected, installing dnf..." && \
        microdnf install -y dnf && microdnf clean all && \
        dnf -y update && \
        dnf -y install epel-release libedit ncurses libxml2 sqlite gettext && \
        dnf clean all; \
    else \
        echo "Standard version detected, installing dnf..." && \
        dnf -y update && \
        dnf -y install epel-release libedit ncurses libxml2 sqlite gettext && \
        dnf clean all; \
    fi

RUN groupadd -r asterisk && useradd -r -g asterisk asterisk

COPY --from=build /usr/lib64 /usr/lib64
COPY --from=build /usr/sbin /usr/sbin
COPY --from=build /var/lib/asterisk /var/lib/asterisk
COPY --from=build /etc/asterisk /etc/asterisk

RUN chown -R asterisk:asterisk /var/lib/asterisk && chmod -R 750 /var/lib/asterisk

ENTRYPOINT ["/usr/sbin/asterisk", "-U", "asterisk", "-G", "asterisk", "-pvvvdddf"]
