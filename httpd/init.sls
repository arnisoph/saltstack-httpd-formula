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
    - require:
      - pkg: httpd
