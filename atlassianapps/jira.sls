{%- from 'atlassianapps/map.jinja' import atlassianapps with context %}
{%- set app_name = 'jira' %}

include:
  - atlassianapps

jira:
  group:
    - present
  user.present:
    - fullname: Jira user for Servicedesk
    - shell: /bin/sh
    - home: {{ atlassianapps.prefix }}/jira-home
    - groups:
       - jira

### APPLICATION INSTALL ###
unpack-jira-tarball:
  archive.extracted:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}
    - source: {{ atlassianapps.source_url }}/jira/downloads/atlassian-jira-software-{{ atlassianapps.version }}.tar.gz
    - archive_format: tar
    - skip_verify: True
    - user: jira
    - options: z
    - if_missing: {{ atlassianapps.prefix }}/{{ app_name }}/jira/atlassian-jira-software-{{ atlassianapps.version }}-standalone
    - keep: True
    - require:
      - module: jira-stop
      - file: jira-init-script
    - listen_in:
      - module: jira-restart

create-jira-symlink:
  file.symlink:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/jira
    - target: {{ atlassianapps.prefix }}/{{ app_name }}/atlassian-jira-software-{{ atlassianapps.version }}-standalone
    - user: jira
    - watch:
      - archive: unpack-jira-tarball

jira-create-logs-symlink:
  file.symlink:
    - name: {{ atlassianapps.log_root }}
    - target: {{ atlassianapps.prefix }}/{{ app_name }}/jira/logs
    - user: jira
    - backupname: {{ atlassianapps.prefix }}/{{ app_name }}/jira/old_logs
    - watch:
      - archive: unpack-jira-tarball

fix-jira-filesystem-permissions:
  file.directory:
    - user: jira
    - group: jira
    - recurse:
      - user
      - group
    - names:
      - {{ atlassianapps.prefix }}/jira-home
      - {{ atlassianapps.prefix }}/{{ app_name }}
    - watch:
      - archive: unpack-jira-tarball

jira-systemd-system-dir:
  file.directory:
    - name: /usr/lib/systemd/system
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

jira-init-script:
  file.managed:
    - name: '/usr/lib/systemd/system/jira.service'
    - source: salt://atlassianapps/templates/atlassianapps.systemd.tmpl
    - user: root
    - group: root
    - mode: 0755
    - require:
      - file: jira-systemd-system-dir
    - template: jinja
    - context:
      atlassianapps: {{ atlassianapps|json }}
      app_name: {{ app_name }}
      app_root_name: {{ app_name }}
      atlassianapps_home: JIRA_HOME

jira-properties-file:
  file.managed:
    - name: '{{ atlassianapps.prefix }}/{{ app_name }}/jira/atlassian-jira/WEB-INF/classes/jira-application.properties'
    - source: salt://atlassianapps/templates/atlassianapps-application.properties.tmpl
    - user: jira
    - group: jira
    - mode: 0755
    - template: jinja
    - context:
      atlassianapps: {{ atlassianapps|json }}
      app_name: jira

{{ atlassianapps.prefix }}/jira-home/dbconfig.xml:
  file.managed:
    - source: salt://atlassianapps/templates/dbconfig.xml.tmpl
    - user: jira
    - group: jira
    - template: jinja
    - listen_in:
      - module: jira-restart
    - context:
      atlassianapps: {{ atlassianapps|json }}

jira-service:
  service.running:
    - name: jira
    - enable: True
    - require:
      - archive: unpack-jira-tarball
      - file: jira-init-script
    - watch:
      - /usr/lib/systemd/system/jira.service
      - {{ atlassianapps.prefix }}/{{ app_name }}/jira/atlassian-jira/WEB-INF/classes/jira-application.properties

{% if atlassianapps.use_https == True %}
jira-https-replace:
  file.replace:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/jira/conf/server.xml
    - pattern:  '\<Connector port=\"8080\"[^\n]*'
    - repl: '<Connector port="8080" proxyName="{{ atlassianapps.public_url }}" proxyPort="443" scheme="https"'
    - backup: False
{% endif %}

jira-jvm-min-memory:
  file.replace:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/jira/bin/setenv.sh
    - pattern:  'JVM_MINIMUM_MEMORY="[^"]*"'
    - repl: 'JVM_MINIMUM_MEMORY="{{ atlassianapps.jvm_Xms }}"'
    - backup: False
    - listen_in:
      - module: jira-restart

jira-jvm-max-memory:
  file.replace:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/jira/bin/setenv.sh
    - pattern:  'JVM_MAXIMUM_MEMORY="[^"]*"'
    - repl: 'JVM_MAXIMUM_MEMORY="{{ atlassianapps.jvm_Xmx }}"'
    - backup: False
    - listen_in:
      - module: jira-restart

jira-restart:
  module.wait:
    - name: service.restart
    - m_name: jira

jira-stop:
  module.wait:
    - name: service.stop
    - m_name: jira
