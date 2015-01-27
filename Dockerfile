FROM php:5.6-apache

RUN apt-get update && apt-get install -y rsync && rm -r /var/lib/apt/lists/*

RUN a2enmod rewrite


# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install mysql
RUN docker-php-ext-install mbstring

VOLUME /var/www/html

RUN apt-get update && apt-get install -y unzip && rm -r /var/lib/apt/lists/*
RUN useradd -u 1000 apache && \
	sed -i -e 's/^User www-data/User apache/' /etc/apache2/apache2.conf && \
	sed -i -e 's/^Group www-data/Group staff/' /etc/apache2/apache2.conf

RUN curl -o ioncube_loaders.tar.gz http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && \
	tar zxvf ioncube_loaders.tar.gz && \
	cp ioncube/ioncube_loader_lin_5.6.so /usr/local/lib/php/extensions && \
	rm ioncube_loaders.tar.gz && \
	rm -rf ioncube && \
	echo "zend_extension = /usr/local/lib/php/extensions/ioncube_loader_lin_5.6.so" > /usr/local/etc/php/conf.d/ioncube.ini && \
	echo "session.gc_probability = 0" > /usr/local/etc/php/conf.d/session_gc.ini

RUN echo "[date]\ndate.timezone = Asia/Tokyo" > /usr/local/etc/php/conf.d/timezone.ini

RUN curl -o acms.zip http://www.a-blogcms.jp/_download/2113/54/acms2113_install.zip && \
	unzip acms.zip -d /usr/src && \
	mv /usr/src/acms*/ablogcms /usr/src/acms && \
	rm acms.zip && \
	rm -rf /usr/src/acms*_install && \
	mv /usr/src/acms/setup /usr/src/acms_setup && \
	mv /usr/src/acms/htaccess.txt /usr/src/acms/.htaccess

COPY docker-entrypoint.sh /entrypoint.sh

# RUN

# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
