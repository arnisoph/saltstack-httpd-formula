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
{% for k, v in datamap.modules.items() %}
  {% if v.manage|default(False) %}
      - cmd: manage_mod_{{ k }}
  {% endif %}
{% endfor %}


{% for k, v in datamap.modules.items() %}
  {% if v.manage|default(False) %}

    {% if v.pkgs|length > 0 %}
manage_modpkg_{{ k }}:
  pkg:
    - installed
    - pkgs:
{% for p in v.pkgs %}
      - {{ p }}
{% endfor %}
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
    - unless: test -e /etc/apache2/mods-enabled/{{ v.name|default(k) }}.load
    {% else %}
    - onlyif: test -e /etc/apache2/mods-enabled/{{ v.name|default(k) }}.load
    {% endif %}
  {% endif %}
{% endfor %}
