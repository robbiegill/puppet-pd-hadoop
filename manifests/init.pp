# enable remote login in mac sharing prefs
# ssh-keygen -t rsa
# add ~/.ssh/id_rsa.pub to ~/.ssh/authorized_keys
# cd /hadoop-pd/hadoop-0.20.2/bin && sh start-all.sh

class puppet-pd-hadoop {

  $user_name = "${::boxen_user}"

  file { "/hadoop-pd":
    ensure => "directory",
    owner  => "${user_name}",
    group  => "staff",
    mode   => 750,
    alias  => 'hadoop-pd-dir'
  }

  file { "/hadoop-pd/data":
    ensure => "directory",
    owner  => "${user_name}",
    group  => "staff",
    mode   => 750,
    alias  => 'hadoop-pd-data-dir',
    require => File['hadoop-pd-dir']
  }

  file { "/hadoop-pd/data/hadoop":
    ensure => "directory",
    owner  => "${user_name}",
    group  => "staff",
    mode   => 750,
    alias  => 'hadoop-pd-hadoop-dir',
    require => File['hadoop-pd-data-dir']
  }

  file {"/hadoop-pd/hadoop-0.20.2.tar.gz": 
    ensure  => "present",
    source => "puppet:///modules/puppet-pd-hadoop/hadoop-0.20.2.tar.gz",
    owner  => "${user_name}",
    group  => "staff",
    mode   => 750,
    alias  => 'hadoop-tar-file',
    require => File['hadoop-pd-dir'],
    before => Exec['untar-hadoop']
  }

  exec { "untar hadoop": 
    creates => "/hadoop-pd/hadoop-0.20.2",
    alias   => "untar-hadoop",
    command => "tar -zxf hadoop-0.20.2.tar.gz",
    cwd     => "/hadoop-pd",
    refreshonly => "true",
    user    => "${user_name}",
    subscribe => File['hadoop-tar-file']
  }

	file { "/hadoop-pd/data/hadoop/namedir":
    ensure => "directory",
    owner  => "${user_name}",
    group  => "staff",
    mode   => 750,
    alias  => 'namedir',
    require => File['hadoop-pd-hadoop-dir']
  }

  file { "/hadoop-pd/data/hadoop/datadir":
    ensure => "directory",
    owner  => "${user_name}",
    group  => "staff",
    mode   => 750,
    alias  => 'datadir',
    require => File['hadoop-pd-hadoop-dir']
  }

  file { "/hadoop-pd/hadoop-0.20.2/conf/hdfs-site.xml":
    owner  => "${user_name}",
    group  => "staff",
    mode   => 644,
    alias => "hdfs-site-xml",
    content => template("puppet-pd-hadoop/hdfs-site.xml.erb"),
    require => Exec['untar-hadoop']
  }

  file { "/hadoop-pd/hadoop-0.20.2/conf/core-site.xml":
    owner  => "${user_name}",
    group  => "staff",
    mode   => 644,
    alias => "core-site-xml",
    content => template("puppet-pd-hadoop/core-site.xml.erb"),
    require => Exec['untar-hadoop']
  }

  file { "/hadoop-pd/hadoop-0.20.2/conf/hadoop-env.sh":
    owner  => "${user_name}",
    group  => "staff",
    mode   => 644,
    alias => "hadoop-env-sh",
    content => template("puppet-pd-hadoop/hadoop-env.sh.erb"),
    require => Exec['untar-hadoop']
  }

  file { "/hadoop-pd/hadoop-0.20.2/conf/mapred-site.xml":
    owner  => "${user_name}",
    group  => "staff",
    mode   => 644,
    alias => "mapred-site-xml",
    content => template("puppet-pd-hadoop/mapred-site.xml.erb"),
    require => Exec['untar-hadoop']
  }

  exec { "format the name node":
    command    => "/hadoop-pd/hadoop-0.20.2/bin/hadoop namenode -format",
    cwd        => "/hadoop-pd/hadoop-0.20.2/bin",
    path       => "/bin:/usr/bin:/usr/local/bin",
    user       => "${user_name}",
    alias      => "format-hdfs",
    subscribe  => Exec['untar-hadoop'],
    refreshonly  => true,
    require    => File['hdfs-site-xml','core-site-xml','hadoop-env-sh','mapred-site-xml']
  }

  notify { "generate ssh keys":
    message  => "!!! ------- remember to configure passwordless ssh ---------- !!!",
    subscribe => Exec["format-hdfs"]
  }
}
