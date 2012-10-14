require 'Qt4'
require './ruboxTree.rb'
require './loginDialog.rb'
require './usuario.rb'

class DRuboxWindow < Qt::MainWindow

	slots 'login()', 'projectSelected(int)','addFile()','addFolder()','remove()','sync()'

	def initialize(parent = nil)
		super(parent)		
		createActions()
		createMenus()
		createStatusBar()
		createToolBars()
		
		setWindowIcon(Qt::Icon.new('./images/ic32.png'))
		setWindowTitle("Rubox Desktop Application")
		#@tree = RuboxTree.new()
		#setCentralWidget(@tree)

		@usuario = nil
		
		resize(800,400)
		move(300,300)

	end

	def createActions()
		@iniciarSesionAction = Qt::Action.new(tr("&Iniciar Sesion"),self)
		@iniciarSesionAction.setIcon(Qt::Icon.new('./images/ic32.png'))
		@iniciarSesionAction.setStatusTip(tr("Iniciar sesion"))
		connect(@iniciarSesionAction,SIGNAL('triggered()'),self,SLOT('login()'))

		@cerrarSesionAction = Qt::Action.new(tr("&Cerrar Sesion"),self)
		@cerrarSesionAction.setIcon(Qt::Icon.new('./images/ic32.png'))
		@cerrarSesionAction.setStatusTip(tr("Cerrar sesion"))

		@salirAction = Qt::Action.new(tr("&Salir"),self)
		@salirAction.setIcon(Qt::Icon.new('./images/ic32.png'))
		@salirAction.setStatusTip(tr("Salir de la aplicacion"))
		connect(@salirAction,SIGNAL('triggered()'),self,SLOT('close()'))

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

		@syncAction = Qt::Action.new(tr("&Sincronizar"),self)
		@syncAction.setIcon(Qt::Icon.new('./images/Sync.png'))
		@syncAction.setStatusTip(tr("Sincronizar datos"))
		connect(@syncAction,SIGNAL('triggered()'),self,SLOT('sync()'))	

	end

	def createMenus()
		@ruboxMenu = menuBar().addMenu(tr("&Rubox"))
		@ruboxMenu.addAction(@iniciarSesionAction)
		@ruboxMenu.addAction(@cerrarSesionAction)
		@ruboxMenu.addAction(@salirAction)

		@addMenu = menuBar().addMenu(tr("&Agregar"))
		@addMenu.addAction(@addFileAction)
		@addMenu.addAction(@addFolderAction)
		@addMenu.addAction(@syncAction)
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
		@ruboxToolBar.addAction(@syncAction)
	end

	def createStatusBar()
		statusBar()
	end

	def login()
		loginDialog = LoginDialog.new(self)
		if(loginDialog.exec()==Qt::Dialog::Accepted)
			u = loginDialog.getUsuario()
			p = loginDialog.getPassword()
			@usuario = Usuario.new()
			if (@usuario.iniciarSesion(u,p))
				puts "Iniciada"
				proyectos = @usuario.cargarProyectos()
								
				@projectCombo.addItem("Seleccionar...")
				
				model = @projectCombo.model()
				firstIndex = model.index(0,@projectCombo.modelColumn(),@projectCombo.rootModelIndex())
				firstItem = model.itemFromIndex(firstIndex)
				firstItem.setSelectable(false)
				firstItem.setToolTip("No elegir...")
		
				@projectsMap = Array.new()
				combo_index = 1
				proyectos.each{ |p|
					@projectCombo.addItem(p.nombre()+' ('+p.descripcion()+')')
					@projectsMap[combo_index] = p
					combo_index = combo_index + 1
				}
				#puts "Indice: "+@projectCombo.currentIndex().to_s
				#@projectCombo.setCurrentIndex(-1)
				#puts "Indice: "+@projectCombo.currentIndex().to_s
				connect(@projectCombo,SIGNAL('currentIndexChanged(int)'),self,SLOT('projectSelected(int)'))
			else
				puts "No iniciada"
			end
		end
	end

	def projectSelected(index)
		puts "\nIndice proyecto: "+index.to_s+" -> "+@projectsMap[index].nombre()
		@currentProject = @projectsMap[index]
		setCentralWidget(@currentProject.abrirProyecto())
	end

	def addFile()
		@files = Qt::FileDialog::getOpenFileNames(self,"Seleccione los archivos a agregar","/home")
		@currentProject.addFile(@files, "")
	end

	def addFolder()
		@folder = Qt::FileDialog::getExistingDirectory(self,"Seleccione las carpetas a agregar","/home",Qt::FileDialog::ShowDirsOnly)
		@currentProject.addFolder(@folder, "")
		puts @folder.to_s
	end

	def remove()
		puts "remove called"
	end

	def sync()
		@currentProject.sync()
	end

end #class

app = Qt::Application.new(ARGV)
#Qt::Application::setStyle("motif")
window = DRuboxWindow.new()
window.show()
app.exec()


