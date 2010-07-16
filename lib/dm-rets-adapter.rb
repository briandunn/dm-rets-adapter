require 'logger'
require 'rubygems'
require 'dm-core'
require 'dm-core/adapters/abstract_adapter'
require 'rets4r'

module DataMapper::Adapters
  class RetsAdapter < AbstractAdapter
    attr :url 
    attr :username
    attr :password
    def initialize(name, options)
      @url      = options[:url]
      @username = options[:username]
      @password = options[:password]
      super
    end
    def read(query)

      model    = query.model
      resource = model.storage_names[name][:resource]
      klass    = model.storage_names[name][:class]
      select_list = model.properties.map(&:field).join(',')

      records = nil 
      RETS4R::Client.new(url) do |client|
        client.logger = DataMapper.logger 
        client.login(username, password)
        records = client.search(resource,klass,nil,'Select' => select_list, 'Limit' => query.limit.to_s).response
      end
      records || []
    end
  end
end
