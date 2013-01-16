#encoding: UTF-8
require 'filemagic'
require 'zlib'
require 'zip/zip'
require './utils'
require 'gettext'
require 'rubygems'
require 'gtk2'

class Editor
  include GetText
  INDEX = 0
  attr_accessor :data
  def initialize
	bindtextdomain("editor", :path => "locale")
	GetText.set_locale_all("en")
	@win = Gtk::Window.new
	@win.set_icon("uzgun_surat.jpg")
	@win.set_title("RManEdit")
	@win.signal_connect('delete_event'){false}
	@win.resize(500,500)
	@win.signal_connect('destroy'){Gtk.main_quit}
	@win.set_window_position(Gtk::Window::POS_CENTER)
	@vbox = Gtk::VBox.new(false,2)
	toolBar
	win_contain
	@win.show_all()
  end
 
  def win_contain
      @hbox = Gtk::HBox.new(false,2)
      label1 = Gtk::Label.new(_("Etiket"),true)
      @editor = Gtk::TextView.new
      label3 = Gtk::Label.new(_("Görüntü"),true)
      swin = Gtk::ScrolledWindow.new
      swin.add(@editor)
      @treeview = Gtk::TreeView.new
      renderer = Gtk::CellRendererText.new 
      column   = Gtk::TreeViewColumn.new(_("Bölümler"), renderer,  :text => INDEX)
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
      @treeview.signal_connect("cursor-changed"){selection = @treeview.selection; iter = selection.selected; puts iter[0]}
      @hbox.pack_start(@treeview,true,true,0)
      @hbox.pack_start(swin,true,true,0)
      @hbox.pack_start(label3,true,true,0)
      @vbox.pack_start(@hbox,true,true,0)
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
