# encoding: UTF-8
module MmPartialUpdate
  module Plugins
    module PartialUpdate
      module EmbeddedDocument

        def self.included(model)
          model.plugin MmPartialUpdate::Plugins::PartialUpdate::EmbeddedDocument
        end

        module InstanceMethods

          def create_or_update_changes(options={})
            assert_root_saved
            super
          end

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

          def assert_root_saved
            raise "You are attempting to save changes to an embedded document, but the root document has not yet been saved. You must save changes to the root document before you can call save_changes any of its embedded documents" if _root_document.new?
          end

        end

      end
    end
  end
end

