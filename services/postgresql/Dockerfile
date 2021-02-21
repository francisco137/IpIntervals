ARG PG_VERSION
FROM debian:buster
ARG PG_VERSION
RUN apt-get update
RUN apt-get install -yyy apt-utils
RUN apt-get install -yyy mc
RUN apt-get install -yyy gnupg
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 99E82A75642AC823
RUN apt-get update
RUN apt-get install -yyy postgresql-${PG_VERSION}

EXPOSE 5432 5432

COPY francisco.sql           /home/francisco/
COPY francisco_test_data.sql /home/francisco/
COPY init.sh                 /home/francisco/
RUN chmod 777 /home/francisco/init.sh
