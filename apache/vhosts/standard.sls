{% from "apache/map.jinja" import apache with context %}

include:
  - apache

{% for id, site in salt['pillar.get']('apache:sites', {}).items() %}
{% set documentroot = site.get('DocumentRoot', '{0}/{1}'.format(apache.wwwdir, site.get('ServerName', id))) %}

apache_vhosts_{{ id }}:
  file.managed:
    - name: {{ apache.vhostdir }}/{{ id }}{{ apache.confext }}
    - source: {{ site.get('template_file', 'salt://apache/vhosts/standard.tmpl') }}
    - template: {{ site.get('template_engine', 'jinja') }}
    - context:
        id: {{ id|json }}
        site: {{ site|json }}
        map: {{ apache|json }}
    - require:
      - pkg: apache
    - watch_in:
      - module: apache-reload

{% if site.get('DocumentRoot') != False %}
{{ id }}-documentroot:
  file.directory:
    - name: {{ documentroot }}
    - makedirs: True
    - user: {{ site.get('DocumentRootUser', apache.get('document_root_user'))|json }}
    - group: {{ site.get('DocumentRootGroup', apache.get('document_root_group'))|json }}
    - allow_symlink: True
{% endif %}
{{ id }}-documentlog:
  file.directory:
    - name: {{ apache.vhostdir }}/{{ id }}/logs
    - makedirs: True
    - user: {{ site.get('DocumentRootUser', apache.get('document_root_user'))|json }}
    - group: {{ site.get('DocumentRootGroup', apache.get('document_root_group'))|json }}
    - allow_symlink: True

{% if grains.os_family == 'Debian' %}
{% if site.get('enabled', True) %}
a2ensite {{ id }}{{ apache.confext }}:
  cmd.run:
    - unless: test -f /etc/apache2/sites-enabled/{{ id }}{{ apache.confext }}
    - require:
      - file: /etc/apache2/sites-available/{{ id }}{{ apache.confext }}
    - watch_in:
      - module: apache-reload
{% else %}
a2dissite {{ id }}{{ apache.confext }}:
  cmd.run:
    - onlyif: test -f /etc/apache2/sites-enabled/{{ id }}{{ apache.confext }}
    - require:
      - file: /etc/apache2/sites-available/{{ id }}{{ apache.confext }}
    - watch_in:
      - module: apache-reload
{% endif %}
{% endif %}

{% endfor %}
