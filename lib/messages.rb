#encoding: UTF-8
require 'gettext'
require 'rubygems'
require 'lang'
include GetText
bindtextdomain("messages", :path => "locale")
GetText.set_locale_all(LANGUAGE)
CATEGORY = _("Bölümler")
FILE = _("Dosya")
NO_MAN_FILE = _("Yüklenmiş man dosyası yok")
OPEN = _("Aç")
NEW = _("Yeni")
SAVE = _("Kaydet")
SAVE_AS = _("Farklı Kaydet")
CUT = _("Kes")
COPY = _("Kopyala")
SAVED = _("Kaydedildi")
VIEW_MAN_FILE = _("Man Dosyasını Görüntüle")
CHANGE_WILL_LOST = _("Değişiklikleriniz kaybedilecek. Devam etmek istiyor musunuz?")
CREATE_HTML_FILE = _("Html dosyasına dönüştür")
NO_LABEL = _("Bu etiketi girmemişsiniz.")
EXIT = _("Çıkış")
PASTE = _("Yapıştır")
UNSAVED = _("Görüntülemek için dosyayı kaydetmeniz gerekir")
ITALIK = _("İtalik\n .I")
BOLD = _("Koyu\n .B")
INDENT = _("Girinti\n .RE")
JUSTIFY_LEFT = _("Bölüm başlığı ve sola dayalı yazma\n .SH")
BR = _("Alt satıra geç\n .br")
PARAGRAPH = _("Paragraf\n .P")
COMMENT_LINE = _("Yorum satiri\n .\\\" ")
SET_COLOUMN = _("Sütunlu yaz\n .TP" )
START_INDENT_PARAGRAPH = _("Paragrafa girinti ile başla\n .IP")
NOFILL = _("Nofill\n .nf")
FILL = _("Fill\n .fi")
HP = _("Satırdan sonraki ilk girinti\n .HP")
SUBHEAD = _("Alt başlık \n .SS")
CREATE_MAN_FILE_ERROR = _("Html dosyasına dönüştürülmek istenen dosya bir man dosyası değil")
OPEN_MAN_FILE_ERROR = _("Lütfen açmak için bir man dosyası seçiniz")
PREVIEW_MAN_FILE = _("Görüntülemek istediğiniz dosyanız henüz man dosyası formatında değil")
SETTINGS = _("Ayarlar")
LANGUAGES = _("Dil Seçenekleri")
ENGLISH = _("İngilizce")
TURKISH = _("Türkçe")
GERMAN = _("Almanca")
RESTART = _("RManEdit yeniden başlatılacağı için değişiklikleriniz kaybedilecek.")
ABOUT = _("Hakkında")
APP_ABOUT = _("RManEdit Hakkında Açıklamalar")
APP_INFO = _("RManEdit Creative Commons ile lisanlanmıştır.\nRManEdit yazarı: Ebru Akagündüz")
OK = _("Tamam")
HELP = _("Yardım")
HELP_CONTENT = _("<!DOCTYPE html><html><head><h3>RManEdit</h3>
 Man sayfaları hazırlamak için bir metin editörüdür. Man sayfaları hazırlanırken koyu, italik, girintili yazma için belirli etiketler kullanılır. RManEdit ise bu etiketlerin kullanımı kolaylaştırıp, man sayfalarını daha hızlı bir şekilde hazırlamanızı sağlar.</head><br><body>
</ul>
<li>Çabuk bir şekilde man sayfası hazırlamayı sağlayan ilk özellik menü çubuğundaki simgelerdir. Alttaki menü çubuğunda italik, koyu, girinti, paragraf gibi etiketleri  içeren butonlar vardır. Bilgisayarınızın faresiyle bu simgelerin üzerine geldiğinizde açıklaması yazmaktadır.<br><p></li>
<li><B>RManEdit</B> programında en sağ kısımda yazdığınız uygulamayı görüntülemeniz için bölüm vardır. Orta kısım man sayfalarının yazılacağı kısımdır. Sol kısımdaki etiketlere tıkladığınızda ise imleç man sayfanızdaki <b>NAME, SYNOPSIS</b> gibi alanlara gider.<p></li>
<li>Menü çubuğunda <I>Dosya-> Html dosyasına dönüştür</I> kısmı kaydettiğiniz man dosyasını dosyasını html dosyasına çevirir.</li></ul></body>
</html>")
