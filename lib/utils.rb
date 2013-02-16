#encoding: UTF-8
require 'filemagic'
require 'zlib'
require 'zip/zip'
require 'gettext'
require 'rubygems'
require 'gtk2'
require 'tempfile'
require 'webkit'

class Utils
  include GetText 
  bindtextdomain("rmanedit")
  @@filename = ""
  @@saved = true
  
  def lang_choice(win,lang)
      if not @@saved
        dialog = Gtk::MessageDialog.new(win, Gtk::Dialog::MODAL,
        Gtk::MessageDialog::QUESTION,Gtk::MessageDialog::BUTTONS_YES_NO,
        _("Your changes will be lost because of RManEdit will start"))
        if dialog.run == Gtk::Dialog::RESPONSE_YES
          dialog.destroy
          f = File.open("/home/#{ENV["USER"]}/.config/rmanedit/lang.rb","w")
          f.write("LANGUAGE=\"#{lang}\"")
          f.close
          IO.popen("rmanedit")
          Gtk.main_quit
        else
          dialog.destroy
        end
      else 
          f = File.open("/home/#{ENV["USER"]}/.config/rmanedit/lang.rb","w")
          f.write("LANGUAGE=\"#{lang}\"")
          f.close
          IO.popen("rmanedit")
          Gtk.main_quit 
      end
  end

  def save_as(win,editor,temp)
      save(win,editor,temp)   
  end

  def save(win,editor,temp)
      if temp == "save_as"
        temp = @@filename
        @@filename = ""
      end
      # daha once hic kaydedilmemis
      if @@filename == ""
          dialog = Gtk::FileChooserDialog.new(_("Save"), win, Gtk::FileChooser::ACTION_SAVE, nil,
          [Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_CANCEL],
          [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY ])
          dialog.set_do_overwrite_confirmation(true)
          dialog.show_all()
          if dialog.run  == Gtk::Dialog::RESPONSE_APPLY
            # dosyanin tam yolu
            @@filename = dialog.filename
            content = editor.buffer.text
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
            relative_filename = @@filename.split('/')
            relative_filename = relative_filename[relative_filename.length-1]
            win.set_title(relative_filename+ " ~ RManEdit")
            msg.show_all()
            if msg.run == Gtk::Dialog::RESPONSE_OK
              msg.destroy
              dialog.destroy
            end
          else
            if temp != ""
              @@filename = temp
            end
            dialog.destroy
          end
          @@saved = true
      elsif @@saved
          return
      else
        content = editor.buffer.text
        File.open(@@filename, 'w') do |f|
        gz = Zlib::GzipWriter.new(f)
        gz.write(content)
        gz.close
        end
        @@saved = true
      end
  end
 
  def open_new_empty_file(win,editor) 
      if not @@saved
          which_func = "open_new_empty_file"
          will_change_lost(win,editor,which_func)
     else
        editor.buffer.text = ""
        @@saved = true
        @@filename = ""
        win.set_title("RManEdit")
    end
  end

  # kaydedilmis bir dosyayi acma
  def open_file(win,editor) 
      if not @@saved
          which_func = "open_file"
          will_change_lost(win,editor,which_func)
      else
          open_new_file(win,editor)
          # kaydedilmis dosya acilinca buf degisir 
          # buf tekrar true oldu
          @@saved = true
      end
  end 
  
  # dosya acikken yeni dosya acma icin dialog
  def will_change_lost(win,editor,which_func)
      dialog = Gtk::MessageDialog.new(win, Gtk::Dialog::MODAL,
      Gtk::MessageDialog::QUESTION,Gtk::MessageDialog::BUTTONS_YES_NO,
      _("Your changes will be lost. Do you want to continue?"))
     if dialog.run == Gtk::Dialog::RESPONSE_YES
          dialog.destroy
          @@filename = ""
          win.set_title("RManEdit")
          editor.buffer.text = ""
          @@saved = true
          if which_func == "open_file"
              open_new_file(win,editor)
              # kayitli dosya acilinca bu degisir
              # saved tekrar true olmasi gerekir
              @@saved = true
          end
     else
         dialog.destroy
     end   
  end 

  def buf_changed(buf,view_but,treeview,renderer)
     @@saved = false
     if buf.text == ""
         view_but.set_sensitive(false)
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
  
  def preview(win,editor,manview)
      if @@filename == "" or @@saved == false
        msg = Gtk::MessageDialog.new(nil, Gtk::Dialog::DESTROY_WITH_PARENT, 
        Gtk::MessageDialog::INFO, Gtk::MessageDialog::BUTTONS_OK,
        _("If you want to view file, you must save it"))
        msg.show_all()
        if msg.run == Gtk::Dialog::RESPONSE_OK 
            msg.destroy
        end
        return
      end
      # dosya kayitli ise
      content = editor.buffer.text
      file = Tempfile.new('foo')
      file.write(content)
      file.rewind
      file.read
      fm = FileMagic.new
      if fm.file(file.path).scan(/troff/i).length == 0
        msg = Gtk::MessageDialog.new(nil, Gtk::Dialog::DESTROY_WITH_PARENT,
        Gtk::MessageDialog::INFO, Gtk::MessageDialog::BUTTONS_OK, _("It is not a man file"))
        msg.show_all()
        if msg.run == Gtk::Dialog::RESPONSE_OK
            file.close
            file.unlink
            msg.destroy
        end
        return
      end
      output = IO.popen("man2html #{file.path}")
      str = output.readlines
      i = 5
      content = str[1]+str[2]+str[3]
      content += "<meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\"></HEAD><BODY>"
      while i< str.length do
          content = content + str[i]
          i = i + 1
      end
      manview.load_string(content,"text/html", "UTF-8", "file://home")   
      file.close
      file.unlink 
  end

  def open_new_file(win,editor)
        dialog = Gtk::FileChooserDialog.new(_("Open"), win, Gtk::FileChooser::ACTION_OPEN, nil, 
        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
        [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
        dialog.show
        begin
          if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
            @@saved = true
            file = dialog.filename
            @@filename = file
            relative_filename = @@filename.split('/')
            relative_filename = relative_filename[relative_filename.length-1]
            fm = FileMagic.new
            # gzip dosyasi
            if fm.file(file).scan(/gziP/i).length != 0
      	      gz = Zlib::GzipReader.new(open(file)).read 
              editor.buffer.text = gz
              win.set_title(relative_filename+ " ~ RManEdit")
            # zip dosyasi
       	    elsif fm.file(file).scan(/zip/i).length != 0
              win.set_title(relative_filename+ " ~ RManEdit")
       	      Zip::ZipFile.open(file) do |zip_file|
       	      zip_file.each do |f|
              editor.buffer.text = zip_file.read(f)
                end
              end
            # herhangi bir text
      	    else
              win.set_title(relative_filename+ " ~ RManEdit")
              content = ""
              IO.foreach(file){|block|  content = content + "\n"+ block}
              editor.buffer.text = content
            end
              dialog.destroy         
         else
           dialog.destroy
         end
       rescue
         msg = Gtk::MessageDialog.new(nil, Gtk::Dialog::DESTROY_WITH_PARENT,
         Gtk::MessageDialog::INFO, Gtk::MessageDialog::BUTTONS_OK, _("Please select a man file to open"))
         msg.show_all()
         if msg.run == Gtk::Dialog::RESPONSE_OK
           msg.destroy
           dialog.destroy
         end
       end
  end

  # secilen etikete gitme 
  def label_find(find,editor)
      start = editor.buffer.start_iter
      first, last = start.forward_search(find, Gtk::TextIter::SEARCH_TEXT_ONLY, nil)
      if (first)    
          mark = editor.buffer.create_mark(nil, first, false)
          editor.scroll_mark_onscreen(mark)
      #    editor.buffer.delete_mark(mark)
          editor.buffer.select_range(first, last)
      else
          dialogue = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL, Gtk::MessageDialog::INFO, 
          Gtk::MessageDialog::BUTTONS_OK, _("No such tag"))
         dialogue.run
         dialogue.destroy
      end
      first = last = nil
  end
  
  # html dosyasina donusturme  
  def create_html_file(editor,win)
      dialog = Gtk::FileChooserDialog.new(_("Save"), win, Gtk::FileChooser::ACTION_SAVE, nil,
      [Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_CANCEL],
      [ Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY ])
      dialog.show_all() 
      if dialog.run  == Gtk::Dialog::RESPONSE_APPLY
          file = dialog.filename
          # yandaki textin bir dosya icine atilmasi
          content = editor.buffer.text
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

end

class TextManiplation

  def cut_text(editor)
      clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      editor.buffer.cut_clipboard(clipboard, true)
  end

  def copy_text(editor)
      clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      editor.buffer.copy_clipboard(clipboard)
  end
  
  def paste_text(editor)
      clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      editor.buffer.paste_clipboard(clipboard, nil, true)
  end
 
  def find_text(editor)
  editor.buffer.create_tag("highlight", {"background" => "#f8d60d", "foreground" => "red"})
  start = editor.buffer.start_iter
  first, last = start.forward_search("text", Gtk::TextIter::SEARCH_TEXT_ONLY, nil)
  count = 0
  while (first)
    start.forward_char
    first, last = start.forward_search("text", Gtk::TextIter::SEARCH_TEXT_ONLY, nil)
    start = first
    editor.buffer.apply_tag("highlight", first, last)
    count += 1
  end
  end

end
