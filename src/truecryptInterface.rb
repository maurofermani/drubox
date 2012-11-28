require './config/yml.rb'

class TruecryptInterface

 	DRUBOX_FOLDER = ENV["HOME"] + "/" + YML::get("drubox_folder")

	def self.initDirs()
		#setupTC
		Dir.mkdir(DRUBOX_FOLDER) if(!File.directory?(DRUBOX_FOLDER))
		Dir.mkdir(DRUBOX_FOLDER+"/.hd") if(!File.directory?(DRUBOX_FOLDER+"/.hd"))
	end

	# Se usa desde la clase Usuario para crear un volumen encriptado dedicado al usuario, cuando el mismo 
	# no dispone de un volumen creado previamente (por ejemplo, la primera vez que el usuario inicia sesión 
	# en la máquina local).
	def self.createVolume(login, pw, size = 10485760)
		begin	
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
		rescue Exception => e
			raise TruecryptException, "Error al crear el volumen" , caller
		end
	end

	def self.existsVolume?(login)
		cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"
		File.exists?(cryptVol)
	end

	# Se utiliza en la clase Usuario para montar el volumen encriptado del usuario cuando se inicia la sesión, 
	# haciendo que los proyectos almacenados en el volumen queden disponibles para operar sobre ellos, 
	# principalmente desde la clase Proyecto
	def self.mountVolume(login, pw)
		begin	
			mountPoint = DRUBOX_FOLDER+"/"+login
			Dir.mkdir(mountPoint) if(!File.directory?(mountPoint)) #punto de montaje
		
			cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"
			pwVol = pw		

			`truecrypt #{cryptVol} #{mountPoint}/ -p "#{pwVol}" -k "" --non-interactive`
		rescue Exception => e
			raise TruecryptException, "Error al montar el volumen" , caller
		end
	end

	# Desmonta el volumen del usuario cuando se cierra la sesión por lo que los proyectos almacenados en el 
	# volumen ya no pueden ser accedidos.
	def self.unmountVolume(login)
		begin	
			cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"
		
			res = `truecrypt -d #{cryptVol} 2>&1`
			if (res.to_s.include?("device is busy")) 
				raise TruecryptException, "Error al desmontar el volumen. Dispositivo ocupado." , caller
			end
		rescue TruecryptException => e
			raise e
		rescue Exception => e
			raise TruecryptException, "Error al desmontar el volumen" , caller
		end
	end

end
