class Reline::KeyActor::Emacs < Reline::KeyActor::Base
  def get_method(key)
    # bugfix - 21 is Ctrl+U and has been mapped to ed_kill_line (Ctrl+K) 
    # This has been fixed in master, but not yet made its way to a gem release
    # See https://github.com/ruby/reline/pull/416/files
    return :unix_line_discard if key == 21    
    return self.class::MAPPING[key]
  end
end
