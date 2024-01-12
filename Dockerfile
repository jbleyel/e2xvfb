FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt update

RUN apt install -y tzdata

RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa -y

# build requirements
RUN apt-get update && apt-get install -y \
  git g++-12 build-essential autoconf autotools-dev gettext libtool libtool-bin unzip swig \
  python3.12-dev \
  python3-twisted python3-usb python3-requests \
  libz-dev libssl-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libsigc++-2.0-dev \
  libfreetype6-dev libfribidi-dev \
  libavahi-client-dev libjpeg-dev libgif-dev libsdl2-dev libxml2-dev \
  libarchive-dev libcurl4-openssl-dev libgpgme11-dev libntirpc-dev \
  x11vnc xvfb xdotool nginx openssh-server curl vsftpd nano locales iputils-ping net-tools gdb valgrind libsqlite3-dev


RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8


RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py

RUN find / -name 'pip*'

RUN update-alternatives --install /usr/bin/pip pip /usr/local/bin/pip3.12 1

RUN rm /usr/bin/python3 && ln -sf /usr/bin/python3.12 /usr/bin/python3
RUN rm /usr/bin/pygettext3 && ln -sf /usr/bin/pygettext3.12 /usr/bin/pygettext3
RUN rm /usr/bin/pydoc3 && ln -sf /usr/bin/pydoc3.12 /usr/bin/pydoc3
#RUN rm /usr/bin/python3-config && ln -sf /usr/bin/python3.12-config /usr/bin/python3-config
#RUN rm /usr/bin/python3-config && ln -sf /usr/local/bin/pip3.12 /usr/bin/pip3

#RUN pip3 install --upgrade pip
RUN pip3 install setuptools

RUN pip3 install wifi
RUN pip3 install Cheetah3
RUN pip3 install pillow
RUN pip3 install treq
RUN pip3 install future
RUN pip3 install netifaces  
RUN pip3 install cffi
RUN pip3 install puremagic
RUN pip3 install tmdbsimple
RUN pip3 install tvdbsimple
#RUN pip3 install sqlite
#RUN pip3 install scalene

WORKDIR /work

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

ARG OPKG_VER="0.6.1"
RUN curl -L "http://downloads.yoctoproject.org/releases/opkg/opkg-$OPKG_VER.tar.gz" -o opkg.tar.gz
RUN tar -xzf opkg.tar.gz
RUN cd "opkg-$OPKG_VER" \
  && ./configure --enable-gpg --disable-curl --prefix=/usr --sysconfdir=/etc \
  && make \
  && make install


RUN git clone --depth 1 https://github.com/openatv/enigma2.git
COPY ax_python_devel.m4 /work/enigma2/m4/ax_python_devel.m4
RUN cd enigma2 \
  && ./autogen.sh \
  && ./configure --with-libsdl --with-gstversion=1.0 --prefix=/usr --sysconfdir=/etc --with-boxtype=dm920 \
  && make -j4 \
  && make install
RUN ldconfig

RUN git clone --depth 10 https://github.com/oe-mirrors/branding-module.git
COPY ax_python_devel.m4 branding-module/m4/ax_python_devel.m4
RUN cd branding-module \
  && autoreconf -i \
  && ./configure --prefix=/usr --with-imageversion="7.4" \
  && make \
  && make install

RUN git clone --depth 1 https://github.com/openatv/MetrixHD.git -b master
RUN cd MetrixHD && cp -arv usr /

#default skin
RUN git clone --depth 1 https://github.com/openatv/oe-alliance-e2-skindefault.git
RUN cd oe-alliance-e2-skindefault && cp -arv fonts /usr/share/ && cp -arv skin_default /usr/share/enigma2/ && cp skin*.xml /usr/share/enigma2/ && cp prev.png /usr/share/enigma2/

#overlayhd
RUN git clone --depth 1 https://github.com/IanSav/OverlayHD.git
RUN cd OverlayHD && cp -arv usr /

RUN git clone --depth 1 https://github.com/openatv/WeatherInfo.git
RUN cd WeatherInfo && cp Weatherinfo.py /usr/lib/enigma2/python/Tools/


# rpc error
RUN cp /usr/include/tirpc/rpc/* /usr/include/rpc/
RUN cp /usr/include/tirpc/netconfig.h /usr/include/

# oe-alliance-plugins
RUN git clone --depth 1 https://github.com/oe-alliance/oe-alliance-plugins.git
COPY Makefile-oe-alliance-plugins.am oe-alliance-plugins/Makefile.am
COPY ax_python_devel.m4 enigma2-plugins/m4/ax_python_devel.m4
RUN cd oe-alliance-plugins \
 && autoreconf -i \
 && ./configure --prefix=/usr \
 && make \
 && make install


# enigma2-plugins
RUN git clone --depth 1 https://github.com/oe-alliance/enigma2-plugins.git
COPY Makefile-enigma2-plugins.am enigma2-plugins/Makefile.am
COPY ax_python_devel.m4 enigma2-plugins/m4/ax_python_devel.m4
RUN cd enigma2-plugins \
 && sed -i '/PKG_CHECK_MODULES(ENIGMA2, enigma2)/d' ./configure.ac \
 && sed -i '/PKG_CHECK_MODULES(LIBCRYPTO, libcrypto)/d' ./configure.ac \
 && autoreconf -i \
 && ./configure --prefix=/usr --without-debug --with-po \
 && make \
 && make install

# OWI
RUN git clone --depth 1 https://github.com/oe-alliance/OpenWebif.git
COPY OWI.sh OpenWebif/OWI.sh
RUN cd OpenWebif \  
  && chmod 755 OWI.sh \
  && ./OWI.sh



RUN git clone --depth 1 https://github.com/oe-mirrors/e2openplugin-EnhancedMovieCenter.git
RUN cd e2openplugin-EnhancedMovieCenter \  
  && autoreconf -i \
  && ./configure --prefix=/usr \
  && make \
  && make install

COPY enigma.info /usr/lib/enigma.info

COPY process.py /usr/lib/python3.12/site-packages/process.py


# OPKG
RUN mkdir -p /etc/opkg && mkdir -p /var/lib/opkg/lists && mkdir -p /var/lib/opkg/info
RUN echo "dest root /" > /etc/opkg/opkg.conf
RUN echo "option lists_dir /var/lib/opkg/lists" >> /etc/opkg/opkg.conf
RUN echo "option status_file /var/lib/opkg/status" >> /etc/opkg/opkg.conf
RUN echo "arch all 1" > /etc/opkg/arch.conf
RUN echo "arch any 6" >> /etc/opkg/arch.conf
RUN echo "arch noarch 11" >> /etc/opkg/arch.conf
RUN echo "src/gz openatv-all http://feeds2.mynonpublic.com/7.4/vusolo4k/all" >> /etc/opkg/all-feed.conf
RUN echo "src/gz oe-alliance-settings-feed https://raw.githubusercontent.com/oe-alliance/oe-alliance-settings-feed/master/feed" >> /etc/opkg/oe-alliance-settings-feed.conf

COPY opkg.py /work/opkg.py
RUN python opkg.py

RUN if [ -f /usr/lib32/libc.so.6 ]; then ln -snf /usr/lib32/libc.so.6 /usr/lib/libc.so.6 && chmod 755 /usr/lib32/libc.so.6; fi
RUN if [ -f /usr/lib/aarch64-linux-gnu/libc.so.6 ]; then ln -snf /usr/lib/aarch64-linux-gnu/libc.so.6 /usr/lib/libc.so.6 && chmod 755 /usr/lib/aarch64-linux-gnu/libc.so.6; fi

RUN rm -rf /work/*

# SSH
RUN mkdir /var/run/sshd
RUN echo 'root:docker' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN echo 'export NOTVISIBLE="in users profile"' >> ~/.bashrc
RUN echo "export VISIBLE=now" >> /etc/profile
RUN bash -c 'install -m755 <(printf "#!/bin/sh\nexit 0") /usr/sbin/policy-rc.d'

# FTP
COPY vsftpd.conf /etc/
RUN mkdir -p /var/run/vsftpd/empty
RUN sed -i '/root/d' /etc/ftpusers

RUN mkdir -p /usr/share/enigma2/receiver
COPY test.png /usr/share/enigma2/receiver
COPY test_front.png /usr/share/enigma2/receiver
COPY entrypoint.sh /opt
RUN chmod 755 /opt/entrypoint.sh
ENV DISPLAY=:99
EXPOSE 5900 80 81 21 22 20
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD bash
