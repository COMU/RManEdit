#encoding: UTF-8
require 'gettext'
require 'rubygems'
include GetText
bindtextdomain("messages", :path => "locale")
GetText.set_locale_all("en")
CATEGORY = _("Bölümler")
FILE = _("Dosya")
NO_MAN_FILE = _("Yüklenmiş man dosyası yok")
OPEN = _("Aç")
NEW = _("Yeni")
SAVE = _("Kaydet")
SAVE_AS = _("Farklı Kaydet")
SAVED = _("Kaydedildi")
CHANGE_WILL_LOST = _("Tüm değişiklikler kaybedilecek. Devam etmek istiyor musunuz?")
CREATE_HTML_FILE = _("Html dosyasına dönüştür")
NO_LABEL = _("Bu etiketi girmemişsiniz.")
EXIT = _("Çıkış")




