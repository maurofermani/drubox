require './config/yml.rb'

class Logger
	
	ERROR = "Error"
	WARNING = "Warning"
	INFO = "Info"

	DRUBOX_FOLDER = ENV["HOME"] + "/" + YML::get("drubox_folder")

	@@druboxFolder = Dir.mkdir(DRUBOX_FOLDER) if(!File.directory?(DRUBOX_FOLDER))
	@@logFile = File.open(DRUBOX_FOLDER + "/.client.log", "a")

	def self.logMessage(message)
		str =  "-------------------------------------------------\n"
		str += "[" + Time.new.to_s + "] "
		str += ENV["user"] == nil ? "Sin usuario" : "Usuario: " + ENV["user"]
		str += "\n"
		str += message + "\n"
		@@logFile.puts(str)
		@@logFile.flush
	end

	def self.log(project, level, message)
		str =  "-------------------------------------------------\n"
		str += "[" + Time.new.to_s + "] "
		str += ENV["user"] == nil ? "Sin usuario" : "Usuario: " + ENV["user"]
                str += "\n"
		str += project + " -> " + level + ": " + message + "\n"
		@@logFile.puts(str)
		@@logFile.flush	
	end

end
