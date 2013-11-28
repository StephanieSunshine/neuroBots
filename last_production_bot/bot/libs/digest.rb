module Digest

def digest(title, artist)
  return Digest::MD5.hexdigest(title+artist)
end

end
