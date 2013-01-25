#encoding: UTF-8
require 'gtk2'
require 'webkit'
require 'filemagic'
require 'zlib'
require 'zip/zip'
require './utils'
require './messages'
require 'rubygems'

class Editor
  INDEX = 0
  attr_accessor :data
  def initialize
	@win = Gtk::Window.new
	@win.set_icon("uzgun_surat.jpg")
	@win.set_title("RManEdit")
	@win.signal_connect('delete_event'){false}
#	@win.resize(700,500)
	@win.signal_connect('destroy'){Gtk.main_quit}
	@win.set_window_position(Gtk::Window::POS_CENTER)
	@vbox = Gtk::VBox.new(false,2)
	menuBar
	toolBar
	win_contain
	@win.show_all()
  end
 
  def win_contain
      @hbox = Gtk::HBox.new(false,2)
      @editor = Gtk::TextView.new
      swin = Gtk::ScrolledWindow.new
 #     swin.add(@editor)
      # ornek man2html eklenmesi
      output = IO.popen("man2html ls.1")
      str = output.readlines
      i = 0
      content = ""
      while i< str.length do
          content = content + str[i]
          i = i + 1
      end
      # man page icin textView
      manview = WebKit::WebView.new
      manview.load_string(content,"text/html", "UTF-8", "file://home") 
      # man goruntusu icin scrollWind
      swin2 = Gtk::ScrolledWindow.new
#      swin2.add(manview)
      @treeview = Gtk::TreeView.new
      renderer = Gtk::CellRendererText.new 
      column   = Gtk::TreeViewColumn.new(CATEGORY, renderer,  :text => INDEX)
      @treeview.append_column(column)
      list = Array.new
      list = ["NAME", "SYNOPSIS","AVAILABILITY","DESCRIPTION","OPTIONS","EXAMPLES","NOTES",
      "MESSAGES AND EXIT CALLS","AUTHOR","HISTORY","RESOURCES","FILES","BUGS","CAVEATS","SEE ALSO"]
      store = Gtk::ListStore.new(String) 
      list.each_with_index do |e, i|
	  iter = store.append
	  iter[INDEX] = list[i]
          end
      @treeview.model = store
      @treeview.signal_connect("cursor-changed"){selection = @treeview.selection; 
      iter = selection.selected; o = Utils.new; o.label_find(iter[0],@editor)}
      hpaned = Gtk::HPaned.new    
      hpaned.set_size_request(900,500)
      hpaned2 = Gtk::HPaned.new
      hpaned2.set_size_request(800,500)
      hpaned.pack1(@treeview,false,true)
      hpaned.pack2(hpaned2,false,true)
  #    swin.set_size_request(500,500)
   #   swin2.set_size_request(300,500)
      @editor.set_size_request(500,500)
      manview.set_size_request(300,500)
      hpaned2.pack1(@editor,false,true)
      hpaned2.pack2(manview,false,true)
      @win.set_size_request(900,500)
      @win.set_resizable(true)
      @hbox.pack_start(hpaned,true,true,0)
      @vbox.pack_start(@hbox,true,true,0)
  end
  def menuBar
      
     mb = Gtk::MenuBar.new
     filemenu = Gtk::Menu.new
     filemenuitem = Gtk::MenuItem.new(FILE)
     filemenuitem.set_submenu(filemenu)
     open = Gtk::MenuItem.new(OPEN)
     save = Gtk::MenuItem.new(SAVE)
     save_as = Gtk::MenuItem.new(SAVE_AS)
     make_html = Gtk::MenuItem.new(CREATE_HTML_FILE)
     exit_ = Gtk::MenuItem.new(EXIT)
     filemenu.append(open)     
     filemenu.append(save) 
     filemenu.append(save_as)
     filemenu.append(make_html)
     filemenu.append(exit_)
     mb.append(filemenuitem)
     exit_.signal_connect("activate"){Gtk.main_quit}
     make_html.signal_connect("activate"){o=Utils.new; o.create_html_file(@editor,@win)}
     @vbox.pack_start(mb,false,false,0) 
  end
  def toolBar
	toolbar = Gtk::Toolbar.new
        toolbar.set_toolbar_style(Gtk::Toolbar::Style::ICONS)
        newtb = Gtk::ToolButton.new(Gtk::Stock::NEW)
        opentb = Gtk::ToolButton.new(Gtk::Stock::OPEN)
        savetb = Gtk::ToolButton.new(Gtk::Stock::SAVE)
	cuttb = Gtk::ToolButton.new(Gtk::Stock::CUT)
	copytb = Gtk::ToolButton.new(Gtk::Stock::COPY)
	pastetb = Gtk::ToolButton.new(Gtk::Stock::PASTE)
        sep = Gtk::SeparatorToolItem.new
        quittb = Gtk::ToolButton.new(Gtk::Stock::QUIT)

        toolbar.insert(0, newtb)
        toolbar.insert(1, opentb)
        toolbar.insert(2, savetb)
	toolbar.insert(3, cuttb)
	toolbar.insert(4, copytb)
	toolbar.insert(5, pastetb)
        toolbar.insert(6, sep)
        toolbar.insert(7, quittb)
	opentb.signal_connect("clicked"){o = Utils.new; o.on_opentb(@win,@editor)}
	savetb.signal_connect("clicked"){o= Utils.new; o.on_savetb(@win,@editor)}
	cuttb.signal_connect("clicked"){o = Utils.new; o.on_cuttb(@editor)}
	copytb.signal_connect("clicked"){o = Utils.new; o.on_copytb(@editor)}
	pastetb.signal_connect("clicked"){o= Utils.new; o.on_pastetb(@editor)}
	newtb.signal_connect("clicked"){o= Utils.new; o.on_newtb(@win,@editor)}
	quittb.signal_connect("clicked"){Gtk.main_quit}
	@vbox.pack_start(toolbar,false,false,0)
	@win.add(@vbox)
  end

end

app = Editor.new
Gtk.main
