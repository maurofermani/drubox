

class Logger
	
	ERROR = "Error"
	WARNING = "Warning"
	INFO = "Info"

	LOG_HOME = ENV["HOME"]+"/Rubox/" + "p"
	@@logFile = File.open(LOG_HOME + "/.client.log", "a")

	def self.log(message)
		str =  "-------------------------------------------------\n"
		str += "[" + Time.new.to_s + "]\n"
		str += message + "\n"
		@@logFile.puts(str)
		@@logFile.flush
	end

	def self.log(project, level = @@INFO, message)
		str =  "-------------------------------------------------\n"
		str += "[" + Time.new.to_s + "]\n"
		str += project + " -> " + level + ": " + message + "\n"
		@@logFile.puts(str)
		@@logFile.flush	
	end

end
