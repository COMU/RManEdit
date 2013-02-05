#!/usr/bin/ruby
#encoding: UTF-8
require 'gtk2'
require 'webkit'
require 'filemagic'
require 'zlib'
require 'zip/zip'
require './utils'
require './lang'
load 'messages.rb'
require 'rubygems'

class Editor < Utils
  INDEX = 0
  attr_accessor :data
  def initialize
	@win = Gtk::Window.new
	@win.set_icon("images/uzgun_surat.jpg")
	@win.set_title("RManEdit")
	@win.signal_connect('delete_event'){false}
	@win.signal_connect('destroy'){Gtk.main_quit}
	@win.set_window_position(Gtk::Window::POS_CENTER)
	@vbox = Gtk::VBox.new(false,2)
        @editor = Gtk::TextView.new
        @buf = Gtk::TextBuffer.new
        @editor.set_buffer(@buf) 
	menuBar
	toolBar
        win_contain
	@win.show_all()
  end
 
  def win_contain
      @hbox = Gtk::HBox.new(false,2)
      swin = Gtk::ScrolledWindow.new
      @manview = WebKit::WebView.new
      @treeview = Gtk::TreeView.new
      swin.add(@editor)
      content = "<html><head><h2> #{NO_MAN_FILE}</h2></head></HTML>"
      # man page icin textView
      @manview.load_string(content,"text/html", "UTF-8", "file://home") 
      # man goruntusu icin scrollWind 
      swin2 = Gtk::ScrolledWindow.new()
      swin2.add(@manview)
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
      hpaned.set_size_request(900,-1)
      hpaned2 = Gtk::HPaned.new
      hpaned2.set_size_request(800,500)
      hpaned.pack1(@treeview,true,false)
      hpaned.pack2(hpaned2,true,true)
      swin.set_size_request(500,500)
      swin2.set_size_request(300,500)
      hpaned2.pack1(swin,true,true)
      hpaned2.pack2(swin2,true,false)
      hpaned.set_position(30)
      
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
     new = Gtk::MenuItem.new(NEW)
     save = Gtk::MenuItem.new(SAVE)
     save_as = Gtk::MenuItem.new(SAVE_AS)
     make_html = Gtk::MenuItem.new(CREATE_HTML_FILE)
     exit_ = Gtk::MenuItem.new(EXIT)
     filemenu.append(open)    
     filemenu.append(new) 
     filemenu.append(save) 
     filemenu.append(save_as)
     filemenu.append(make_html)
     filemenu.append(exit_)
     mb.append(filemenuitem)
     # setting menu
     settingmenu = Gtk::Menu.new
     settingmenuitem = Gtk::MenuItem.new(SETTINGS)
     settingmenuitem.set_submenu(settingmenu)
     mb.append(settingmenuitem)
     imenu = Gtk::Menu.new
     lang = Gtk::MenuItem.new(LANGUAGES)
     lang.set_submenu(imenu)
     en = Gtk::MenuItem.new(ENGLISH)
     tr = Gtk::MenuItem.new(TURKISH)
     de = Gtk::MenuItem.new(GERMAN)
     imenu.append(tr)
     imenu.append(en)
     imenu.append(de) 
     settingmenu.append(lang)
     # about
     aboutmenu = Gtk::Menu.new
     aboutmenuitem = Gtk::MenuItem.new(ABOUT)
     aboutmenuitem.set_submenu(aboutmenu)
     app_about = Gtk::MenuItem.new(APP_ABOUT)
     aboutmenu.append(app_about)
     # help 
     helpmenuitem = Gtk::MenuItem.new(HELP)
     aboutmenu.append(helpmenuitem)     
     mb.append(aboutmenuitem)

     open.signal_connect("activate"){o=Utils.new; o.open_file(@win,@editor)}
     new.signal_connect("activate"){o=Utils.new; o.open_new_empty_file(@win,@editor)}
     save.signal_connect("activate"){o=Utils.new; o.save(@win,@editor,"")}
     save_as.signal_connect("activate"){o=Utils.new; o.save_as(@win,@editor,"save_as")}
     exit_.signal_connect("activate"){Gtk.main_quit}
     make_html.signal_connect("activate"){o=Utils.new; o.create_html_file(@editor,@win)}
     en.signal_connect("activate"){o=Utils.new;o.lang_choice(@win,"en")}
     tr.signal_connect("activate"){o=Utils.new;o.lang_choice(@win,"tr")}
     app_about.signal_connect("activate"){o=Utils.new; o.app_about}
     helpmenuitem.signal_connect("activate"){o=Utils.new; o.help}
     @vbox.pack_start(mb,false,false,0) 
  end
  def toolBar
	toolbar = Gtk::Toolbar.new
        toolbar.set_toolbar_style(Gtk::Toolbar::Style::ICONS)
        toolbar.icon_size = 2
        newtb = Gtk::ToolButton.new(Gtk::Stock::NEW)
        opentb = Gtk::ToolButton.new(Gtk::Stock::OPEN)
        savetb = Gtk::ToolButton.new(Gtk::Stock::SAVE)
        saveastb = Gtk::ToolButton.new(Gtk::Stock::SAVE_AS)
	cuttb = Gtk::ToolButton.new(Gtk::Stock::CUT)
	copytb = Gtk::ToolButton.new(Gtk::Stock::COPY)
	pastetb = Gtk::ToolButton.new(Gtk::Stock::PASTE)
        view_but = Gtk::ToolButton.new(Gtk::Stock::PRINT_PREVIEW)
        sep = Gtk::SeparatorToolItem.new
        quittb = Gtk::ToolButton.new(Gtk::Stock::QUIT)
        tip = Gtk::Tooltips.new
        tip.set_tip(newtb,NEW,nil)
        tip.set_tip(opentb, OPEN,nil)
        tip.set_tip(savetb,SAVE,nil)
        tip.set_tip(saveastb,SAVE_AS,nil)
        tip.set_tip(cuttb, CUT,nil)
        tip.set_tip(copytb,COPY,nil)
        tip.set_tip(pastetb,PASTE,nil)
        tip.set_tip(view_but, VIEW_MAN_FILE,nil)
        toolbar.insert(0, newtb)
        toolbar.insert(1, opentb)
        toolbar.insert(2, savetb)
        toolbar.insert(3,saveastb)
	toolbar.insert(4, cuttb)
	toolbar.insert(5, copytb)
	toolbar.insert(6, pastetb)
        toolbar.insert(7,view_but)
        toolbar.insert(8, sep)
        toolbar.insert(9, quittb)
	view_but.set_sensitive false       
        # view_but sensitive
        @buf.signal_connect("changed"){o=Utils.new; o.buf_changed(@buf,view_but)}
	opentb.signal_connect("clicked"){o = Utils.new; o.open_file(@win,@editor)}
        saveastb.signal_connect("clicked"){o = Utils.new; o.save_as(@win,@editor,"save_as")}
	savetb.signal_connect("clicked"){o= Utils.new; o.save(@win,@editor,"")}
	cuttb.signal_connect("clicked"){o = Utils.new; o.on_cuttb(@editor)}
	copytb.signal_connect("clicked"){o = Utils.new; o.on_copytb(@editor)}
	pastetb.signal_connect("clicked"){o= Utils.new; o.on_pastetb(@editor)}
	newtb.signal_connect("clicked"){o= Utils.new; o.open_new_empty_file(@win,@editor)}
        view_but.signal_connect("clicked"){o = Utils.new; o.preview(@win,@editor,@manview)}
	quittb.signal_connect("clicked"){Gtk.main_quit}
	@vbox.pack_start(toolbar,false,false,0)
        toolBarFont
	@win.add(@vbox)
  end
  
  def toolBarFont
      tbFont = Gtk::Toolbar.new
      t1 = Gtk::Tooltips.new
      tbFont.set_toolbar_style(Gtk::Toolbar::Style::ICONS)
      italik = Gtk::ToolButton.new(Gtk::Stock::ITALIC)
      bold = Gtk::ToolButton.new(Gtk::Stock::BOLD)
      indent = Gtk::ToolButton.new(Gtk::Stock::INDENT)
      justify_left = Gtk::ToolButton.new(Gtk::Stock::JUSTIFY_LEFT)
      br = Gtk::ToolButton.new(Gtk::Stock::JUMP_TO)
      paragraph = Gtk::ToolButton.new(Gtk::Image.new("images/paragraph.png"))
      comment_line = Gtk::ToolButton.new(Gtk::Image.new("images/comment_line.png"))
      set_coloumn = Gtk::ToolButton.new(Gtk::Image.new("images/coloumns.png"))
      start_indent_paragraph = Gtk::ToolButton.new(Gtk::Image.new("images/paragraph_indent.png"))
      nofill = Gtk::ToolButton.new(Gtk::Image.new("images/nf.png"))
      fill = Gtk::ToolButton.new(Gtk::Image.new("images/fi.png"))
      hp = Gtk::ToolButton.new(Gtk::Image.new("images/hp.png"))
      subhead = Gtk::ToolButton.new(Gtk::Image.new("images/subhead.png"))
      italik.set_size_request(50,40)
      bold.set_size_request(50,40)
      indent.set_size_request(50,40)
      justify_left.set_size_request(50,40)
      br.set_size_request(50,40)
      paragraph.set_size_request(50,40)
      comment_line.set_size_request(50,40)
      set_coloumn.set_size_request(50,40)
      start_indent_paragraph.set_size_request(50,40)
      nofill.set_size_request(50,40)
      fill.set_size_request(50,40)
      hp.set_size_request(50,40)
      subhead.set_size_request(50,40)
      t1.set_tip(italik,ITALIK,nil)
      t1.set_tip(bold,BOLD,nil)
      t1.set_tip(indent,INDENT,nil)
      t1.set_tip(justify_left,JUSTIFY_LEFT,nil)
      t1.set_tip(br,BR,nil)
      t1.set_tip(paragraph,PARAGRAPH,nil)
      t1.set_tip(comment_line,COMMENT_LINE,nil)
      t1.set_tip(set_coloumn,SET_COLOUMN,nil)
      t1.set_tip(start_indent_paragraph,START_INDENT_PARAGRAPH,nil)
      t1.set_tip(nofill,NOFILL,nil)
      t1.set_tip(fill,FILL,nil)
      t1.set_tip(hp,HP,nil)
      t1.set_tip(subhead,SUBHEAD,nil)
      tbFont.insert(0,italik)
      tbFont.insert(1,bold)
      tbFont.insert(2,indent)
      tbFont.insert(3,justify_left)
      tbFont.insert(4,br)
      tbFont.insert(5,paragraph)
      tbFont.insert(6,comment_line)
      tbFont.insert(7,set_coloumn)
      tbFont.insert(8,start_indent_paragraph)
      tbFont.insert(9,nofill)
      tbFont.insert(10,fill)
      tbFont.insert(11,hp)
      tbFont.insert(12,subhead)
      italik.signal_connect("clicked"){@buf.insert_at_cursor(".I ")}
      bold.signal_connect("clicked"){@buf.insert_at_cursor(".B ")}
      indent.signal_connect("clicked"){@buf.insert_at_cursor(".RE ")}
      justify_left.signal_connect("clicked"){@buf.insert_at_cursor(".SH ")}
      br.signal_connect("clicked"){@buf.insert_at_cursor(".br\n")}
      paragraph.signal_connect("clicked"){@buf.insert_at_cursor(".P ")}
      comment_line.signal_connect("clicked"){@buf.insert_at_cursor(".\\\" ")}
      set_coloumn.signal_connect("clicked"){@buf.insert_at_cursor(".TP\n")}
      start_indent_paragraph.signal_connect("clicked"){@buf.insert_at_cursor(".IP ")}
      nofill.signal_connect("clicked"){@buf.insert_at_cursor(".nf ")}
      fill.signal_connect("clicked"){@buf.insert_at_cursor(".fi ")}
      hp.signal_connect("clicked"){@buf.insert_at_cursor(".HP ")}
      subhead.signal_connect("clicked"){@buf.insert_at_cursor(".SS ")}
      @vbox.pack_start(tbFont,false,false,0)
  end
end

app = Editor.new
Gtk.main
