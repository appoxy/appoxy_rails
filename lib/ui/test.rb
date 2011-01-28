require 'erb'
require_relative 'binding_hack'

options = Appoxy::UI::BindingHack.new(:x=>"hi")
template = ERB.new(File.read(File.join(File.dirname(__FILE__), '_geo_location_finder.html.erb')))
ret      = template.result(options.get_binding)
p ret
