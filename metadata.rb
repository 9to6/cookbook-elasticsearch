name             "elasticsearch2"

maintainer       "karmi"
maintainer_email "karmi@karmi.cz"
license          "Apache"
description      "Installs and configures elasticsearch2"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.markdown'))
version          "0.3.13"

depends 'ark', '~> 0.2.4'

suggests 'build-essential'
suggests 'xml'
suggests 'java'
suggests 'monit'

provides 'elasticsearch2'
provides 'elasticsearch2::data'
provides 'elasticsearch2::ebs'
provides 'elasticsearch2::aws'
provides 'elasticsearch2::gce'
provides 'elasticsearch2::nginx'
provides 'elasticsearch2::proxy'
provides 'elasticsearch2::plugins'
provides 'elasticsearch2::monit'
provides 'elasticsearch2::search_discovery'
