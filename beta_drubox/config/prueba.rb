
require 'yaml'

yml = YAML::load(File.open('environment.yml'))

puts yml['server_ip']

yml.each_pair { |key, value|
  puts "#{key} = #{value}"
}
