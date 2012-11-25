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
		setHeaderLabels(["Nombre", "Estado", "Tamano", "","Fecha Modificacion"])
		5.times{ |i| header().setResizeMode(i,Qt::HeaderView::ResizeToContents) }
		
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
			item.setText(1, "") #status se inicializa con el evento
			item.setText(2, (File.size(file).to_s + ' bytes'))
			item.setText(3, file)
			item.setText(4, File.mtime(file).strftime("%Y-%m-%d %I:%M:%S %p"))

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

	def addFile(file, newPath = nil)
		
		path = (newPath==nil)? @path : newPath["path"]
		
		file = path+"/"+File.basename(file)

		item = Qt::TreeWidgetItem.new()
		item.setText(0, File.basename(file))
		item.setText(1, "")
		item.setText(2, (File.size(file).to_s + ' bytes'))
		item.setText(3, file)
		item.setText(4, File.mtime(file).strftime("%Y-%m-%d %I:%M:%S %p"))
		item.setIcon(0, Qt::Icon.new(FILE_ICON_PATH))
		if (newPath==nil)
			addTopLevelItem(item)
		else
			 newPath["item"].insertChild(newPath["item"].childCount, item)
		end	
		
	end

	def addFolder(folderPath, newPath = nil)
		folder = (newPath==nil)? @path+"/"+File.basename(folderPath) : newPath["path"]+"/"+File.basename(folderPath)

		folder_item = Qt::TreeWidgetItem.new()
		folder_item.setText(0, File.basename(folder))
		folder_item.setText(1, "")
		folder_item.setText(2, (File.size(folder).to_s + ' bytes'))
		folder_item.setText(3, folder )
		folder_item.setText(4, File.mtime(folder).strftime("%Y-%m-%d %I:%M:%S %p"))
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
		if (!item.empty?) and (File.exists?(path = item[0].text(3)))
			
			if (File.ftype(path) == 'directory')
				msg = "Desea eliminar el directorio #{item[0].text(0)}? (Se eliminara tambien su contenido)"
			else
				msg = "Desea eliminar el archivo #{item[0].text(0)}?"
			end			
			
			op = Qt::MessageBox::warning(self,tr('DRubox'),tr(msg),Qt::MessageBox::Yes | Qt::MessageBox::No)
			if (op==Qt::MessageBox::Yes)
				parent = item[0].parent() ? item[0].parent() : invisibleRootItem()
				i = parent.takeChild(parent.indexOfChild(item[0]))
				puts "sacado: "+i.text(3)
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
			path = item[0].text(3)
			if(!File.exists?(path)) or (File.ftype(path) != 'file')
				path = nil
			end
		end
		return path
	end

	def getSelectedFolder()
		item = selectedItems()
		folder = nil
		if (!item.empty?) 	
			path = item[0].text(3)
			if(File.exists?(path)) and (File.ftype(path) == 'directory')
				folder = {"path" => path, "item" => item[0]}
			end
		end
		return folder
	end
	
	def refresh()
		clear()
		populate(self,@path)
	end

	def updateStatusIcons(files, iconPath, statusText)
		files.each{ |f,s|
			filePath = @path+"/"+s.path.to_s
			puts "filepath: "+filePath
			fileName = File.basename(filePath)
			puts "filename: "+fileName
			items = findItems(filePath, Qt::MatchCaseSensitive|Qt::MatchRecursive,3)
			items.each{ |i|
				puts "1: "+filePath
				puts "2: "+i.text(3)
				if(i.text(3)==filePath)
					i.setText(1, statusText)
					i.setIcon(1, Qt::Icon.new(iconPath))		
				end
			}	
		}
	end

	def updateStatusIconsDeleted(files, iconPath, statusText)
		puts "deleted"
		files.each{ |f,s|
			
			filePath = @path+"/"+s.path.to_s
			puts "filepath: "+filePath
			fileName = File.basename(filePath)
			puts "filename: "+fileName
			items = findItems(filePath, Qt::MatchCaseSensitive|Qt::MatchRecursive,3)
			
			if (items.length()==0)
				
				splitPath = s.path.split("/")
				parent = nil
				parent_path =  @path
				for i in 0..splitPath.length-2
					parent_path = parent_path+"/"+splitPath[i] 					
					f = findItems(parent_path, Qt::MatchCaseSensitive|Qt::MatchRecursive,3)
				
					if(f.length==0)
						folder_item = Qt::TreeWidgetItem.new()
						folder_item.setText(0, splitPath[i])
						folder_item.setIcon(0, Qt::Icon.new(FOLDER_ICON_PATH))
						folder_item.setText(3, parent_path)

						if (parent==nil)
							addTopLevelItem(folder_item)
							
						else
							parent.insertChild(parent.childCount, folder_item)
						end	
						parent = folder_item
					else
						f.each{ |fol|
							parent = fol if(fol.text(3)==parent_path)	
						}						
					end
				end
				item = Qt::TreeWidgetItem.new()
				item.setText(0, splitPath[splitPath.length-1])
				item.setIcon(0, Qt::Icon.new(FILE_ICON_PATH))				
				item.setText(3, parent_path+"/")
				item.setText(1, statusText)
				item.setIcon(1, Qt::Icon.new(iconPath))
				if(parent==nil)
					addTopLevelItem(item)
				else
					parent.insertChild(parent.childCount,item)	
				end
			else
				items.each{ |it|
					puts "1: "+filePath
					puts "2: "+it.text(3)
					if(it.text(3)==filePath)
						it.setText(1, statusText)
						it.setIcon(1, Qt::Icon.new(iconPath))		
					end
				}
			end	
		}
	end

	def updateNoCommitStatus(untracked)
		untracked.each{ |u|
			items = findItems(u, Qt::MatchCaseSensitive|Qt::MatchRecursive,3)
			items.each{ |it|
				if(it.text(3)==u)
					it.setText(4, "Untracked")
					it.setIcon(4, Qt::Icon.new("./images/status_added.png"))		
				end
			}	
		}
		
	end

	def updateStatus(status)
		updateStatusIcons(status.untracked, "./images/status_added.png", "Untracked")
		updateStatusIcons(status.changed, "./images/status_changed.png", "Changed")
		updateStatusIcons(status.added, "./images/status_added.png", "Added")
		updateStatusIconsDeleted(status.deleted, "./images/status_deleted.png", "Deleted")
	end


end
