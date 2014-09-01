httpd:
  lookup:
    mods:
      modules:
        passenger:
          manage: True
        ssl:
          manage: True
          config:
            plain: |
              SSLRandomSeed startup builtin
              SSLRandomSeed startup file:/dev/urandom 512
              SSLRandomSeed connect builtin
              SSLRandomSeed connect file:/dev/urandom 512

              AddType application/x-x509-ca-cert .crt
              AddType application/x-pkcs7-crl    .crl

              SSLPassPhraseDialog  builtin

              SSLSessionCache        shmcb:${APACHE_RUN_DIR}/ssl_scache(512000)
              SSLSessionCacheTimeout  300

              SSLMutex  file:${APACHE_RUN_DIR}/ssl_mutex

              SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5

              SSLProtocol all -SSLv2
        userdir:
          manage: True
          enable: False
        status:
          manage: True
          enable: False
        autoindex:
          manage: True
          enable: False
  vhosts:
    default:
      ensure: absent
      linkname: 000-default
    default_ssl:
      name: default-ssl
      ensure: absent
    sunstone:
      plain: |
        <VirtualHost *:80>
            ServerName sunstone-server
            DocumentRoot /usr/lib/one/sunstone/public

            PassengerUser oneadmin
            PassengerMaxInstancesPerApp 1

            <Directory /usr/lib/one/sunstone/public>
                AllowOverride all
                Options -MultiViews
            </Directory>
        </VirtualHost>
        <VirtualHost *:443>
            ServerName sunstone-server
            DocumentRoot /usr/lib/one/sunstone/public

            PassengerUser oneadmin
            PassengerMaxInstancesPerApp 1

            <Directory /usr/lib/one/sunstone/public>
                AllowOverride all
                Options -MultiViews
            </Directory>

            SSLEngine on
            SSLCertificateFile      /etc/ssl/certs/cert.pem
            SSLCertificateKeyFile   /etc/ssl/private/key.key
            SSLCertificateChainFile /etc/ssl/certs/ca.pem

            Header always set Strict-Transport-Security "max-age=31556926"
        </VirtualHost>


{# Open Monitoring Distribution (OMD) HTTP vhost setup #}
httpd:
  lookup:
    mods:
      modules:
        headers:
          manage: True
        rewrite:
          manage: True
        ssl:
          manage: True
          config:
            plain: |
              SSLRandomSeed startup builtin
              SSLRandomSeed startup file:/dev/urandom 512
              SSLRandomSeed connect builtin
              SSLRandomSeed connect file:/dev/urandom 512

              AddType application/x-x509-ca-cert .crt
              AddType application/x-pkcs7-crl    .crl

              SSLPassPhraseDialog builtin

              SSLSessionCache shmcb:${APACHE_RUN_DIR}/ssl_scache(512000)
              SSLSessionCacheTimeout  300

              SSLMutex file:${APACHE_RUN_DIR}/ssl_mutex

              SSLHonorCipherOrder On
              SSLCipherSuite ECDHE-RSA-AES128-SHA256:AES128-GCM-SHA256:HIGH:!MD5:!aNULL:!EDH:!RC4

              SSLProtocol all -SSLv2
        userdir:
          manage: True
          enable: False
        status:
          manage: True
          enable: False
        autoindex:
          manage: True
          enable: False
        proxy:
          manage: True
        proxy_http:
          manage: True
  vhosts:
    default:
      ensure: absent
      linkname: 000-default
    default_ssl:
      name: default-ssl
      ensure: absent
    omd:
      plain: |
        <VirtualHost *:80>
          RewriteEngine On
          RewriteCond %{HTTPS} !=on
          RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]
        </VirtualHost>
    omd_ssl:
      plain: |
        <VirtualHost *:443>
          SSLEngine on
          SSLCertificateFile /etc/ssl/certs/my.domain.local.crt.pem
          SSLCertificateKeyFile /etc/ssl/private/my.domain.local.key.pem
          SSLCertificateChainFile /etc/ssl/certs/my.domain.local.ca.pem
          SSLCACertificateFile /etc/ssl/certs/my.domain.local.ca.pem
          SSLCACertificatePath /etc/ssl/certs

          # Make sure that symlink /omd does not make problems
          <Directory />
            Options +FollowSymlinks
          </Directory>

          <IfModule mod_proxy_http.c>
            ProxyRequests Off
            ProxyPreserveHost On
            Include /omd/sites/mysitenamehere/etc/apache/proxy-port.conf
          </IfModule>

          <Location /mysitenamehere>
            ErrorDocument 503 "Error 503, site not started?"
            SSLRequireSSL
            Header always set Strict-Transport-Security "max-age=31556926;includeSubdomains"

            SetEnv OMD_SITE mysitenamehere
            SetEnv OMD_ROOT /omd/sites/mysitenamehere
            SetEnv OMD_MODE own
          </Location>
        </VirtualHost>
    myvhost:
      template_path: 'salt://httpd/files/customvhosttemplate'
      context:
        servername: my.domain.de
        webroot: /var/www/myvhost
        tmproot: /tmp
        proxyport: 9007
        suexec:
          user: myvhost
          group: myvhost
