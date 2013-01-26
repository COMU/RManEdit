#encoding: UTF-8
require 'gettext'
require 'rubygems'
include GetText
bindtextdomain("messages", :path => "locale")
GetText.set_locale_all("en")
CATEGORY = _("Bölümler")
FILE = _("Dosya")
OPEN = _("Aç")
NEW = _("Yeni")
SAVE = _("Kaydet")
SAVE_AS = _("Farklı Kaydet")
CREATE_HTML_FILE = _("Html dosyasına dönüştür")
EXIT = _("Çıkış")




