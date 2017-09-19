
Atlassian-Apps
===============
Jira | Jira ServiceDesk | Confluence | Bitbucket formula
===============

This formula is for installing any of the application below-
* Jira
* Jira Servicedesk
* Confluence
* Bitbucket

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================


``atlassianapps``
-----------------

It only installs dependent packages. include one below

``atlassianapps.jira``
------------------------

Installs Jira 

``atlassianapps.jiraservicedesk``
------------------------

Installs Jira servicedesk

``atlassianapps.confluence``
------------------------

Installs Confluence

``atlassianapps.bitbucket``
------------------------

Installs bitbucket

``atlassianapps.dbdriver``
------------------------


Example Pillar
==============
See [pilar.example](pillar.example)

Notes
=============
Postgres is used as default database, Can be switched to MySQL Easily, Check Map


Upgrade/Downgrade
=================
Simply change the version number and apply state, Datat unaffected


Dependencies
================
oracle-java (or any variant)
postgresql (9.4+)
postfix (if you have a mail relay locally)

