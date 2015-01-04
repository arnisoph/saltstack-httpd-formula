#!jinja|yaml

{% from "httpd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('httpd:lookup')) %}

{% for k, v in salt['pillar.get']('httpd:vhosts', {})|dictsort if v.site_setup|default(False) %}
  {% if v.ensure|default('managed') in ['managed'] %}
    {% set f_fun = 'managed' %}
  {% elif v.ensure|default('managed') in ['absent'] %}
    {% set f_fun = 'absent' %}
  {% endif %}

  {% set id = v.name|default(k) %}
  {% set siteroot = v.context.siteroot|default({'path': '/var/www/' ~ id}) %}
  {% set tmproot = v.context.tmproot|default({}) %}
  {% set webroot = v.context.webroot|default({}) %}
  {% set docroot = v.context.docroot|default({}) %}
  {% set logroot = v.context.logroot|default({}) %}
  {% set privroot = v.context.privroot|default({}) %}
  {% set fcgistarterroot = v.context.fcgistarterroot|default({}) %}

  {% if f_fun in ['managed'] %}
    {% if logroot.ensure|default('present') == 'present' %}
setup_site_{{ k }}_logroot:
  file:
    - directory
    - name: {{ siteroot.path }}{{ logroot.path|default('/logs') }}
    - mode: {{ logroot.mode|default(770) }}
    - user: {{ logroot.user|default('root') }}
    - group: {{ logroot.group|default('root') }}
    - require:
      - file: setup_site_{{ k }}_siteroot
    {% endif %}

    {% if tmproot.ensure|default('present') == 'present' %}
setup_site_{{ k }}_tmproot:
  file:
    - directory
    - name: {{ siteroot.path }}{{ tmproot.path|default('/tmp') }}
    - mode: {{ tmproot.mode|default(770) }}
    - user: {{ tmproot.user|default('root') }}
    - group: {{ tmproot.group|default('root') }}
    - require:
      - file: setup_site_{{ k }}_siteroot
    {% endif %}

    {% if privroot.ensure|default('present') == 'present' %}
setup_site_{{ k }}_privroot:
  file:
    - directory
    - name: {{ siteroot.path }}{{ privroot.path|default('/priv') }}
    - mode: {{ privroot.mode|default(750) }}
    - user: {{ privroot.user|default(id) }}
    - group: {{ privroot.group|default(id) }}
    - require:
      - file: setup_site_{{ k }}_siteroot
    {% endif %}

    {% if webroot.ensure|default('present') == 'present' %}
setup_site_{{ k }}_webroot:
  file:
    - directory
    - name: {{ siteroot.path }}{{ webroot.path|default('/htdocs') }}
    - mode: {{ webroot.mode|default(750) }}
    - user: {{ webroot.user|default('root') }}
    - group: {{ webroot.group|default('root') }}
    - require:
      - file: setup_site_{{ k }}_siteroot
    {% endif %}

    {% if docroot.ensure|default('present') == 'present' %}
setup_site_{{ k }}_docroot:
  file:
    - directory
    - name: {{ siteroot.path }}{{ webroot.path|default('/htdocs') }}{{ docroot.path|default('/webroot') }}
    - mode: {{ docroot.mode|default(755) }}
    - user: {{ docroot.user|default(id) }}
    - group: {{ docroot.group|default(id) }}
    - require:
      - file: setup_site_{{ k }}_webroot
    {% endif %}

    {% if 'phpversions' in v.context %}
      {% set fcgistarterroot = v.fcgistarterroot|default({}) %}
      {% set suexec = suexec|default({}) %}
      {% set phpversiondir = v.phpversiondir|default({}) %}
      {% set fcgistarterscript = v.fcgistarterscript|default({}) %}

      {% for phpversion, phpsettings in v.context.phpversions|dictsort if phpsettings.manage|default(False) %}
setup_site_{{ k }}_{{ phpversion }}_php_fcgi_starter_root:
  file:
    - directory
    - name: {{ siteroot.path }}{{ fcgistarterroot.path|default('/conf') }}
    - mode: {{ fcgistarterroot.mode|default(750) }}
    - user: {{ fcgistarterroot.user|default(id) }}
    - group: {{ fcgistarterroot.group|default(id) }}
    - require:
      - file: setup_site_{{ k }}_siteroot.path

setup_site_{{ k }}_{{ phpversion }}_php_fcgi_starter_dir:
  file:
    - directory
    - name: {{ siteroot.path }}{{ fcgistarterroot.path|default('/conf') }}/{{ phpversion }}
    - mode: {{ phpversiondir.mode|default(555) }}
    - user: {{ phpversiondir.user|default(id) }}
    - group: {{ phpversiondir.group|default(id) }}
    - require:
      - file: setup_site_{{ k }}_{{ phpversion }}_php_fcgi_starter_root

setup_site_{{ k }}_{{ phpversion }}_php_fcgi_starter_script:
  file:
    - managed
    - name: {{ siteroot.path }}{{ fcgistarterroot.path|default('/conf') }}/{{ phpversion }}/php-fcgi-starter
    - source: {{ fcgistarterscript.template_path }}
    - mode: {{ fcgistarterscript.mode|default(550) }}
    - user: {{ fcgistarterscript.user|default(id) }}
    - group: {{ fcgistarterscript.group|default(id) }}
    - template: jinja
    - defaults:
      id: {{ k }}
      suexec: {}
        {% if v.context.phpversions is defined %}
      php:
        version: {{ phpversion }}
        {% endif %}
    - context: {{ v.context|default({}) }}
    - require:
      - file: setup_site_{{ k }}_{{ phpversion }}_php_fcgi_starter_dir
    - watch_in:
      - service: httpd

        {% for configid, configsettings in phpsettings.config|default({})|dictsort %}
setup_site_{{ k }}_{{ phpversion }}_config_{{ configid }}:
  file:
    - managed
    - name: {{ siteroot.path }}{{ fcgistarterroot.path|default('/conf') }}/{{ phpversion }}/php_{{ configid }}.ini
    - source: {{ configsettings.template_path|default('salt://php/files/configs/php.ini') }}
    - user: {{ configsettings.user|default('root') }}
    - group: {{ configsettings.group|default(id) }}
    - mode: {{ configsettings.mode|default(644) }}
    - template: jinja
    - defaults:
      id: {{ configid }}
      veralias: {{ phpversion }}
    - context: {{ configsettings.context|default({}) }}
    - require:
      - file: setup_site_{{ k }}_{{ phpversion }}_php_fcgi_starter_dir
    - watch_in:
      - service: httpd
        {% endfor %}
      {% endfor %}
    {% endif %}
  {% endif %}
{% endfor %}
