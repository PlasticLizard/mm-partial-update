# encoding: UTF-8
module MmPartialUpdate
  module Plugins
    module PartialUpdate
      module EmbeddedDocument

        def self.included(model)
          model.plugin MmPartialUpdate::Plugins::PartialUpdate::EmbeddedDocument
        end

        module InstanceMethods

          def database_selector
            selector = @_association_name.to_s
            selector = "#{_parent_document.database_selector}.#{selector}" if
              _parent_document.respond_to?(:database_selector)
            selector = "#{selector}.#{@_database_position}" if defined?(@_database_position)
            selector
          end

          private

          def add_create_self_to_command(selector, command)
            if _parent_document.new?
              _parent_document.add_updates_to_command(command)
            else

              association = _parent_document.associations[@_association_name]
              if association && association.many?
                command.push(selector, self.to_mongo)
              else
                command.set(selector, self.to_mongo, :replace=>true)
              end
            end
          end

        end

      end
    end
  end
end

