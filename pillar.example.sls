httpd:
  lookup:
    modules:
      passenger:
        manage: True
      ssl:
        manage: True
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
      content: |
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
