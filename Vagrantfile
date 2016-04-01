# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant boxes configuration file for testing.
# Two boxes are defined: one with RVM, the other with rbenv. The provisioning
# scripts set these up ready for deployment with Capistrano. See the vagrant-rvm
# and vagrant-rbenv stages defined in config/deploy.

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  # config.vm.box_check_update = false

  # Configure each of the boxes with the same name and forwarded port
  # This means that only one can be active at a given time; this is on purpose
  config.vm.hostname = "resourcemap.local"
  config.vm.network "forwarded_port", guest: 80, host: 8080

  def provision(c, system = :rvm)
    c.vm.provision :shell, path: 'config/vagrant/install-deps.sh'

    case system
    when :rvm
      c.vm.provision :shell, path: 'config/vagrant/install-rvm.sh', args: 'stable'
      c.vm.provision :shell, path: 'config/vagrant/install-ruby-rvm.sh', args: ["#{`cat .ruby-version`}", "bundler"]
    when :rbenv
      c.vm.provision :shell, path: 'config/vagrant/install-rbenv.sh', args: 'stable'
      c.vm.provision :shell, path: 'config/vagrant/install-ruby-rbenv.sh', args: ["#{`cat .ruby-version`}", "bundler"]
    else
      raise RuntimeError, "Unknown Ruby version management system"
    end

    c.vm.provision :shell, path: 'config/vagrant/install-passenger.sh'

    # Copy Apache2 site (needed by install-post.sh)
    c.vm.provision :file, source: "config/vagrant/resource_map.apache2.conf", destination: "~/resource_map.conf"

    # Finish configuration
    c.vm.provision :shell, path: 'config/vagrant/install-post.sh'

    # Provision default configuration files
    %w(database.yml
       settings.yml
       newrelic.yml
       google_maps.key
       guisso.yml
       nuntium.yml
       poirot.yml
       secrets.yml
       telemetry.yml).each do |file|
      c.vm.provision :file, source: "config/vagrant/#{file}", destination: "/u/apps/resource_map/shared/config/#{file}"
    end
  end

  config.vm.define "with-rvm" do |c|
    provision c, :rvm
  end

  config.vm.define "with-rbenv" do |c|
    provision c, :rbenv
  end

  config.vm.provider "virtualbox" do |v|
    # Running Elasticsearch and Passenger requires at least 2Gb of RAM
    v.memory = 2048
    v.cpus = 2
  end
end
