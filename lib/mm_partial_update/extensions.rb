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
        def persistable?
          false
        end
        def can_be_persistable?
          false
        end
      end

      class EmbeddedCollection
        def can_be_persistable?
          true
        end
        def persistable?
          @persistable
        end

        def make_persistable
          class << self; include MmPartialUpdate::EmbeddedCollection; end unless persistable?
          @persistable = true
        end

      end

      class OneEmbeddedProxy
        def can_be_persistable?
          true
        end
        def persistable?
          @persistable
        end

        def make_persistable
          class << self; include MmPartialUpdate::OneEmbeddedProxy; end unless persistable?
          @persistable = true
        end
      end

      class ManyDocumentsProxy
        def save_to_collection(options={})
          @target.each { |doc| doc.save_changes(options) if doc.changed? } if @target
        end
      end


    end
  end
end
