class Gravatar
  module Version
    MAJOR, MINOR, TINY = 1, 0, 3
    STRING = [MAJOR, MINOR, TINY].join('.')
  end
  
  VERSION = Version::STRING
end
