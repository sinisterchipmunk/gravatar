class Gravatar
  module Version
    MAJOR, MINOR, TINY = 2, 0, 0
    STRING = [MAJOR, MINOR, TINY].join('.')
  end
  
  VERSION = Version::STRING
end
