FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt update

RUN apt install -y tzdata

# build requirements
RUN apt-get update && apt-get install -y \
  git g++-11 build-essential autoconf autotools-dev gettext libtool libtool-bin unzip \
  swig python3.10-dev python3-pip python3-twisted \
  python3-netifaces python3-usb python3-requests \
  libz-dev libssl-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libsigc++-2.0-dev \
  libfreetype6-dev libfribidi-dev \
  libavahi-client-dev libjpeg-dev libgif-dev libsdl2-dev libxml2-dev \
  libarchive-dev libcurl4-openssl-dev libgpgme11-dev libntirpc-dev \
  x11vnc xvfb xdotool nginx ssh curl

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
 && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

RUN rm /usr/bin/python3 && ln -sf /usr/bin/python3.10 /usr/bin/python3
RUN rm /usr/bin/pygettext3 && ln -sf /usr/bin/pygettext3.10 /usr/bin/pygettext3
RUN rm /usr/bin/pydoc3 && ln -sf /usr/bin/pydoc3.10 /usr/bin/pydoc3
RUN rm /usr/bin/python3-config && ln -sf /usr/bin/python3.10-config /usr/bin/python3-config

RUN pip3 install wifi

WORKDIR /work

ARG OPKG_VER="0.5.0"
RUN curl -L "http://git.yoctoproject.org/cgit/cgit.cgi/opkg/snapshot/opkg-$OPKG_VER.tar.gz" -o opkg.tar.gz
RUN tar -xzf opkg.tar.gz \
 && cd "opkg-$OPKG_VER" \
 && ./autogen.sh \
 && ./configure --enable-curl --enable-ssl-curl --enable-gpg --prefix=/usr --sysconfdir=/etc \
 && make \
 && make install

RUN git clone --depth 1 https://github.com/oe-alliance/libdvbsi.git
RUN cd libdvbsi \
 && ./autogen.sh \
 && ./configure --prefix=/usr \
 && make \
 && make install

RUN git clone --depth 1 https://github.com/OpenPLi/tuxtxt.git
RUN cd tuxtxt/libtuxtxt \
 && autoreconf -i \
 && CPP="gcc -E -P" ./configure --with-boxtype=generic --prefix=/usr \
 && make \
 && make install
RUN cd tuxtxt/tuxtxt \
 && autoreconf -i \
 && CPP="gcc -E -P" ./configure --with-boxtype=generic --prefix=/usr \
 && make \
 && make install

ENV base_libdir=/usr/lib

RUN git clone --depth 1 https://github.com/openatv/enigma2.git
RUN cd enigma2 \
 && ./autogen.sh \
 && ./configure --with-libsdl --with-gstversion=1.0 --prefix=/usr --sysconfdir=/etc \
 && make -j4 \
 && make install
# disable startup wizards
COPY enigma2-settings /etc/enigma2/settings
RUN ldconfig

RUN git clone --depth 10 https://github.com/oe-mirrors/branding-module.git
COPY ax_python_devel.m4 branding-module/m4/ax_python_devel.m4
RUN cd branding-module \
 && autoreconf -i \
 && ./configure --prefix=/usr --with-imageversion="7.1" \
 && make \
 && make install

RUN git clone --depth 1 https://github.com/openatv/MetrixHD.git -b dev
RUN cd MetrixHD && cp -arv usr /
# && rm -r /usr/lib/enigma2/python/Plugins/Extensions/MyMetrixLite

RUN git clone --depth 1 https://github.com/oe-alliance/oe-alliance-e2-skindefault.git
RUN cd oe-alliance-e2-skindefault && cp -arv fonts /usr/share/ && cp -arv skin_default /usr/share/enigma2/ && cp -arv skin_fallback_1080 /usr/share/enigma2/ && cp skin*.xml /usr/share/enigma2/ && cp prev.png /usr/share/enigma2/


# rpc error
RUN cp /usr/include/tirpc/rpc/* /usr/include/rpc/
RUN cp /usr/include/tirpc/netconfig.h /usr/include/

# enigma2-plugins
RUN git clone --depth 1 https://github.com/oe-alliance/enigma2-plugins.git
COPY ax_python_devel.m4 enigma2-plugins/m4/ax_python_devel.m4
RUN cd enigma2-plugins \
 && sed -i '/PKG_CHECK_MODULES(ENIGMA2, enigma2)/d' ./configure.ac \
 && sed -i '/PKG_CHECK_MODULES(LIBCRYPTO, libcrypto)/d' ./configure.ac \
 && autoreconf -i \
 && ./configure --prefix=/usr --without-debug --with-po \
 && make \
 && make install

# oe-alliance-plugins
RUN git clone --depth 1 https://github.com/oe-alliance/oe-alliance-plugins.git
COPY ax_python_devel.m4 oe-alliance-plugins/m4/ax_python_devel.m4
RUN cd oe-alliance-plugins \
 && autoreconf -i \
 && ./configure --prefix=/usr \
 && make \
 && make install


# OWI
RUN git clone --depth 1 https://github.com/E2OpenPlugins/e2openplugin-OpenWebif.git
COPY OWI.sh e2openplugin-OpenWebif/OWI.sh
RUN cd e2openplugin-OpenWebif \  
 && chmod 755 OWI.sh \
 && ./OWI.sh

COPY enigma.info /usr/lib/enigma.info

COPY process.py /usr/lib/python3.10/site-packages/process.py

# OPKG
RUN mkdir -p /etc/opkg && mkdir -p /var/lib/opkg/lists && mkdir -p /var/lib/opkg/info
RUN echo "dest root /" > /etc/opkg/opkg.conf
RUN echo "option lists_dir /var/lib/opkg/lists" >> /etc/opkg/opkg.conf
RUN echo "arch all 1" > /etc/opkg/arch.conf
RUN echo "arch any 6" >> /etc/opkg/arch.conf
RUN echo "arch noarch 11" >> /etc/opkg/arch.conf
RUN echo "src/gz openatv-all http://feeds2.mynonpublic.com/7.1/vusolo4k/all" >> /etc/opkg/all-feed.conf
RUN echo "src/gz oe-alliance-settings-feed https://raw.githubusercontent.com/oe-alliance/oe-alliance-settings-feed/master/feed" >> /etc/opkg/oe-alliance-settings-feed.conf

COPY opkg.py /work/opkg.py
RUN python opkg.py

RUN if [ -f /usr/lib32/libc.so.6 ]; then ln -snf /usr/lib32/libc.so.6 /usr/lib/libc.so.6; fi
RUN if [ -f /usr/lib/aarch64-linux-gnu/libc.so.6 ]; then ln -snf /usr/lib/aarch64-linux-gnu/libc.so.6 /usr/lib/libc.so.6; fi

COPY entrypoint.sh /opt
RUN chmod 755 /opt/entrypoint.sh
ENV DISPLAY=:99
EXPOSE 5900 80 22
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD bash
