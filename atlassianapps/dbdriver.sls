{%- from 'atlassianapps/map.jinja' import atlassianapps with context %}

atlassianapps-unpack-mysql-tarball:
  archive.extracted:
    - name: /tmp/
    - source: {{ atlassianapps.mysql_location }}/mysql-connector-java-{{ atlassianapps.mysql_connector_version }}.tar.gz
    - skip_verify: true
    - archive_format: tar
    - user: bitbucket
    - options: z
    - if_missing: {{ atlassianapps.prefix }}/{{ app_name }}/bitbucket/lib/mysql-connector-java-{{ atlassianapps.mysql_connector_version }}-bin.jar
    - keep: True

mysql-jar-copy:
  file.copy:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/bitbucket/lib/mysql-connector-java-{{ atlassianapps.mysql_connector_version }}-bin.jar
    - source: /tmp/mysql-connector-java-5.1.40/mysql-connector-java-{{ atlassianapps.mysql_connector_version }}-bin.jar
    - user: bitbucket
    - require:
      - module: bitbucket-stop
      - file: bitbucket-init-script
    - listen_in:
      - module: bitbucket-restart
    - unless:
      - ls {{ atlassianapps.prefix }}/{{ app_name }}/bitbucket/lib/mysql-connector-java-{{ atlassianapps.mysql_connector_version }}-bin.jar

postgres-jar-download:
  file.copy:
    - name: {{ atlassianapps.prefix }}/{{ app_name }}/bitbucket/lib/postgresql-{{ atlassianapps.mysql_connector_version }}.jar
    - source: {{ atlassianapps.postgres_location }}/postgresql-{{ atlassianapps.postgres_connector_version }}.jar
    - user: bitbucket
    - require:
      - module: bitbucket-stop
      - file: bitbucket-init-script
    - listen_in:
      - module: bitbucket-restart
    - unless:
      - ls {{ atlassianapps.prefix }}/{{ app_name }}/bitbucket/lib/postgresql-{{ atlassianapps.mysql_connector_version }}.jar
