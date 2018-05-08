FROM ubuntu:xenial
MAINTAINER Jan Blaha
EXPOSE 5488

RUN adduser --disabled-password --gecos "" jsreport && \
    apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y --no-install-recommends nodejs \
        libgtk2.0-dev \
        libxtst-dev \
        libxss1 \
        libgconf2-dev \
        libnss3-dev \
        libasound2-dev \
        xfonts-75dpi \
        xfonts-base \
		default-jre\
		locales tzdata 
  
RUN rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/apt/* && \
    curl -Lo phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 && \
    tar jxvf phantomjs.tar.bz2 && \
    chmod -R u+x phantomjs-1.9.8-linux-x86_64/bin/phantomjs && \
    mv phantomjs-1.9.8-linux-x86_64/bin/phantomjs /usr/local/bin/ && \
    rm -rf phantomjs*

VOLUME ["/jsreport"]

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN npm install jsreport --production && \
	npm install jsreport-fop-xsl-pdf --production && \
    node node_modules/jsreport --init && \
    npm cache clean -f && \
    rm -rf node_modules/moment-timezone/data/unpacked && \
    rm -rf node_modules/moment/min

ENV NODE_ENV production
ENV phantom:strategy phantom-server
ENV tasks:strategy http-server

       
RUN locale-gen ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:ru
ENV LC_ALL ru_RU.UTF-8
RUN curl -Lo fop-2.2-bin.tar.gz http://apache-mirror.rbc.ru/pub/apache/xmlgraphics/fop/binaries/fop-2.2-bin.tar.gz && \
    tar zxf fop-2.2-bin.tar.gz && \
    rm -f fop-2.2-bin.tar.gz && \
    mv fop-2.2 /usr/local/share && \
	chmod -R u+x /usr/local/share/fop-2.2 
	
ENV PATH=/usr/local/share/fop-2.2/fop:$PATH

ADD run.sh /usr/src/app/run.sh
ADD fop.xconf /usr/src/app/fop.xconf

COPY ./fonts /usr/share/fonts
RUN fc-cache -f -v

CMD ["bash", "/usr/src/app/run.sh"]