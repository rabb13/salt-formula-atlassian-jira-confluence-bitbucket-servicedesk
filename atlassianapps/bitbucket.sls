{%- from 'atlassianapps/map.jinja' import atlassianapps with context %}
{%- set app_name = 'bitbucket' %}

include:
  - atlassianapps

bitbucket:
  group:
    - present
  user.present:
    - fullname: bitbucket user
    - shell: /bin/sh
    - home: {{ atlassianapps.prefix }}/bitbucket-home
    - groups:
       - bitbucket

### APPLICATION INSTALL ###
unpack-bitbucket-tarball:
  archive.extracted:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}
    - source: {{ atlassianapps.source_url }}/stash/downloads/atlassian-bitbucket-{{ atlassianapps.version }}.tar.gz
    - archive_format: tar
    - skip_verify: True
    - user: bitbucket
    - options: z
    - if_missing: {{ atlassianapps.prefix }}/{{ app_name }}/atlassian-bitbucket-{{ atlassianapps.version }}
    - keep: True
    - force: true
    - require:
      - module: bitbucket-stop
      - file: bitbucket-init-script
    - listen_in:
      - module: bitbucket-restart

create-bitbucket-symlink:
  file.symlink:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/bitbucket
    - target: {{ atlassianapps.prefix }}/{{ app_name }}/atlassian-bitbucket-{{ atlassianapps.version }}
    - user: bitbucket
    - watch:
      - archive: unpack-bitbucket-tarball

bitbucket-create-logs-symlink:
  file.symlink:
    - name: {{ atlassianapps.log_root }}
    - target: {{ atlassianapps.prefix }}/{{ app_name }}-home/log
    - user: bitbucket
    - backupname: {{ atlassianapps.prefix }}/{{ app_name }}-home/bitbucket/old_logs
    - watch:
      - archive: unpack-bitbucket-tarball

fix-bitbucket-filesystem-permissions:
  file.directory:
    - user: bitbucket
    - group: bitbucket
    - recurse:
      - user
      - group
    - names:
      - {{ atlassianapps.prefix }}/{{ app_name }}-home
      - {{ atlassianapps.prefix }}/{{ app_name }}
      - {{ atlassianapps.log_root }}
    - watch:
      - archive: unpack-bitbucket-tarball

bitbucket-systemd-system-dir:
  file.directory:
    - name: /usr/lib/systemd/system
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

bitbucket-init-script:
  file.managed:
    - name: '/usr/lib/systemd/system/bitbucket.service'
    - source: salt://atlassianapps/templates/atlassianapps.systemd.tmpl
    - user: root
    - group: root
    - mode: 0755
    - require:
      - file: bitbucket-systemd-system-dir
    - template: jinja
    - context:
      atlassianapps: {{ atlassianapps|json }}
      app_name: {{ app_name }}
      app_root_name: bitbucket
      atlassianapps_home: bitbucket_HOME

bitbucket-properties-file:
  file.managed:
    - name: '{{ atlassianapps.prefix }}/bitbucket-home/shared/bitbucket.properties'
    - source: salt://atlassianapps/templates/bitbucket.properties.tmpl
    - user: bitbucket
    - group: bitbucket
    - mode: 0644
    - template: jinja
    - makedir: True
    - context:
      atlassianapps: {{ atlassianapps|json }}
      app_name: {{ app_name }}


bitbucket-service:
  service.running:
    - name: bitbucket
    - enable: True
    - require:
      - archive: unpack-bitbucket-tarball
      - file: bitbucket-init-script
    - watch:
      - /usr/lib/systemd/system/bitbucket.service
      - {{ atlassianapps.prefix }}/bitbucket-home/shared/bitbucket.properties

bitbucket-set-home:
  file.replace:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/bitbucket/bin/set-bitbucket-home.sh
    - pattern:  'BITBUCKET_HOME=[^\n]*'
    - repl: 'BITBUCKET_HOME={{ atlassianapps.prefix }}/{{ app_name }}-home'
    - backup: False

bitbucket-jvm-min-memory:
  file.replace:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/bitbucket/bin/_start-webapp.sh
    - pattern:  'JVM_MINIMUM_MEMORY="[^"]*"'
    - repl: 'JVM_MINIMUM_MEMORY="{{ atlassianapps.jvm_Xms }}"'
    - backup: False
    - listen_in:
      - module: bitbucket-restart

bitbucket-jvm-max-memory:
  file.replace:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/bitbucket/bin/_start-webapp.sh
    - pattern:  'JVM_MAXIMUM_MEMORY="[^"]*"'
    - repl: 'JVM_MAXIMUM_MEMORY="{{ atlassianapps.jvm_Xmx }}"'
    - backup: False
    - listen_in:
      - module: bitbucket-restart

bitbucket-restart:
  module.wait:
    - name: service.restart
    - m_name: bitbucket

bitbucket-stop:
  module.wait:
    - name: service.stop
    - m_name: bitbucket
