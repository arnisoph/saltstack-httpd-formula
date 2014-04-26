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
