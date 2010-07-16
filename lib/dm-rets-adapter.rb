require 'rubygems'
require 'dm-core'
require 'dm-core/adapters/abstract_adapter'
require 'rets4r'
module DataMapper::Adapters
  class RetsAdapter < AbstractAdapter
    def initialize(name, options)
      super
    end
    def read(query)
      model = query.model

    end
  end
end
