require 'Qt4'
require './ruboxTree.rb'
require './loginDialog.rb'
require './timeMachineDialog.rb'
require './truecryptOptionsDialog.rb'
require './usuario.rb'
require './exceptions/uploadException.rb'
require './exceptions/downloadException.rb'
require './exceptions/cloneProjectException.rb'
require './exceptions/commitException.rb'
require './exceptions/getCommitsException.rb'
require './exceptions/serverException.rb'
require './exceptions/truecryptException.rb'
require './logger/logger.rb'
require './config/yml.rb'



class DRuboxGUI < Qt::MainWindow

	slots 'login()', 'projectSelected(int)','addFile()','addFolder()','remove()','upload()','download()','timeMachine()','logout()','quitDrubox()','refreshTree()'

	def initialize(parent = nil)
		super(parent)		
		createActions()
		createMenus()
		createStatusBar()
		createToolBars()
		setWindowIcon(Qt::Icon.new('./images/ic32.png'))
		setWindowTitle("Rubox - Aplicacion de Escritorio")

		@usuario = nil
		@currentIndex = 0
		
		resize(800,400)
		move(300,300)
		installEventFilter(self)
	end

	def eventFilter(obj, evt)
		super(obj, evt)
	       	if(evt.type()==Qt::Event::WindowActivate)
			refreshTree()
		end
	end

	def closeEvent(event)
		super(event)
		quitDrubox()
	end

	def createActions()
		@iniciarSesionAction = Qt::Action.new(tr("&Iniciar Sesion"),self)
		@iniciarSesionAction.setIcon(Qt::Icon.new('./images/ic32.png'))
		@iniciarSesionAction.setStatusTip(tr("Iniciar sesion"))
		connect(@iniciarSesionAction,SIGNAL('triggered()'),self,SLOT('login()'))

		@cerrarSesionAction = Qt::Action.new(tr("&Cerrar Sesion"),self)
		@cerrarSesionAction.setIcon(Qt::Icon.new('./images/ic32.png'))
		@cerrarSesionAction.setStatusTip(tr("Cerrar sesion"))
		connect(@cerrarSesionAction,SIGNAL('triggered()'),self,SLOT('logout()'))

		@salirAction = Qt::Action.new(tr("&Salir"),self)
		@salirAction.setIcon(Qt::Icon.new('./images/ic32.png'))
		@salirAction.setStatusTip(tr("Salir de la aplicacion"))
		connect(@salirAction,SIGNAL('triggered()'),self,SLOT('quitDrubox()'))

		@addFileAction = Qt::Action.new(tr("Agregar &Archivo"),self)
		@addFileAction.setIcon(Qt::Icon.new('./images/File.png'))
		@addFileAction.setStatusTip(tr("Agregar archivo"))
		connect(@addFileAction,SIGNAL('triggered()'),self,SLOT('addFile()'))

		@addFolderAction = Qt::Action.new(tr("Agregar &Carpeta"),self)
		@addFolderAction.setIcon(Qt::Icon.new('./images/Folder.png'))
		@addFolderAction.setStatusTip(tr("Agregar carpeta"))
		connect(@addFolderAction,SIGNAL('triggered()'),self,SLOT('addFolder()'))

		@removeAction = Qt::Action.new(tr("&Eliminar"),self)
		@removeAction.setIcon(Qt::Icon.new('./images/Remove.png'))
		@removeAction.setStatusTip(tr("Eliminar archivo o carpeta"))
		connect(@removeAction,SIGNAL('triggered()'),self,SLOT('remove()'))

		@uploadAction = Qt::Action.new(tr("&Subir cambios"),self)
		@uploadAction.setIcon(Qt::Icon.new('./images/up_b.png'))
		@uploadAction.setStatusTip(tr("Subir los cambios al servidor..."))
		connect(@uploadAction,SIGNAL('triggered()'),self,SLOT('upload()'))

		@downAction = Qt::Action.new(tr("&Bajar cambios"),self)
		@downAction.setIcon(Qt::Icon.new('./images/down_b.png'))
		@downAction.setStatusTip(tr("Bajar los cambios del servidor..."))
		connect(@downAction,SIGNAL('triggered()'),self,SLOT('download()'))

		@timeMachineAction = Qt::Action.new(tr("&Maquina del tiempo"),self)
		@timeMachineAction.setIcon(Qt::Icon.new('./images/TimeMachine.png'))
		@timeMachineAction.setStatusTip(tr("Obtener versiones pasadas de los archivos..."))
		connect(@timeMachineAction,SIGNAL('triggered()'),self,SLOT('timeMachine()'))

		@statusAction = Qt::Action.new(tr("&Status"),self)
		@statusAction.setIcon(Qt::Icon.new('./images/status.png'))
		@statusAction.setStatusTip(tr("Obtener status de los archivos..."))
		connect(@statusAction,SIGNAL('triggered()'),self,SLOT('refreshTree()'))		

		enableActions(false)
	end

	def createMenus()
		@ruboxMenu = menuBar().addMenu(tr("&Rubox"))
		@ruboxMenu.addAction(@iniciarSesionAction)
		@ruboxMenu.addAction(@cerrarSesionAction)
		@ruboxMenu.addAction(@salirAction)

		@addMenu = menuBar().addMenu(tr("&Agregar"))
		@addMenu.addAction(@addFileAction)
		@addMenu.addAction(@addFolderAction)
		@addMenu.addAction(@uploadAction)
		@addMenu.addAction(@downAction)
		@addMenu.addAction(@timeMachineAction)
	end

	def createToolBars()
		@ruboxToolBar = addToolBar(tr("&Rubox"))
		@ruboxToolBar.addAction(@iniciarSesionAction)

		@projectCombo = Qt::ComboBox.new()
		@projectCombo.setSizeAdjustPolicy(0)	
		
		@ruboxToolBar.addSeparator()
		@ruboxToolBar.addWidget(Qt::Label.new(tr("Proyectos: ")))
		@ruboxToolBar.addWidget(@projectCombo)

		@ruboxToolBar.addSeparator()
		@ruboxToolBar.addAction(@addFileAction)
		@ruboxToolBar.addAction(@addFolderAction)
		@ruboxToolBar.addAction(@removeAction)
		@ruboxToolBar.addAction(@uploadAction)
		@ruboxToolBar.addAction(@downAction)
		@ruboxToolBar.addAction(@timeMachineAction)
		@ruboxToolBar.addAction(@statusAction)
	end

	def createStatusBar()
		statusBar()
	end

	def enableActions(enable, accessType = 3)
		@addFileAction.setEnabled(enable)
		@addFolderAction.setEnabled(enable)
		@removeAction.setEnabled(enable)
		
		@downAction.setEnabled(enable)
		@timeMachineAction.setEnabled(enable)
		@statusAction.setEnabled(enable)
		
		if enable and (accessType.to_i==1 or accessType.to_i==2) 
			@uploadAction.setEnabled(enable)
		else
			@uploadAction.setEnabled(false)
		end
	end

	def login()
		begin
		if(@usuario == nil)
			loginDialog = LoginDialog.new(self)
			if(loginDialog.exec()==Qt::Dialog::Accepted)
				u = loginDialog.getUsuario()
				p = loginDialog.getPassword()
				@usuario = Usuario.new()
				if (@usuario.iniciarSesion(u,p))
					ENV["user"] = @usuario.login

					#metodo de consulta en la calse usuario para saber si existe el dir de trabajo
					#consultar, y si no existe, preguntar tamaño y usar metodo para crearlo

					if(!@usuario.tieneWorkspace?())
						#leer tamaño	
						truecryptOptions = TruecryptOptionsDialog.new(self)	
						truecryptOptions.exec()
						size = truecryptOptions.getSize()
						@usuario.crearWorkspace(size)
					end
					@usuario.montarWorkspace()

					proyectos = @usuario.cargarProyectos()
								
					@projectCombo.addItem("Seleccionar...")
				
					model = @projectCombo.model()
					firstIndex = model.index(0,@projectCombo.modelColumn(),@projectCombo.rootModelIndex())
					firstItem = model.itemFromIndex(firstIndex)
					firstItem.setSelectable(false)
	
					proyectos.each{ |p|
						@projectCombo.addItem(p)
					}
					connect(@projectCombo,SIGNAL('currentIndexChanged(int)'),self,SLOT('projectSelected(int)'))
				else
					@usuario = nil					
					Logger::logMessage("Usuario o password incorrectos")
					Qt::MessageBox::warning(self,tr('DRubox'),tr("Usuario o password incorrectos"))
				end
			end
		end
		rescue TruecryptException => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(),Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr(e.message()))
		rescue ServerException => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(),Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr(e.message()))
			@usuario = nil
		rescue Exception => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(),Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al loguearse"))
			logout()
		end
	end

	def logout()
		begin
			@usuario.cerrarSesion() if(@usuario != nil)
		rescue TruecryptException => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())
			Qt::MessageBox::warning(self,tr('DRubox'),tr(e.message()))
		rescue Exception => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error de conexion al servidor"))
		ensure
			@usuario = nil
			@proyecto = nil
			@tree.clear() if(@tree != nil)
			@tree = nil
			@projectCombo.clear() if(@projectCombo != nil)
			@currentIndex = 0
			enableActions(false)
			ENV["user"] = nil
		end
	end

	def quitDrubox()
		logout()
		close()
	end

	def projectSelected(index)
		begin
			if (index>0) and (index!=@currentIndex)
				@currentIndex = index		
				projectPath = @usuario.setCurrentProject(index-1)
				@tree = RuboxTree.new(nil,projectPath)
				setCentralWidget(@tree)
				@proyecto = @usuario.getCurrentProject()
				getStatus()
				enableActions(true, @proyecto.accessType())
			end
		rescue CloneProjectException => e
			@tree.clear() if(@tree!=nil)
			@projectCombo.setCurrentIndex(0) if(@projectCombo!=nil) and (@projectCombo.count()>0)
			@currentIndex = 0			
			enableActions(false)
			Qt::MessageBox::critical(self,tr('DRubox'),tr(e.message()))
		rescue Exception => e
			#error al abrir el proyecto
			@tree.clear() if(@tree!=nil)
			@projectCombo.setCurrentIndex(0) if(@projectCombo!=nil) and (@projectCombo.count()>0)
			@currentIndex = 0			
			enableActions(false)
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al abrir el proyecto"))
		end
	end

	def addFile()
		begin		
			newPath = @tree.getSelectedFolder()		
			file = Qt::FileDialog::getOpenFileName(self,"Seleccione los archivos a agregar","/home")
			if (file!=nil)
				yaExiste = @proyecto.fileExists?(file, newPath)		
				if yaExiste
					op = Qt::MessageBox::warning(self,tr('DRubox'),tr("El archivo ya existe, desea reemplazarlo?"),Qt::MessageBox::Yes | Qt::MessageBox::No)
					if (op==Qt::MessageBox::Yes)
						@proyecto.addFile(file, newPath)
					end
				else
					@proyecto.addFile(file, newPath)
				end
			end
		rescue Exception => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())			
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al agregar el archivo"))
		ensure
			refreshTree()
		end
	end

	def addFolder()
		begin	
			newPath = @tree.getSelectedFolder()
			folder = Qt::FileDialog::getExistingDirectory(self,"Seleccione las carpetas a agregar","/home",Qt::FileDialog::ShowDirsOnly)
			if(folder!=nil)		
				yaExiste = @proyecto.fileExists?(folder, newPath)		
				if yaExiste		
					op = Qt::MessageBox::warning(self,tr('DRubox'),tr("La carpeta ya existe, desea reemplazarla?"),Qt::MessageBox::Yes | Qt::MessageBox::No)
					if (op==Qt::MessageBox::Yes)
						@proyecto.addFolder(folder, newPath)
					end	
				else
					@proyecto.addFolder(folder, newPath) 
				end
			end
		rescue Exception => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())			
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al agregar la carpeta"))
		ensure		
			refreshTree()
		end
	end

	def remove()
		begin				
			rm_path = @tree.removeSelectedItem()
			@proyecto.remove(rm_path) if(rm_path!=nil)
		rescue Exception => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())			
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al eliminar el archivo o carpeta"))
		ensure		
			refreshTree()
		end
	end

	def upload()
		begin
			cambios = @proyecto.hayCambios?
			if (cambios)
				ok = Qt::Boolean.new
				msg = Qt::InputDialog::getText(self,tr("Mensaje"), tr("Mensaje de los cambios"), Qt::LineEdit::Normal, "", ok)
				if !ok.nil?
					if msg!= nil and !msg.empty?
						@proyecto.upload(msg)
						Qt::MessageBox::information(self,tr('DRubox'), tr("Cambios subidos correctamente."))
					else
						Qt::MessageBox::information(self,tr('DRubox'), tr("Ingrese un mensaje para los cambios."))
					end
				end
			else
				@proyecto.upload("")
				Qt::MessageBox::information(self,tr('DRubox'), tr("Cambios subidos correctamente."))
			end
		rescue CommitException, DownloadException, UploadException  => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr(e.message()))
		rescue Exception => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al subir los cambios al servidor"))			
		ensure		
			refreshTree()
		end
	end

	def download()
		begin
		cambios = @proyecto.hayCambios?
		if (cambios)
			ok = Qt::Boolean.new
			msg = Qt::InputDialog::getText(self,tr("Mensaje"),
				tr("Mensaje de los cambios"),
				Qt::LineEdit::Normal, "", ok)
			if !ok.nil?
				if msg!= nil and !msg.empty?
					@proyecto.download(msg)
					
					Qt::MessageBox::information(self,tr('DRubox'),
						tr("Cambios descargados correctamente."))
				else
					Qt::MessageBox::information(self,tr('DRubox'),
						tr("Ingrese un mensaje para los cambios."))
				end
			end
		else
			@proyecto.download("")
			Qt::MessageBox::information(self,tr('DRubox'),
				tr("Cambios descargados correctamente."))
		end
		rescue CommitException, DownloadException  => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr(e.message()))
		rescue  Exception => e	
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al descargar los cambios desde el servidor"))
		ensure		
			refreshTree()	
		end
	end

	def timeMachine()
		begin			
			path = @tree.getSelectedFile()
			if(path!=nil)
				commits = @proyecto.getFileCommits(path)	
				if (commits!=nil)				
					timeMachineDialog = TimeMachineDialog.new(path, commits, self)
					if(timeMachineDialog.exec()==Qt::Dialog::Accepted)
						newFileName = timeMachineDialog.getFolder + "/" + timeMachineDialog.getNewFileName()
						@proyecto.recuperarArchivo(path, newFileName , timeMachineDialog.getSelectedSha())
					end
				else
					Qt::MessageBox::information(self,tr('DRubox'),tr("No se encontraron versiones anteriores del archivo"))		
				end
			end
		rescue GetCommitsException => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr(e.message()))	
		rescue Exception => e
			Logger::log( (@proyecto == nil or @proyecto.nombre() == nil)? "": @proyecto.nombre(), Logger::ERROR,e.message())
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al obtener las versiones anteriores del archivo"))	
		ensure		
			refreshTree()
		end
	end

	def getStatus()
		if (@proyecto!=nil) and (@tree!=nil) 
			status = @proyecto.status() 
			if(status!=nil)
				@tree.updateStatus(status)   
			else
				untrackedFiles = @proyecto.noCommitStatus() 
				@tree.updateNoCommitStatus(untrackedFiles) 
			end
		end
	end

	def refreshTree()
		@tree.refresh() if (@tree!=nil)
		getStatus()
	end

end #class

begin
  app = Qt::Application.new(ARGV)
  window = DRuboxGUI.new()
  window.show()
  window.login()
  app.exec()

end


