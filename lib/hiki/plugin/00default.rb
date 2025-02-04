# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

#==============================
#  tDiary plugins for Hiki
#==============================
def anchor(s)
  s.sub!(/^\d+$/, "")
  p = h(escape(@page))
  p.gsub!(/%/, "%%")
  %Q[#{@conf.cgi_name}?#{p}#{s}]
end

def my(a, str)
  %Q[<a href="#{anchor(a).gsub!(/%%/, '%')}">#{h(str)}</a>]
end

#==============================
#  Hiki default plugins
#==============================
#===== hiki_url
def hiki_url(page)
  "#{@conf.cgi_name}?#{escape(page)}"
end

#===== hiki_anchor
def hiki_anchor(page, display_text)
  if page == "FrontPage" then
    make_anchor(@conf.cgi_name, display_text)
  else
    make_anchor("#{@conf.cgi_name}?#{page}", display_text)
  end
end

#===== make_anchor
def make_anchor(url, display_text, a_class = nil)
  if a_class
    %Q!<a href="#{url}" class="#{a_class}">#{display_text}</a>!
  else
    %Q!<a href="#{url}">#{display_text}</a>!
  end
end

#===== page_name
def page_name(page)
  pg_title = @db.get_attribute(page, :title)
  h((pg_title && pg_title.size > 0) ? pg_title : page)
end

#===== toc
def toc
  @toc_f = :top
  ""
end

def toc_here(page = nil)
  if page
    tokens = @db.load_cache(page)
    unless tokens
      parser = @conf.parser.new(@conf)
      tokens = parser.parse(@db.load(page))
      @db.save_cache(page, tokens)
    end
    formatter = @conf.formatter.new(tokens, @db, Plugin.new(@conf.options, @conf), @conf)
    formatter.to_s
    formatter.toc.gsub(/<a href="/, "<a href=\"#{hiki_url(page)}")
  else
    @toc_f ||= :here
    TOC_STRING
  end
end

#===== recent
def recent(n = 20)
  n = n > 0 ? n : 0

  l = @db.page_info.sort do |a, b|
    b[b.keys[0]][:last_modified] <=> a[a.keys[0]][:last_modified]
  end

  s = ""
  c = 0
  ddd = nil

  l.each do |a|
    break if (c += 1) > n
    name = a.keys[0]
    p = a[name]

    tm = p[:last_modified ]
    cur_date = tm.strftime(@conf.msg_date_format)

    if ddd != cur_date
      s << "</ul>\n" if ddd
      s << "<h5>#{cur_date}</h5>\n<ul>\n"
      ddd = cur_date
    end
    t = page_name(name)
    an = hiki_anchor(escape(name), t)
    s << "<li>#{an}</li>\n"
  end
  s << "</ul>\n"
  s
end

#===== br
def br(n = 1)
  "<br>" * n.to_i
end

#===== update_proc
add_update_proc {
  updating_mail if @conf.mail_on_update
  if @user
    @conf.repos.commit(@page, escape(@user))
  else
    @conf.repos.commit(@page)
  end
}

#----- send a mail on updating
def updating_mail
  begin
    latest_text = @db.load(@page) || ""
    type = (!@db.text or @db.text.size == 0) ? "create" : "update"
    text = ""
    text  = "#{@db.text}\n#{'-' * 25}\n" if type == "update"
    text << "#{latest_text}\n"

    send_updating_mail(@page, type, text)
  rescue
  end
end

#===== delete_proc
add_delete_proc {
  @conf.repos.delete(@page)
}

#===== hiki_header
add_header_proc {
  hiki_header
}

def hiki_header
  return "<title>#{title}</title>\n" if @conf.mobile_agent?
  s = <<EOS
  <meta http-equiv="Content-Language" content="#{@conf.lang}">
  <meta http-equiv="Content-Type" content="text/html; charset=#{@conf.charset}">
  <meta http-equiv="Content-Script-Type" content="text/javascript; charset=#{@conf.charset}">
  <meta http-equiv="Content-Style-Type" content="text/css">
  <meta name="generator" content="#{@conf.generator}">
  <title>#{title}</title>
  <link rel="stylesheet" type="text/css" href="#{h(base_css_url)}" media="all">
  <link rel="stylesheet" type="text/css" href="#{h(theme_url)}" media="all">
EOS
  s << <<EOS if @command != "view"
  <meta name="ROBOTS" content="NOINDEX,NOFOLLOW">
  <meta http-equiv="pragma" content="no-cache">
  <meta http-equiv="cache-control" content="no-cache">
  <meta http-equiv="expires" content="0">
EOS
  s
end

#===== hiki_footer
add_footer_proc {
  hiki_footer
}

def hiki_footer
  s = %Q|Generated by <a href="http://hikiwiki.org/">Hiki</a> #{::Hiki::VERSION} (#{::Hiki::RELEASE_DATE}).<br>\nPowered by <a href="http://www.ruby-lang.org/">Ruby</a> #{RUBY_VERSION}|
  s << %Q|-p#{RUBY_PATCHLEVEL}| if RUBY_PATCHLEVEL > 0 rescue nil
  s << %Q| (#{RUBY_RELEASE_DATE})|
  if /ruby/i =~ ENV["GATEWAY_INTERFACE"]
    s << ' with <a href="http://www.modruby.net/">mod_ruby</a>'
  elsif defined?(FCGI)
    s << ' with <a href="http://raa.ruby-lang.org/project/fcgi/">ruby-fcgi</a>'
  end
  s << %Q|.<br>\nFounded by #{h(@conf.author_name)}.<br>\n|
end

#===== edit_proc
add_edit_proc {
  hiki_anchor(escape(@page), "[#{page_name(@page)}]")
}

#===== menu
def create_menu(data, command)
  menu = []

  if @conf.bot?
    menu << %Q!<a href="#{@conf.cgi_name}?c=index">#{@conf.msg_index}</a>!
  else
    menu << %Q!<a href="#{@conf.cgi_name}?c=create" rel="nofollow">#{@conf.msg_create}</a>! if creatable?
    menu << %Q!<a href="#{@conf.cgi_name}?c=edit;p=#{escape(@page)}" rel="nofollow">#{@conf.msg_edit}</a>! if @page && editable?
    menu << %Q!<a href="#{@conf.cgi_name}?c=diff;p=#{escape(@page)}" rel="nofollow">#{@conf.msg_diff}</a>! if @page && editable?
    menu << %Q!#{hiki_anchor('FrontPage', page_name('FrontPage'))}!
    menu << %Q!<a href="#{@conf.cgi_name}?c=index">#{@conf.msg_index}</a>!
    menu << %Q!<a href="#{@conf.cgi_name}?c=search">#{@conf.msg_search}</a>!
    menu << %Q!<a href="#{@conf.cgi_name}?c=recent">#{@conf.msg_recent_changes}</a>!
    @plugin_menu.each do |c|
      next if c[:option].has_key?("p") && !(@page && editable?)
      cmd =  %Q!<a href="#{@conf.cgi_name}?c=#{c[:command]}!
      c[:option].each do |key, value|
        value = escape(@page) if key == "p"
        cmd << %Q!;#{key}=#{value}!
      end
      cmd << %Q!">#{c[:display_text]}</a>!
      menu << cmd
    end
    menu_proc.each {|i| menu << i}
    menu << %Q!<a href="#{@conf.cgi_name}?c=login#{@page ? ";p=#{escape(@page)}" : ""}">#{@conf.msg_login}</a>! unless @user || @conf.password.empty?
    menu << %Q!<a href="#{@conf.cgi_name}?c=admin">#{@conf.msg_admin}</a>! if admin?
    menu << %Q!<a href="#{@conf.cgi_name}?c=logout">#{@conf.msg_logout}</a>! if @user && !@conf.password.empty?
  end
  menu
end

def hiki_menu(data, command)
  menu = create_menu(data, command)
  if @conf.mobile_agent?
    data[:tools] = menu.join("|")
  else
    data[:tools] = menu.collect! {|i| %Q!<span class="adminmenu">#{i}</span>! }.join("&nbsp;\n")
  end
end

# conf: default
def saveconf_default
  if @mode == "saveconf" then
    @conf.site_name = @request.params["site_name"]
    @conf.author_name = @request.params["author_name"]
    mails = []
    @request.params["mail"].each_line do |addr|
      mails << addr.gsub(/\r?\n/, "").strip
    end
    mails.delete_if{|e| e.empty?}
    @conf.mail = mails
    @conf.mail_on_update = @request.params["mail_on_update"] == "true"
  end
end

# conf: password
def saveconf_password
  if @mode == "saveconf" then
    old_password    = @request.params["old_password"]
    password1       = @request.params["password1"]
    password2       = @request.params["password2"]
    if password1 and password1.size > 0
      if (@conf.password.size > 0 && old_password.crypt(@conf.password) != @conf.password) ||
          (password1 != password2)
         return :password_change_failure
      end
      salt = [rand(64),rand(64)].pack("C*").tr("\x00-\x3f","A-Za-z0-9./")
      @conf.password = password1.crypt(salt)
      return :password_change_success
    end
  end
  return nil
end

# conf: display
def saveconf_theme
  # dummy
end

if @request.params["conf"] == "theme" && @mode == "saveconf"
  @conf.theme          = @request.params["theme"] || ""
  @conf.use_sidebar    = @request.params["sidebar"] == "true"
  @conf.main_class     = @request.params["main_class"]
  @conf.main_class     = "main" if @conf.main_class == ""
  @conf.sidebar_class  = @request.params["sidebar_class"]
  @conf.sidebar_class  = "sidebar" if @conf.sidebar_class == ""
  @conf.auto_link      = @request.params["auto_link"] == "true"
  @conf.use_wikiname   = @request.params["use_wikiname"] == "true"
  @conf.theme_url      = @request.params["theme_url"]
  @conf.theme_path     = @request.params["theme_path"]
end

if @request.params["conf"] == "theme"
  @conf_theme_list = []
  Dir.glob("#{@conf.theme_path}/*").sort.each do |dir|
    theme = File.basename(dir)
    next unless FileTest.file?("#{dir}/#{theme}.css")
    name = theme.split(/_/).collect{|s| s.capitalize}.join(" ")
    @conf_theme_list << [theme,name]
  end
end

# conf: XML-RPC
def saveconf_xmlrpc
  if @mode == "saveconf"
    @conf.xmlrpc_enabled = @request.params["xmlrpc_enabled"] == "true"
  end
end


def auth?
  true
end

def editable?(page = @page)
  if page
    auth? && ((!@db.is_frozen?(page) && !@conf.options["freeze"]) || admin?)
  else
    creatable?
  end
end

def creatable?
  auth? && (!@conf.options["freeze"] || admin?)
end

def postable?
  true
end

export_plugin_methods(:toc, :toc_here, :recent, :br)
