#!jinja|yaml

{% from "httpd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('httpd:lookup')) %}

httpd:
  pkg:
    - installed
    - pkgs: {{ datamap.pkgs }}
  service:
    - {{ datamap.service.state|default('running') }}
    - name: {{ datamap.service.name }}
    - enable: {{ datamap.service.enable|default(True) }}

{% for f in datamap.config.manage|default([]) %}
  {% set c = datamap.config[f]|default({}) %}
httpd_config_{{ f }}:
  file:
    - {{ c.ensure|default('managed') }}
    - name: {{ c.path }}
    - source: {{ c.template_path|default('salt://httpd/files/' ~ f) }}
    - user: {{ c.user|default('root') }}
    - group: {{ c.group|default('root') }}
    - mode: {{ c.mode|default(640) }}
    - template: jinja
    - watch_in:
      - service: httpd
{% endfor %}

{% for k, v in datamap.mods.modules|dictsort %}
  {% if v.manage|default(False) %}

    {% if 'pkgs' in v %}
manage_modpkg_{{ k }}:
  pkg:
    - installed
    - pkgs: {{ v.pkgs }}
    - require_in:
      - cmd: manage_mod_{{ k }}
    {% endif %}

manage_mod_{{ k }}:
  cmd:
    - run
    {% if v.enable|default(True) %}
    - name: {{ datamap.a2enmod.path}} {{ v.name|default(k) }}
    {% else %}
    - name: {{ datamap.a2dismod.path}} {{ v.name|default(k) }}
    {% endif %}
    {% if v.enable|default(True) %}
    - unless: test -L /etc/apache2/mods-enabled/{{ v.name|default(k) }}.load
    {% else %}
    - onlyif: test -L /etc/apache2/mods-enabled/{{ v.name|default(k) }}.load
    {% endif %}
    - watch_in:
      - service: httpd

    {% if v.config is defined %}
modconfig_{{ k }}:
  file:
    - managed
    - name: {{ datamap.mods.dir }}/{{ k }}.conf
    - source: salt://httpd/files/modconfig
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        alias: {{ k }}
    - watch_in:
      - service: httpd
    {% endif %}

  {% endif %}
{% endfor %}

{% for f in datamap.default_documents|default([]) %}
default_doc_{{ f }}:
  file:
    - absent
    - name: {{ f }}
{% endfor %}

{% for f in salt['pillar.get']('httpd:configs_absent', []) %}
configfile_absent_{{ f }}:
  file:
    - absent
    - name: {{ f }}
    - watch_in:
      - service: httpd
{% endfor %}
