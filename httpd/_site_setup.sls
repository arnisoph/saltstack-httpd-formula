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
  {% set siteroot = v.siteroot|default({}) %}
  {% set tmproot = v.tmproot|default() %}
  {% set webroot = v.webroot|default() %}
  {% set docroot = v.docroot|default({}) %}
  {% set logroot = v.logroot|default({}) %}
  {% set privroot = v.privroot|default({}) %}

setup_site_{{ k }}_siteroot:
  file:
  {% if f_fun in ['managed'] %}
    - directory
  {% else %}
    - absent
  {% endif %}
    - name: {{ v.context.siteroot }}
    - mode: {{ siteroot.mode|default(755) }}
    - user: {{ siteroot.user|default('root') }}
    - group: {{ siteroot.group|default('root') }}
    - makedirs: True
    - require:
      - pkg: httpd
    - require_in:
      - service: httpd

  {% if f_fun in ['managed'] %}
setup_site_{{ k }}_logroot:
  file:
    - directory
    - name: {{ v.context.siteroot }}{{ v.context.logroot|default('/logs') }}
    - mode: {{ logroot.mode|default(750) }}
    - user: {{ logroot.user|default('root') }}
    - group: {{ logroot.group|default('root') }}
    - require:
      - file: setup_site_{{ k }}_siteroot

setup_site_{{ k }}_tmproot:
  file:
    - directory
    - name: {{ v.context.siteroot }}{{ v.context.tmproot|default('/tmp') }}
    - mode: {{ tmproot.mode|default(770) }}
    - user: {{ tmproot.user|default('root') }}
    - group: {{ tmproot.group|default('root') }}
    - require:
      - file: setup_site_{{ k }}_siteroot

setup_site_{{ k }}_privroot:
  file:
    - directory
    - name: {{ v.context.siteroot }}{{ v.context.privroot|default('/priv') }}
    - mode: {{ privroot.mode|default(750) }}
    - user: {{ privroot.user|default(id) }}
    - group: {{ privroot.group|default(id) }}
    - require:
      - file: setup_site_{{ k }}_siteroot

setup_site_{{ k }}_webroot:
  file:
    - directory
    - name: {{ v.context.siteroot }}{{ v.context.webroot|default('/htdocs') }}
    - mode: {{ webroot.mode|default(750) }}
    - user: {{ webroot.user|default('root') }}
    - group: {{ webroot.group|default('root') }}
    - require:
      - file: setup_site_{{ k }}_siteroot

setup_site_{{ k }}_docroot:
  file:
    - directory
    - name: {{ v.context.siteroot }}{{ v.context.webroot|default('/htdocs') }}{{ v.context.docroot|default('/webroot') }}
    - mode: {{ docroot.mode|default(755) }}
    - user: {{ docroot.user|default(id) }}
    - group: {{ docroot.group|default(id) }}
    - require:
      - file: setup_site_{{ k }}_webroot

    {% if 'phpversions' in v.context %}
      {% set fcgistarterroot = v.fcgistarterroot|default({}) %}
      {% set suexec = v.context.suexec|default({}) %}
      {% set phpversiondir = v.phpversiondir|default({}) %}
      {% set fcgistarterscript = v.fcgistarterscript|default({}) %}

      {% for phpversion, phpsettings in v.context.phpversions|dictsort if phpsettings.manage|default(False) %}
setup_site_{{ k }}_php_fcgi_starter_{{ phpversion }}_root:
  file:
    - directory
    - name: {{ v.context.siteroot }}{{ v.context.fcgistarterroot|default('/conf') }}
    - mode: {{ fcgistarterroot.mode|default(750) }}
    - user: {{ fcgistarterroot.user|default(id) }}
    - group: {{ fcgistarterroot.group|default(id) }}
    - require:
      - file: setup_site_{{ k }}_siteroot

setup_site_{{ k }}_php_fcgi_starter_{{ phpversion }}_dir:
  file:
    - directory
    - name: {{ v.context.siteroot }}{{ v.context.fcgistarterroot|default('/conf') }}/{{ phpversion }}
    - mode: {{ phpversiondir.mode|default(555) }}
    - user: {{ phpversiondir.user|default(id) }}
    - group: {{ phpversiondir.group|default(id) }}
    - require:
      - file: setup_site_{{ k }}_php_fcgi_starter_{{ phpversion }}_root

setup_site_{{ k }}_php_fcgi_starter_{{ phpversion }}_script:
  file:
    - managed
    - name: {{ v.context.siteroot }}{{ v.context.fcgistarterroot|default('/conf') }}/{{ phpversion }}/php-fcgi-starter
    - source: {{ fcgistarterscript.template_path }}
    - mode: {{ fcgistarterscript.mode|default(750) }}
    - user: {{ fcgistarterscript.user|default(id) }}
    - group: {{ fcgistarterscript.group|default(id) }}
    - template: jinja
    - defaults:
      id: {{ k }}
      suexec: {}
      phpversion: {{ phpversion }}
    - context: {{ v.context|default({}) }}
    - require:
      - file: setup_site_{{ k }}_php_fcgi_starter_{{ phpversion }}_dir
      {% endfor %}
    {% endif %}
  {% endif %}
{% endfor %}
