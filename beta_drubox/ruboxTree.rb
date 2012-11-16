class RuboxTree < Qt::TreeWidget
#class RuboxTree < Qt::TreeView
	
	#FOLDER_PATH = "/home/p4c/Escritorio/ejrubyqt/drubox/drubox_files"
	FILE_ICON_PATH = "./images/File.png"
	FOLDER_ICON_PATH = "./images/Folder.png"

#	def initialize (parent = nil)
#		super(parent)
#		#setHeaderLabels(['Id','Nombre', 'Tipo', 'Path', 'Estado'])
#		@model = Qt::FileSystemModel.new()
#		@model.setRootPath(FOLDER_PATH)
#		@model.setReadOnly(false)
#		
#		setModel(@model)
#		setRootIndex(@model.index(FOLDER_PATH));
#		resize(640, 480);
#	end

	def initialize (parent = nil, path)
		super(parent)
		setHeaderLabels(['File Name', 'Last Modified', 'Size', 'Path','State'])
		#g = Git.init(FOLDER_PATH)
		#g = Git.open(FOLDER_PATH)
		
		@path = path
		populate(self,@path)
		
		#puts g.status
		#puts g.status.added
		#puts g.status.changed
		#puts g.status.deleted
		#puts g.status.untracked
		#puts g.status.pretty
	end

	def populate(tree, path, parent=nil)
		Dir["#{path}/*"].each do |file|
			#fill item information
			item = Qt::TreeWidgetItem.new()
			item.setText(0, File.basename(file))
			item.setText(1, File.mtime(file).strftime("%Y-%m-%d %I:%M:%S %p"))
			item.setText(2, (File.size(file).to_s + ' bytes'))
			item.setText(3, File.dirname(file) + '/')

			if ( File.ftype(file)=="file")
				item.setIcon(0, Qt::Icon.new(FILE_ICON_PATH) )
			elsif(File.ftype(file)=="directory")
				item.setIcon(0, Qt::Icon.new(FOLDER_ICON_PATH) )	
			end
		
			#add item to the tree
			if (parent == nil)
				tree.addTopLevelItem(item)
			else
				parent.insertChild(parent.childCount, item)
			end

			if (File.ftype(file) == 'directory')
				populate(tree, file, item)
			end
		end
	end

	def addFile(files, newPath = nil)
		
		path = (newPath==nil)? @path : newPath["path"]
		files.each{ |f|
			file = path+"/"+File.basename(f)

			item = Qt::TreeWidgetItem.new()
			item.setText(0, File.basename(file))
			item.setText(1, File.mtime(file).strftime("%Y-%m-%d %I:%M:%S %p"))
			item.setText(2, (File.size(file).to_s + ' bytes'))
			item.setText(3, File.dirname(file) + '/')
			item.setIcon(0, Qt::Icon.new(FILE_ICON_PATH))
			if (newPath==nil)
				addTopLevelItem(item)
			else
				 newPath["item"].insertChild(newPath["item"].childCount, item)
			end	
		}
	end

	def addFolder(folderPath, newPath = nil)
		folder = (newPath==nil)? @path+"/"+File.basename(folderPath) : newPath["path"]+"/"+File.basename(folderPath)

		folder_item = Qt::TreeWidgetItem.new()
		folder_item.setText(0, File.basename(folder))
		folder_item.setText(1, File.mtime(folder).strftime("%Y-%m-%d %I:%M:%S %p"))
		folder_item.setText(2, (File.size(folder).to_s + ' bytes'))
		folder_item.setText(3, File.dirname(folder) + '/')
		folder_item.setIcon(0, Qt::Icon.new(FOLDER_ICON_PATH))
		if (newPath==nil)
			addTopLevelItem(folder_item)
		else
			 newPath["item"].insertChild(newPath["item"].childCount, folder_item)
		end		
		populate(self,folder,folder_item)
	end

	def removeSelectedItem()
		item = selectedItems()
		if (!item.empty?)		
			path = item[0].text(3)+item[0].text(0) 
			if (File.ftype(path) == 'directory')
				msg = "Desea eliminar el directorio #{item[0].text(0)}? (Se eliminara tambien su contenido)"
			else
				msg = "Desea eliminar el archivo #{item[0].text(0)}?"
			end			
			
			op = Qt::MessageBox::warning(self,tr('DRubox'),tr(msg),Qt::MessageBox::Yes | Qt::MessageBox::No)
			if (op==Qt::MessageBox::Yes)
				parent = item[0].parent() ? item[0].parent() : invisibleRootItem()
				i = parent.takeChild(parent.indexOfChild(item[0]))
				puts "sacado: "+i.text(3)+i.text(0)
				puts "path: "+path
				return path
			else
				return nil
			end
		end
	end

	def getSelectedFile()
		item = selectedItems()
		path = nil
		if (!item.empty?)		
			path = item[0].text(3)+item[0].text(0)
			if(File.ftype(path) != 'file')
				path = nil
			end
		end
		return path
	end

	def getSelectedFolder()
		item = selectedItems()
		folder = nil
		if (!item.empty?)		
			path = item[0].text(3)+item[0].text(0)
			if(File.ftype(path) == 'directory')
				folder = {"path" => path, "item" => item[0]}
			end
		end
		return folder
	end
	
	def refresh()
		clear()
		populate(self,@path)
	end
end
