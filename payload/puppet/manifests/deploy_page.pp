# deploy index.html

file {'homePage':
  path    => '/usr/share/nginx/www/index.html',
  ensure  => present,
  owner   => root,
  group   => root,
  mode    => 0644,
  source  => '/vagrant/payload/puppet/files/index.html',
}
