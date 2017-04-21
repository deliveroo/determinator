require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'semantic'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :version do
  desc "Bumps the minor version of the gem, saving to the version file"
  task :bump do
    version = Semantic::Version.new(Determinator::VERSION)
    # Always bump the patch version, the minor and major versions can be bumped manually
    version.patch += 1

    version_file = File.join(__dir__, "lib/determinator/version.rb")
    vfile_contents = File.read(version_file)
    new_contents = vfile_contents.sub(%r{VERSION = "(.+?)"}, %Q[VERSION = "#{version.to_s}"])

    File.write(version_file, new_contents)
    Determinator.send(:remove_const, :VERSION)
    load version_file
  end
end
