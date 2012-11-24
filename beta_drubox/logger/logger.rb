

class Logger
	
	LOG_HOME = ENV["HOME"]+"/Rubox/" + "p"
	@@logFile = File.open(LOG_HOME + "/.client.log", "a")

	def self.log(message)
		str =  "-------------------------------------------------\n"
		str += "[" + Time.new.to_s + "]\n"
		str += message + "\n"
		@@logFile.puts(str)
		@@logFile.flush
	end

	def self.log(project, level = 3, message)
		case level
		when 1
			str_level = "Error"
		when 2
			str_level = "Warning"
		when 3
			str_level = "Info"
		end

		str =  "-------------------------------------------------\n"
		str += "[" + Time.new.to_s + "]\n"
		str += project + " -> " + str_level + ": " + message + "\n"
		@@logFile.puts(str)
		@@logFile.flush	
	end
end
