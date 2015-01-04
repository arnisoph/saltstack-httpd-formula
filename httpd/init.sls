#!jinja|yaml

{% from "httpd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('httpd:lookup')) %}

include: {{ datamap.sls_include|default(['httpd.setup', 'httpd.vhosts', 'httpd._site_setup']) }}
extend: {{ datamap.sls_extend|default({}) }}
