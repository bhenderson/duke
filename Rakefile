# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :isolate
Hoe.plugin :minitest

Hoe.spec 'duke' do
  developer 'Brian Henderson', 'bhenderson@attinteractive.com'

  extra_deps << ['rack', '~> 1.4.1']
  extra_deps << ['rack-routes', '~> 0.2']
  extra_dev_deps << ['minitest', '~> 2.11.3']
  extra_dev_deps << ['rack-test']

  self.readme_file      = "README.rdoc"
  self.testlib          = :minitest
end

# vim: syntax=ruby
