require 'multi_json'

def fixture(name, jsonify = true)
  path = File.expand_path '../../fixtures', __FILE__

  file = File.read("#{path}/#{name}.json")

  jsonify ? MultiJson.load(file) : file
end
