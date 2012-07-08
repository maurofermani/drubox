require "grit"

include Grit

repo = Repo.new("/home/fermani/workspace/ruby")

puts repo.index


puts repo.config
puts repo.description

st = repo.status

m = st.changed

m.each { |e| puts e.first }

#st.each do |s|
#  puts s.path + " - " + s.untracked
#end
