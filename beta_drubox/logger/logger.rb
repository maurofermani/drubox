

class Logger
	
	LOG_HOME = ENV["HOME"]+"/.drubox/" + "m"
	@@logFile = File.open(LOG_HOME + "/.client.log", "a")

	def self.log(message)
		str =  "-------------------------------------------------\n"
		str += "[" + Time.new.to_s + "]\n"
		str += message + "\n"
		@@logFile.puts(str)
		@@logFile.flush
	end
end
