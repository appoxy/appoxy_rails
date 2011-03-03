require './lib/appoxy_rails.rb'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = "appoxy_rails"
    gemspec.summary     = "Appoxy Rails Helper gem"
    gemspec.description = "Appoxy API Helper gem description..."
    gemspec.email       = "travis@appoxy.com"
    gemspec.homepage    = "http://www.appoxy.com"
    gemspec.authors     = ["Travis Reeder"]
    gemspec.files       = FileList['lib/**/*.rb', 'lib/**/*.html.erb']
    gemspec.add_dependency 'rest-client'
    gemspec.add_dependency 'oauth'
    gemspec.add_dependency 'ruby-openid'
    gemspec.add_dependency 'appoxy_api'
    gemspec.add_dependency 'mini_fb'
    gemspec.add_dependency 'simple_record'


  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler -s http://gems.github.com"
end
