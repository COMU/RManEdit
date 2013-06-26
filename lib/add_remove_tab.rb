#encoding: UTF-8
"""
Copyright (C) 2013 - Ebru Akagündüz <ebru.akagunduz@gmail.com>

This file is part of RManEdit.

RManEdit is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

RManEdit is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>

"""

require 'gtk2'
require 'gettext'
require 'utils'
require 'textView'

class AddRemoveTab

  include GetText
  bindtextdomain("rmanedit")

  def new_tab(tab, treeview, view_but, empty_file)
    time = Time.now
    editor = Textview.new
    swin = Gtk::ScrolledWindow.new
    if tab.n_pages != 0
      pagenum = tab_name(tab).to_s
    else
      pagenum = 1.to_s
    end
    swin.add(editor)
    tab.append_page(swin,
    Gtk::Label.new("Untitled Document " + pagenum)) 
    if empty_file
       editor.buffer.text = ".\\\" DO NOT MODIFY THIS FILE!\n .TH \"your_command_name\" \"#{time.strftime("%B")} #{time.year}\" \"your_description\""
    end
    tab.signal_connect("switch-page") do |a, b, current_page|
      buf = tab.get_nth_page(current_page).child.buffer
#      buf.text = ".\\\" DO NOT MODIFY THIS FILE!\n .TH \"your_command_name\" \"#{time.strftime("%B")} #{time.year}\" \"your_description\""
      buf.signal_connect("changed"){o=Utils.new;
      o.text_changed(tab);
      # sayfa degisip textin degisme durumu
      o.view_sensitive(buf.text, treeview, view_but)}
      # sadece sayfa degisme durumu
      o=Utils.new;
      o.view_sensitive(buf.text, treeview, view_but)
    end
 end
 
  def remove_tab(tab)
    # kaldirilmak istenen sayfa kayitli mi
    if tab.get_nth_page(tab.page).child.saved
      tab.remove_page(tab.page)
      return
    end
    dialog = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL,
    Gtk::MessageDialog::QUESTION,
    Gtk::MessageDialog::BUTTONS_YES_NO,
    _("Your changes will be lost. Do you want to continue?"))
    if dialog.run == Gtk::Dialog::RESPONSE_YES
      tab.remove_page(tab.page)
    end
    dialog.destroy
  end
  

  def tab_name(tab)
    i = 0
    arr = Array.new
    pagenum = tab.n_pages
    while i < pagenum
      # child page
      page = tab.get_nth_page(i)
      label = tab.get_tab_label(page).text
      arr.push(label)
       i += 1
    end
    i = 1
    while i <= pagenum + 1
      if arr.index("Untitled Document "+i.to_s) == nil and
      arr.index("* Untitled Document "+i.to_s) == nil
        return i
      end
      i += 1
    end
 end
end
