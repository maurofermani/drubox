require 'git'
require 'rubygems'
#require 'Logger'

Git.init("/var/cache/git/nuevo/")   

Git.init('/home/fermani/Desktop/nuevo1/')

g = Git.open('/home/fermani/Desktop/nuevo1/')
puts g.dir




=begin
g = Git.open("/home/fermani/workspace/ruby")#, :log => Logger.new(STDOUT))

#g.add('.')

#g.commit('commit int')

g.status.to_a.each do |u|
  puts u.class.to_s
end
=end

#puts g.repo.to_s + " - " + g.dir.to_s

