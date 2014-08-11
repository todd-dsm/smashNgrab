# Create nginx repo

file { 'nginxrepo':
  path    => '/etc/yum.repos.d/nginx.repo',
  ensure  => present,
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => "[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=1\n"
}
