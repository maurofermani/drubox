require './config/yml.rb'

class TruecryptInterface

 	DRUBOX_FOLDER = ENV["HOME"] + "/" + YML::get("drubox_folder")

	def self.initDirs()
		#setupTC
		Dir.mkdir(DRUBOX_FOLDER) if(!File.directory?(DRUBOX_FOLDER))
		Dir.mkdir(DRUBOX_FOLDER+"/.hd") if(!File.directory?(DRUBOX_FOLDER+"/.hd"))
	end

	def self.createVolume(login, pw, size = 10485760)
		#crear volumen TC (DRUBOX_FOLDER+"/.hd/"+@username+".ci")) si no existe
		cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"
		pwVol = pw
		sizeVol = size #esto pedirlo al usuario
		randomFileVol = "/tmp/random.txt" #esto cambiarlo, generar el archivo en el momento y ver si despues se puede borrar
		
		#crea un String aleatorio para generar el archivo para el --random-source de truecrypt
		randomString = ""
		320.times{randomString << ( rand(2)==1? ( (rand(2)==1?65:97) + rand(25)) : rand(9) + 48 ).chr}
		file = File.new(randomFileVol,"w")
		file.puts(randomString)
		file.close()
				

		`echo 5 | truecrypt -t -c #{cryptVol} --volume-type=normal --encryption="AES" --hash="SHA-512" -p="#{pwVol}" -k "" --random-source=#{randomFileVol} --size="#{sizeVol}"` if(!File.exists?(cryptVol))
	
		File.delete(randomFileVol) if (File.exists?(randomFileVol))
	end

	def self.existsVolume?(login)
		cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"
		File.exists?(cryptVol)
	end

	def self.mountVolume(login, pw)
		mountPoint = DRUBOX_FOLDER+"/"+login
		Dir.mkdir(mountPoint) if(!File.directory?(mountPoint)) #punto de montaje
		
		cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"
		pwVol = pw		

		`truecrypt #{cryptVol} #{mountPoint}/ -p "#{pwVol}" -k "" --non-interactive`
	end

	def self.unmountVolume(login)
		cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"
		
		res = `truecrypt -d #{cryptVol} 2>&1`
		if (res.to_s.include?("device is busy")) 
			raise TruecryptException, "Error al desmontar el volumen. Dispositivo ocupado." , caller
		end
	end

end
