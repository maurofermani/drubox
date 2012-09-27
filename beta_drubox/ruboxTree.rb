require 'git'

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
		
		populate(self,path)
		
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

end
