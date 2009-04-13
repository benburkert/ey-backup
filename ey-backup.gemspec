# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ey-backup}
  s.version = "0.0.3.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ezra Zygmuntowicz"]
  s.autorequire = %q{ey-backup}
  s.date = %q{2009-03-24}
  s.default_executable = %q{eybackup}
  s.description = %q{A gem that provides s3 backups for ey-solo slices...}
  s.email = %q{ezra@engineyard.com}
  s.executables = ["eybackup"]
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/ey-backup", "lib/ey-backup/mysql_backup.rb", "lib/ey-backup/postgresql_backup.rb", "lib/ey-backup.rb", "spec/ey-backup_spec.rb", "spec/spec_helper.rb", "bin/eybackup"]
  s.has_rdoc = true
  s.homepage = %q{http://example.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{A gem that provides s3 backups for ey-solo slices...}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
