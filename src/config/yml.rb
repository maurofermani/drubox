require 'yaml'

class YML

  @@yml = YAML::load(File.open("config/environment.yml"))

  def self.get(key)
    return @@yml[key.to_s]
  end

end