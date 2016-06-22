# Taken from puppet-access acceptance tests (blame RE-1990)
# Taken from puppet acceptance lib
# Install development repos
def install_dev_repos_on(package, host, sha, repo_configs_dir)
  platform = host['platform'] =~ /^(debian|ubuntu)/ ? host['platform'].with_version_codename : host['platform']
  platform_configs_dir = File.join(repo_configs_dir, platform)

  case platform
  when /^(fedora|el|centos)-(\d+)-(.+)$/
    variant = (($1 == 'centos') ? 'el' : $1)
    fedora_prefix = ((variant == 'fedora') ? 'f' : '')
    version = $2
    arch = $3

    #hack for https://tickets.puppetlabs.com/browse/RE-1990
    pattern = "pl-%s-%s-%s-%s%s-%s.repo"

    repo_filename = pattern % [
      package,
      sha,
      variant,
      fedora_prefix,
      version,
      arch
    ]

    repo = fetch(
      "http://builds.puppetlabs.lan/%s/%s/repo_configs/rpm/" % [package, sha],
      repo_filename,
      platform_configs_dir
    )

    scp_to(host, repo, '/etc/yum.repos.d/')

  when /^(debian|ubuntu)-([^-]+)-(.+)$/
    variant = $1
    version = $2
    arch = $3

    list = fetch(
      "http://builds.puppetlabs.lan/%s/%s/repo_configs/deb/" % [package, sha],
      "pl-%s-%s-%s.list" % [package, sha, version],
      platform_configs_dir
    )

    scp_to host, list, '/etc/apt/sources.list.d'
    on host, 'apt-get update'
  else
    host.logger.notify("No repository installation step for #{platform} yet...")
  end
end

install_opts = options.merge( { :dev_builds_repos => ["PC1"] })
repo_config_dir = 'tmp/repo_configs'

step "Install Puppet Enterprise." do
  install_pe
end

step "Setup pe-client-tools repositories." do
  install_dev_repos_on('pe-client-tools',
                       master,
                       ENV['SHA'],
                       repo_config_dir)
end

step "Install pe-client-tools." do
  host = master
  install_package(host, 'pe-client-tools')
  on(host, "/opt/puppetlabs/bin/puppet-query --help")
  on(host, "/opt/puppetlabs/bin/puppet-query 'nodes{}'")
end
