FROM node:alpine
EXPOSE 5488

RUN addgroup -S jsreport && adduser -S -G jsreport jsreport 

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && apk update --no-cache \
  && apk add --no-cache \
    chromium>64.0.3282.168-r0 \
    # just for now as we npm install from git
    git \
    # so user can docker exec -it test /bin/bash
    bash \
	curl \
	openjdk7-jre \ 
  && rm -rf /var/cache/apk/* /tmp/*


VOLUME ["/jsreport"]
RUN mkdir -p /app
WORKDIR /app

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

RUN npm install -g jsreport-cli && \
    jsreport init && \
    npm uninstall -g jsreport-cli && \
	npm install jsreport-fop-xsl-pdf --production && \
	npm install jsreport-fs-store-aws-s3-persistence-all-options --production && \
    npm cache clean -f 

ADD run.sh /app/run.sh
ADD fop.xconf /app/fop.xconf
ADD jsreport.config.json /app/jsreport.config.json

ENV LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU:ru \
    LC_ALL=ru_RU.UTF-8
	

RUN curl -Lo fop-2.2-bin.tar.gz http://apache-mirror.rbc.ru/pub/apache/xmlgraphics/fop/binaries/fop-2.2-bin.tar.gz && \
    tar zxf fop-2.2-bin.tar.gz && \
    rm -f fop-2.2-bin.tar.gz && \
    mv fop-2.2 /usr/local/share && \
	chmod -R u+x /usr/local/share/fop-2.2 
	
ENV PATH=/usr/local/share/fop-2.2/fop:$PATH


COPY ./fonts /usr/share/fonts
RUN fc-cache -f -v

ENV NODE_ENV production
ENV chrome:launchOptions:executablePath /usr/lib/chromium/chrome
ENV chrome:launchOptions:args --no-sandbox
ENV templatingEngines:strategy http-server

RUN fop -v
CMD ["bash", "/app/run.sh"]