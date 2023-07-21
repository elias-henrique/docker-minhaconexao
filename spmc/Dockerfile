FROM ubuntu

WORKDIR /
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install wget -y
RUN apt-get install build-essential -y
RUN apt-get install manpages-dev -y
RUN apt-get install libssl-dev -y
RUN apt-get install openssl -y
RUN wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb
RUN dpkg -i libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb

COPY install.sh /
RUN chmod a+x install.sh

RUN bash install.sh

EXPOSE 9090

CMD ["/usr/bin/mc-test", "--cert-path", "/etc/mc-test/keys/star.mcservers.co.crt", "--pfx-path", "/etc/mc-test/keys/full-cert.pfx"]

