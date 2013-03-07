#encoding: UTF-8
require 'filemagic'
require 'zlib'
require 'zip/zip'
require 'gettext'
require 'rubygems'
require 'gtk2'
require 'tempfile'
require 'webkit'
require 'textView'
require 'add_remove_tab'

class Utils
  
  include GetText 
  bindtextdomain("rmanedit")
  
  def text_changed(tab)
    
    current_page = tab.get_nth_page(tab.page)
    # sayfa ismine surekli * ekler bu if olmazsa
    if current_page.child.saved
      old_label = tab.get_tab_label(current_page)
      pagename = "* " + old_label.text
      tab.set_tab_label(current_page,
      Gtk::Label.new(pagename))
    end
    r = defined? @@find 
    if r != nil
      current_page.child.buffer.create_tag("highlight", {"background" => "yellow"})
      start = current_page.child.buffer.start_iter
      iter_end = current_page.child.buffer.end_iter  
      current_page.child.buffer.remove_tag("highlight", start, iter_end) 
      find_text(tab, @@find, @@count_label) 
    end
    current_page.child.saved = false
  end 
 
  def lang_choice(tab,lang)

    f = File.open("/home/#{ENV["USER"]}/.config/rmanedit/lang.rb","w")
    f.write("LANGUAGE=\"#{lang}\"")
    f.close

    msg = Gtk::MessageDialog.new(nil,
    Gtk::Dialog::DESTROY_WITH_PARENT, 
    Gtk::MessageDialog::INFO,
    Gtk::MessageDialog::BUTTONS_OK,
     _("If you restart RManEdit, your settins will implement"))

    if msg.run == Gtk::Dialog::RESPONSE_OK 
      msg.destroy
    end

  end

  def save_as(tab,saveas)

    save(tab,saveas)   
  end

  def save(tab,saveas)
    
    current_page = tab.get_nth_page(tab.page).child
    content = current_page.buffer.text

    if current_page.first_save == false or saveas
      dialog = Gtk::FileChooserDialog.new(_("Save"), nil, 
      Gtk::FileChooser::ACTION_SAVE, nil,
      [Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_CANCEL],
      [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY ])
      dialog.set_do_overwrite_confirmation(true)
      dialog.show_all()
      if dialog.run  == Gtk::Dialog::RESPONSE_APPLY
        # dosyanin tam yolu
        @@filename = dialog.filename
        # ikinci kez yazma için gz uzantisi eklenmesi
        @@filename = @@filename + ".gz"
        File.open(@@filename, 'w') do |f|
        gz = Zlib::GzipWriter.new(f)
        gz.write(content)
        gz.close
        end
        msg = Gtk::MessageDialog.new(dialog,
        Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::INFO,
        Gtk::MessageDialog::BUTTONS_OK, _("Saved"))
        current_page.file_path = @@filename
        filename = @@filename.split('/')
        filename = filename[filename.length-1]
        page = tab.get_nth_page(tab.page)
        tab.set_tab_label(page, Gtk::Label.new(filename))
        msg.show_all()
        if msg.run == Gtk::Dialog::RESPONSE_OK
          msg.destroy
          dialog.destroy
        end
      else
        dialog.destroy 
        return
      end
    else
      file_path = current_page.file_path
      File.open(file_path, 'w') do |f|
      gz = Zlib::GzipWriter.new(f)
      gz.write(content)
      gz.close
      filename = file_path.split('/')
      filename = filename[filename.length-1]
      page = tab.get_nth_page(tab.page)
      tab.set_tab_label(page, Gtk::Label.new(filename))
      end
    end
    current_page.first_save = true
    current_page.saved = true
  end

  def open_new_empty_file(tab, treeview, view_but) 

    o = AddRemoveTab.new
    o.new_tab(tab, treeview, view_but)
  end

  # kayitli bir dosyayi acma
  def open_file(tab, treeview, view_but) 

    o = AddRemoveTab.new
    o.new_tab(tab, treeview, view_but)
    open_new_file(tab)
  end 

  def view_sensitive(text, treeview, view_but)

    if text == ""
      view_but.set_sensitive(false)
      view_but.show_all
      selection = treeview.selection
      iter = selection.selected
      if iter != nil
        selection.unselect_iter(iter)
      end
      treeview.sensitive=false
    else
      view_but.set_sensitive(true)
      treeview.sensitive=true
    end

  end

  def preview(tab, manview)

    current_page = tab.get_nth_page(tab.page).child
    if current_page.saved == false
      msg = Gtk::MessageDialog.new(nil,
      Gtk::Dialog::DESTROY_WITH_PARENT, 
      Gtk::MessageDialog::INFO, 
      Gtk::MessageDialog::BUTTONS_OK,
      _("If you want to view file, you must save it"))
      msg.show_all()
      if msg.run == Gtk::Dialog::RESPONSE_OK 
        msg.destroy
      end
        return
      end
      # dosya kayitli ise
      content = current_page.buffer.text
      file = Tempfile.new('foo')
      file.write(content)
      file.rewind
      file.read
      fm = FileMagic.new      
      output = IO.popen("man2html #{file.path}")
      str = output.readlines
      i = 5
      content = str[1]+str[2]+str[3]
      content += "<meta http-equiv=\"Content-Type\"" 
      content += "content=\"text/html;charset=UTF-8\"></HEAD><BODY>"
      while i< str.length do
          content = content + str[i]
          i = i + 1
      end
      manview.load_string(content,"text/html", "UTF-8", "file://home")   
      file.close
      file.unlink 
  end

  def open_new_file(tab)

    dialog = Gtk::FileChooserDialog.new(_("Open"), nil, 
    Gtk::FileChooser::ACTION_OPEN, nil, 
    [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
    [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
    dialog.show
    begin
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        new_page = tab.get_nth_page(tab.n_pages-1).child
        new_page.saved = true
        @@filename = dialog.filename
        fm = FileMagic.new
        # gzip dosyasi
        if fm.file(@@filename).scan(/gziP/i).length != 0
          gz = Zlib::GzipReader.new(open(@@filename)).read 
          new_page.buffer.text = gz
        # zip dosyasi
        elsif fm.file(@@filename).scan(/zip/i).length != 0
       	  Zip::ZipFile.open(@@filename) do |zip_file|
       	  zip_file.each do |f|
          new_page.buffer.text = zip_file.read(f)
            end
          end
        # herhangi bir text
        elsif fm.file(@@filename).scan(/text/i).length != 0
          content = ""
          IO.foreach(@@filename){|block|  content = content + "\n"+ block}
          new_page.buffer.text = content
       else
         msg = Gtk::MessageDialog.new(nil,
         Gtk::Dialog::DESTROY_WITH_PARENT,
         Gtk::MessageDialog::INFO, Gtk::MessageDialog::BUTTONS_OK,
         _("If the file is not text, you can't open"))
         msg.show_all()
         if msg.run == Gtk::Dialog::RESPONSE_OK
             tab.remove_page(tab.n_pages-1)
             msg.destroy
             dialog.destroy
             return 
         end
       end
      new_page.file_path = @@filename
      # sekme isminin acik olan dosyanin adini almasi
      filename = @@filename.split('/')
      filename = filename[filename.length-1]
      page = tab.get_nth_page(tab.n_pages-1)
      tab.set_tab_label(page, Gtk::Label.new(filename))
      page.child.first_save = true
    else 
      tab.remove_page(tab.n_pages-1)
    end
    dialog.destroy
    rescue
      msg = Gtk::MessageDialog.new(nil,
      Gtk::Dialog::DESTROY_WITH_PARENT,
      Gtk::MessageDialog::INFO, 
      Gtk::MessageDialog::BUTTONS_OK, 
      _("Please select a man file to open"))
      msg.show_all()
      if msg.run == Gtk::Dialog::RESPONSE_OK
        msg.destroy
        dialog.destroy
        open_new_file(tab)
      end
    end
  end

  # secilen etikete gitme 
  def label_find(find, tab)

    current_page = tab.get_nth_page(tab.page).child
    start = current_page.buffer.start_iter
    first, last = start.forward_search(find, 
    Gtk::TextIter::SEARCH_TEXT_ONLY, nil)
    if (first)    
      mark = current_page.buffer.create_mark(nil, first, false)
      current_page.scroll_mark_onscreen(mark)
      current_page.buffer.delete_mark(mark)
      current_page.buffer.select_range(first, last)
    else
      dialogue = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL, 
      Gtk::MessageDialog::INFO, 
      Gtk::MessageDialog::BUTTONS_OK, _("No such tag"))
      dialogue.run
      dialogue.destroy
    end
    while first
      start.forward_char
      first, last = start.forward_search(find, Gtk::TextIter::SEARCH_TEXT_ONLY, nil)
      start = first
      mark = current_page.buffer.create_mark(nil, first, false)
      current_page.scroll_mark_onscreen(mark)
      current_page.buffer.delete_mark(mark)
      current_page.buffer.select_range(first, last)
    end
     first = last = nil
  end
  
  # html dosyasina donusturme  
  def create_html_file(tab)

    dialog = Gtk::FileChooserDialog.new(_("Save"), nil,
    Gtk::FileChooser::ACTION_SAVE, nil,
    [Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_CANCEL],
    [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY])
    dialog.show_all() 
    if dialog.run  == Gtk::Dialog::RESPONSE_APPLY
      file = dialog.filename
      # yandaki textin bir dosya icine atilmasi
      current_page = tab.get_nth_page(tab.page).child
      content = current_page.buffer.text
      File.open(file, "w") { |f| f <<  content }
      # ayni textin htmlye donusturulmesi
      fm = FileMagic.new
      if fm.file(file).scan(/troff/i).length == 0
        File.delete(file)
        msg = Gtk::MessageDialog.new(dialog,
        Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::INFO,
        Gtk::MessageDialog::BUTTONS_OK, _("It is not a man file"))
        msg.show_all()
        if msg.run == Gtk::Dialog::RESPONSE_OK
          msg.destroy
          dialog.destroy
          return
        end
      end
      output = IO.popen("man2html #{file}")
      str = output.readlines
      i = 5
      content = str[1]+str[2]+str[3]+"<meta http-equiv=\"Content-Type\" 
      content=\"text/html;charset=UTF-8\"></HEAD><BODY>"
      while i< str.length do
        content = content + str[i]
        i = i + 1
      end
      File.open(file, "w") { |f| f <<  content }
      msg = Gtk::MessageDialog.new(dialog,
      Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::INFO,
      Gtk::MessageDialog::BUTTONS_OK, _("Saved"))
      msg.show_all()
      if msg.run == Gtk::Dialog::RESPONSE_OK
        msg.destroy
        dialog.destroy
      end
      else
          dialog.destroy
      end
  end

  def app_about

    w = Gtk::Window.new
    layout = Gtk::Layout.new
    info = Gtk::Label.new(_("""
    RManEdit licence is Creative Commons.
    Written by Ebru Akagündüz"))
    b = Gtk::Button.new
    l = Gtk::Label.new(_("OK"))
    w.set_title(_("About RManEdit"))
    w.set_default_size(330,300)
    w.window_position = Gtk::Window::POS_CENTER
    b.add(l)
    layout.put(info,10,30)
    layout.put(b,250,240) 
    w.add(layout)
    w.show_all
    b.signal_connect("clicked"){w.destroy}
  end

  def help

    w = Gtk::Window.new
    layout = Gtk::Layout.new    
    btn = Gtk::Button.new(_("OK"))
    font = Pango::FontDescription.new("Sans Bold 10")
    w.set_title(_("Help"))
    w.set_size_request(750,400)
    w.window_position = Gtk::Window::POS_CENTER_ALWAYS
    help_content = _("""
    RManEdit
    RmanEdit is a editor for man page preparing. Specified tags like italic, bold, indetion 
    is used for man pages. RmanEdit facilitates to use the tags and you can make
    man pages quickly.

    First feature which make man pages quickly are icons at menu bar. There are buttons 
    that includes tags like paragraph, indentation, italic, bold etc. in menu bar at downside. 
    Description of icons appear when you move on buttons your mouse cursor.

    There is a section on right of program interface. In this section, you can view your 
    aplication. You can write man pages on middle section. There are tags on left section.
    Cursor is moves when you click tags like NAME, SYNOPSIS on left section.
 
    At menu bar File->Convert to html file converts to html file your man file.""")
    l = Gtk::Label.new(help_content)
    l.modify_font(font)
    layout.put(l,10,30)
    layout.put(btn,600,350)
    w.add(layout)
    btn.signal_connect("clicked"){w.destroy}
    w.show_all
  end

  def cut_text(tab)

    current_page = tab.get_nth_page(tab.page).child
    clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
    current_page.buffer.cut_clipboard(clipboard, true)
  end

  def copy_text(tab)

    current_page = tab.get_nth_page(tab.page).child
    clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
    current_page.buffer.copy_clipboard(clipboard)
  end
  
  def paste_text(tab)

    current_page = tab.get_nth_page(tab.page).child
    clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
    current_page.buffer.paste_clipboard(clipboard, nil, true)
  end
 
  def find_text(tab, find, count_label)

    count = 0
    current_page = tab.get_nth_page(tab.page).child
    start = current_page.buffer.start_iter
    first, last = start.forward_search(find.text, Gtk::TextIter::SEARCH_TEXT_ONLY, nil)
    current_page.buffer.create_tag("highlight", {"background" => "yellow"})
    while (first)
      current_page.buffer.apply_tag("highlight", first, last)
      start.forward_char
      first, last = start.forward_search(find.text, Gtk::TextIter::SEARCH_TEXT_ONLY, nil)
      start = first
      count += 1 
    end
    count_label.label = count.to_s
    # removed
    # if count_label.label == "0"      
    # find.modify_base(Gtk::STATE_NORMAL, Gdk::Color.parse("red"))    
    # find.show_all
    # end
    @@find = find
    @@count_label = count_label
  end
   
  def replace_text(tab, replace, find)
    current_page = tab.get_nth_page(tab.page).child
    content = current_page.buffer.text
    content = content.gsub(find.text, replace.text)
    current_page.buffer.text = content
  end  

end

