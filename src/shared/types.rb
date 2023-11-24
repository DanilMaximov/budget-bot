module Types
  # class Enum < Data
  #   alias_method :to_a, :members

  #   def self.define(*args)
  #     super.new(*args)
  #   end

  #   def initialize(...)
  #     super
  #     freeze
  #   end
  # end


  # module Event
  #   module Chat
  #     module Commands
  #       EMenuCommands = Enum.define(:start, :help, :settings)
  #     end

  #     module Route
  #       EEventHandler = Enum.define(:commands, :expenses, :settings)
  #     end

  #     EStatus = Enum.define(:default, :settings)
  #     EType   = Enum.define(:command, :message, :callback_query)
  #   end

  #   ENUM_TYPE   = [ :telegram, :web_api ]
  #   ENUM_FILTER = [ :where, :limit, :order_by ]
  #   ENUM_TARGET = [ :expenses, :menu ]

  #   private_constant :ENUM_TYPE, :ENUM_FILTER

  #   EType   = Enum.define(*ENUM_TYPE)
  #   EFilter = Enum.define(*ENUM_FILTER)
  #   ETarget = Enum.define()
  # end

  # module Model
  #   ENUM_QUERY_METHODS   = %i(find where update insert destroy).freeze
  #   ENUM_FILTER_METHODS  = %i(limit order_by).freeze
  #   ENUM_ALLOWED_METHODS = (ENUM_QUERY_METHODS + ENUM_FILTER_METHODS).freeze

  #   private_constant :ENUM_QUERY_METHODS, :ENUM_FILTER_METHODS, :ENUM_ALLOWED_METHODS

  #   EQueryMethods   = Enum.define(*ENUM_QUERY_METHODS)
  #   EFilterMethods  = Enum.define(*ENUM_FILTER_METHODS)
  #   EAllowedMethods = Enum.define(*ENUM_ALLOWED_METHODS)
  # end
end
