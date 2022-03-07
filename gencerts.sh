#!/bin/bash

domains=($REVERSE_PROXY_DOMAIN_NAME)
rsa_key_size=4096
data_path="./certbot"
email="yeh@jigentec.com" # Adding a valid address is strongly recommended
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi


if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  echo
fi

echo "### Creating dummy certificate for $domains ..." ;
for domain in "${domains[@]}" ; do
    path="/etc/letsencrypt/live/$domain" ;
    mkdir -p "$data_path/conf/live/$domain" ;
    docker-compose run --rm --entrypoint " \
        openssl req -x509 -nodes -newkey rsa:1024 -days 1 \
        -keyout '$path/privkey.pem' \
        -out '$path/fullchain.pem' \
        -subj '/CN=localhost'" certbot ;
done
echo "### Done creating dummy certificates."

# Jenkins needs to be up or else nginx will complain, so we run it solo
echo "### Starting nginx ..."
docker run --rm \
       -p 80:80 \
       -v $PWD/nginx/certbot.conf:/etc/nginx/nginx.conf \
       -v $PWD/certbot/conf:/etc/letsencrypt \
       -v $PWD/certbot/www:/var/www/certbot \
       -d nginx

echo "### Deleting dummy certificate for $domains ..."
for domain in "${domains[@]}" ; do
    docker-compose run --rm --entrypoint " \
        rm -Rf /etc/letsencrypt/live/$domain && \
        rm -Rf /etc/letsencrypt/archive/$domain && \
        rm -Rf /etc/letsencrypt/renewal/$domain.conf" certbot ;
done
echo "### Done deleting dummy certificates."

echo "### Running certbot for $domains ..."
for domain in "${domains[@]}" ; do
    # Select appropriate email arg
    case "$email" in
        "") email_arg="--register-unsafely-without-email" ;;
        *) email_arg="--email $email" ;;
    esac
    # Enable staging mode if needed
    if [ $staging != "0" ]; then staging_arg="--staging"; fi
    # Request certificate
    echo "### Requesting Let's Encrypt certificate for $domain ..."
   docker-compose run --rm --entrypoint " \
        certbot certonly --webroot -w /var/www/certbot \
        $staging_arg \
        $email_arg \
        -d $domain \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal" certbot ;
done
echo "### Done running certbot for $domains."

echo "### Cleaning up..."
docker rm $(docker stop $(docker ps -a -q --filter ancestor=nginx --format="{{.ID}}"))
docker-compose down
