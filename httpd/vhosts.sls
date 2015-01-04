#!jinja|yaml

{% from "httpd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('httpd:lookup')) %}

{% for k, v in salt['pillar.get']('httpd:vhosts', {})|dictsort %}
  {% if v.ensure|default('managed') in ['managed', 'disabled'] %}
    {% set f_fun = 'managed' %}
  {% elif v.ensure|default('managed') in ['absent'] %}
    {% set f_fun = 'absent' %}
  {% endif %}

  {% set id = v.name|default(k) %}
  {% set vhost_context = v.context|default({}) %}
  {% set siteroot = vhost_context.siteroot|default({'path': '/var/www/' ~ id}) %}

vhost_{{ k }}:
  file:
    - {{ f_fun }}
    - name: {{ v.path|default(datamap.vhosts.dir ~ '/' ~ datamap.vhosts.name_prefix|default('') ~ id ~ datamap.vhosts.name_suffix|default('')) }}
  {% if 'template_path' in v %}
    - source: {{ v.template_path }}
    - template: jinja
    - defaults:
      id: {{ k }}
    - context:
      context_pillar: httpd:vhosts:{{ id }}:context
  {% else %}
    - contents_pillar: httpd:vhosts:{{ id }}:contents
  {% endif %}
    - user: root
    - group: root
    - mode: 600
    - watch_in:
      - service: httpd

  {% if 'path' in siteroot %}
setup_site_{{ k }}_siteroot:
  file:
  {% if f_fun in ['managed'] %}
    - directory
  {% else %}
    - absent
  {% endif %}
    - name: {{ siteroot.path }}
    - mode: {{ siteroot.mode|default(755) }}
    - user: {{ siteroot.user|default('root') }}
    - group: {{ siteroot.group|default('root') }}
    - makedirs: True
    - require:
      - pkg: httpd
    - require_in:
      - service: httpd

manage_site_{{ k }}:
  cmd:
    - run
    {% if f_fun in ['managed'] %}
    - name: {{ datamap.a2ensite.path}} {{ id }}
    - unless: test -L /etc/apache2/sites-enabled/{{ v.linkname|default(id) }}
    {% else %}
    - name: {{ datamap.a2dissite.path}} {{ id }}
    - onlyif: test -L /etc/apache2/sites-enabled/{{ v.linkname|default(id) }}
    {% endif %}
    - require:
      - file: vhost_{{ k }}
    - watch_in:
      - service: httpd
  {% endif %}
{% endfor %}
