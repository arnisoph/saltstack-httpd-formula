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
