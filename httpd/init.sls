{% from "httpd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('httpd:lookup')) %}

httpd:
  pkg:
    - installed
    - pkgs:
{% for p in datamap.pkgs %}
      - {{ p }}
{% endfor %}
  service:
    - {{ datamap.service.state|default('running') }}
    - name: {{ datamap.service.name }}
    - enable: {{ datamap.service.enable|default(True) }}
    - watch:
      - pkg: httpd #TODO remove
{% for k, v in salt['pillar.get']('httpd:vhosts').items() %}
      - file: vhost_{{ k }}
      - cmd: manage_site_{{ k }}
{% endfor %}



{% for k, v in datamap.mods.modules.items() %}
  {% if v.manage|default(False) %}

    {% if v.pkgs|length > 0 %}
manage_modpkg_{{ k }}:
  pkg:
    - installed
    - pkgs:
{% for p in v.pkgs %}
      - {{ p }}
{% endfor %}
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

{% for k, v in salt['pillar.get']('httpd:vhosts').items() %}
  {% if v.ensure is not defined or v.ensure in ['managed'] %}
    {% set f_fun = 'managed' %}
  {% elif v.ensure in ['absent'] %}
    {% set f_fun = 'absent' %}
  {% endif %}

  {% set v_name = v.name|default(k) %}

manage_site_{{ k }}:
  cmd:
    - run
    {% if f_fun in ['managed'] %}
    - name: {{ datamap.a2ensite.path}} {{ v_name }}
    {% else %}
    - name: {{ datamap.a2dissite.path}} {{ v_name }}
    {% endif %}
    {% if f_fun in ['managed'] %}
    - unless: test -L /etc/apache2/sites-enabled/{{ v.linkname|default(v_name) }}
    {% else %}
    - onlyif: test -L /etc/apache2/sites-enabled/{{ v.linkname|default(v_name) }}
    {% endif %}

vhost_{{ k }}:
  file:
    - {{ f_fun }}
    - name: {{ v.path|default(datamap.vhosts.dir ~ '/' ~ datamap.vhosts.name_prefix|default('') ~ v_name ~ datamap.vhosts.name_suffix|default('')) }}
    - user: root
    - group: root
    - mode: 600
    - contents_pillar: httpd:vhosts:{{ v_name }}:plain

{% endfor %}
