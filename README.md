<h1>mpublish.sh</h1>

One command way to publish meteor application in Your private web server.

Why?
Meteor team work at very big, safe and excellent Galaxy module. This will be awesome - when it’ll be ready. mpublish.sh script is well-enough utility which make Your local meteor application running as a full-web site with one command way. 

Description
You can have many working application in single web server - everyone with other site domain name. For example: test1.yourserver.com, test2.yourserver2.nl etc. Every web call is managing with nginx server with proper proxy configuration. If You call test1.yourserver.com nginx transfer your connection to application working on the separate port number.
To make mpublish.sh working well i had have to write second script planed to work in server site - /etc/init.d/nodejs. This script manage working every nodejs application located on your server and make for You proper reconfiguration of nginx server.

Howto, Simplest way:
- write meteor application in your mac and go to this directory
- mpublish.sh --server=root@your-web.org --dir=/var/lib/node --site=site1.your-web.org

Is that simple. You can now go in browser to site1.your-web.org and application will works.
To make Your web server working, You have to do obviously some simple steps. For Your convenience mpublish.sh have option --genconfig - that saves Your command parameters in meteor app directory and follow that You can use mpublish.sh invokation without any params.
mpublish.sh have simple command line help of course.

Howto, server configuration
mpublish.sh is wrote and tested for debian squeeze (6.0) server.
In server You have to install nodejs, forever for nodejs, mongodb working at standard 27017 port and nginx server.
You can do this with this simple way:

# install curl
apt-get install curl

# install nginx server
cd /tmp && \
curl http://nginx.org/keys/nginx_signing.key > nginx_signing.key && \
apt-key add nginx_signing.key && \
rm nginx_signing.key && \
echo "deb http://packages.dotdeb.org squeeze all" >> /etc/apt/sources.list && \
echo "deb-src http://packages.dotdeb.org squeeze all" >> /etc/apt/sources.list && \
wget http://www.dotdeb.org/dotdeb.gpg && \
apt-key add dotdeb.gpg && \
rm -f dotdeb.gpg && \
apt-get update && \
apt-get install nginx && \
cat /etc/nginx/nginx.conf|sed 's/http {/http {\n\tmap $http_upgrade $connection_upgrade { default upgrade; ""      close; }\n/g' >/tmp/nginx.conf && \
cp -f /tmp/nginx.conf /etc/nginx/nginx.conf && \
/etc/init.d/nginx restart

# install nodejs - you can change the way of installing nodejs and get another version if you like
cd /tmp && \
curl https://nodejs.org/dist/v0.12.6/node-v0.12.6-linux-x86.tar.gz > node-v0.12.6-linux-x86.tar.gz && \
mkdir -p /opt/node  && \
tar zxf node-v0.12.6-linux-x86.tar.gz -C /opt/node/  && \
rm node-v0.12.6-linux-x86.tar.gz  && \
cd /opt/node  && \
ln -sfn node-v0.12.6-linux-x86 current

# node postrequisites
cd /usr/local/bin && \
ln -s /opt/node/current/bin/npm && \
ln -s /opt/node/current/bin/node
npm install -g forever

# install mongodb
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10 && \
echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.0 main" | tee /etc/apt/sources.list.d/mongodb-org-3.0.list && \
apt-get update && \
apt-get install mongodb

# install mpublish scripts
mkdir -p /var/lib/node
copy nodejs into /etc/init.d && chmod +x /etc/init.d/nodejs
