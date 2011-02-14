module Appoxy
  module Utils
    def self.random_string(length=10)
      chars    = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
      password = ''
      length.times { password << chars[rand(chars.size)] }
      password
    end

  end
end
