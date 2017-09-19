{%- from 'atlassianapps/map.jinja' import atlassianapps with context %}
{%- set app_name = 'confluence' %}

include:
  - atlassianapps

confluence:
  group:
    - present
  user.present:
    - fullname: Confluence user
    - shell: /bin/sh
    - home: {{ atlassianapps.prefix }}/confluence-home
    - groups:
       - confluence

### APPLICATION INSTALL ###
unpack-confluence-tarball:
  archive.extracted:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}
    - source: {{ atlassianapps.source_url }}/confluence/downloads/atlassian-confluence-{{ atlassianapps.version }}.tar.gz
    - archive_format: tar
    - skip_verify: True
    - user: confluence
    - options: z
    - if_missing: {{ atlassianapps.prefix }}/{{ app_name }}/atlassian-confluence-{{ atlassianapps.version }}
    - keep: True
    - force: True
    - require:
      - module: confluence-stop
      - file: confluence-init-script
    - listen_in:
      - module: confluence-restart

create-confluence-symlink:
  file.symlink:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/confluence
    - target: {{ atlassianapps.prefix }}/{{ app_name }}/atlassian-confluence-{{ atlassianapps.version }}
    - user: confluence
    - watch:
      - archive: unpack-confluence-tarball

confluence-create-logs-symlink:
  file.symlink:
    - name: {{ atlassianapps.log_root }}
    - target: {{ atlassianapps.prefix }}/{{ app_name }}/confluence/logs
    - user: confluence
    - backupname: {{ atlassianapps.prefix }}/{{ app_name }}/confluence/old_logs
    - watch:
      - archive: unpack-confluence-tarball

fix-confluence-filesystem-permissions:
  file.directory:
    - user: confluence
    - group: confluence
    - recurse:
      - user
      - group
    - names:
      - {{ atlassianapps.prefix }}/{{ app_name }}-home
      - {{ atlassianapps.prefix }}/{{ app_name }}/
    - watch:
      - archive: unpack-confluence-tarball

confluence-systemd-system-dir:
  file.directory:
    - name: /usr/lib/systemd/system
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

confluence-init-script:
  file.managed:
    - name: '/usr/lib/systemd/system/confluence.service'
    - source: salt://atlassianapps/templates/atlassianapps.systemd.tmpl
    - user: root
    - group: root
    - mode: 0755
    - require:
      - file: confluence-systemd-system-dir
    - template: jinja
    - context:
      atlassianapps: {{ atlassianapps|json }}
      app_name: {{ app_name }}
      app_root_name: confluence
      atlassianapps_home: CONFLUENCE_HOME

confluence-properties-file:
  file.managed:
    - name: '{{ atlassianapps.prefix }}/{{ app_name }}/confluence/confluence/WEB-INF/classes/confluence-init.properties'
    - source: salt://atlassianapps/templates/atlassianapps-application.properties.tmpl
    - user: confluence
    - group: confluence
    - mode: 0755
    - template: jinja
    - context:
      atlassianapps: {{ atlassianapps|json }}
      app_name: {{ app_name }}

confluence-service:
  service.running:
    - name: confluence
    - enable: True
    - require:
      - archive: unpack-confluence-tarball
      - file: confluence-init-script
    - watch:
      - /usr/lib/systemd/system/confluence.service
      - {{ atlassianapps.prefix }}/{{ app_name }}/confluence/confluence/WEB-INF/classes/confluence-init.properties

{% if atlassianapps.use_https == True %}
confluence-https-replace:
  file.replace:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/confluence/conf/server.xml
    - pattern:  '\<Connector port=\"8090"[^\n]* connectionTimeout="20000"'
    - repl: '<Connector port="8090" proxyName="{{ atlassianapps.public_url }}" proxyPort="443" scheme="https" connectionTimeout="20000"'
    - backup: False
{% endif %}

confluence-jvm-min-memory:
  file.replace:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/confluence/bin/setenv.sh
    - pattern:  'JVM_MINIMUM_MEMORY="[^"]*"'
    - repl: 'JVM_MINIMUM_MEMORY="{{ atlassianapps.jvm_Xms }}"'
    - backup: False
    - listen_in:
      - module: confluence-restart

confluence-jvm-max-memory:
  file.replace:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/confluence/bin/setenv.sh
    - pattern:  'JVM_MAXIMUM_MEMORY="[^"]*"'
    - repl: 'JVM_MAXIMUM_MEMORY="{{ atlassianapps.jvm_Xmx }}"'
    - backup: False
    - listen_in:
      - module: confluence-restart

confluence-restart:
  module.wait:
    - name: service.restart
    - m_name: confluence

confluence-stop:
  module.wait:
    - name: service.stop
    - m_name: confluence
