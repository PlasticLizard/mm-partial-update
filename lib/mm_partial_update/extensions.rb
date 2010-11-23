class Object
  def can_be_persistable?
    respond_to?(:make_persistable)
  end
end


module MongoMapper
  module Plugins
    module Associations

      class Proxy
        def add_updates_to_command(*args)
          #noop - this needs to be here to prevent this call from
          # bubbling up to the document. For non-embedded proxies, there
          # no updates to add to the command.
        end
      end

      class EmbeddedCollection
        def persistable?
          kind_of?(MmPartialUpdate::EmbeddedCollection)
        end

        def make_persistable
          class << self; include MmPartialUpdate::EmbeddedCollection; end unless persistable?
        end

      end

      class OneEmbeddedProxy
        def persistable?
          kind_of?(MmPartialUpdate::OneEmbeddedProxy)
        end

        def make_persistable
          class << self; include MmPartialUpdate::OneEmbeddedProxy; end unless persistable?
        end

      end


    end
  end
end
