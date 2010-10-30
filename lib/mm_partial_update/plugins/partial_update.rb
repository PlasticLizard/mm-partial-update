# encoding: UTF-8
module MmPartialUpdate
  module Plugins
    module PartialUpdate

      def self.included(model)
        model.plugin MmDirtier::Plugins::Dirtier unless
          model.plugins.include?(MmDirtier::Plugins::Dirtier)
        model.plugin MmPartialUpdate::Plugins::PartialUpdate
      end

      module InstanceMethods

        def save_changes(options={})
          #We can't update an embedded document if the root isn't saved
          #The clear_changes call is added here because dirty
          #tracking happens further up the call chain than save_to_collection
          #under normal circumstances, so we have to inject it
          return _root_document.save_to_collection.tap {clear_changes} if
            _root_document.new?

          #persist changes to self and descendents
          update_command  = prepare_update_command
          update_command.execute()

          #clear dirty tracking
          @_new = false
          clear_changes
          associations.each do |_, association|
            proxy = get_proxy(association)
            proxy.save_to_collection(options) if
              proxy.proxy_respond_to?(:save_to_collection)
          end
        end

        def prepare_update_command
           UpdateCommand.new(self).tap { |command| add_updates_to_command nil, command }
        end

        def add_updates_to_command(parent_selector, command)

          selector = defined?(@_database_position) ?
          "#{parent_selector}.#{@_database_position}" : parent_selector

          return command.tap {|c|c.set(selector, self.to_mongo, :replace=>true)} if new?

          field_changes = changes

          associations.values.each do |association|
            proxy = get_proxy(association)
            association_changes = field_changes.delete(association.name)
            proxy.add_updates_to_command(selector, association_changes, command) if
              proxy.respond_to?(:add_updates_to_command)
          end

          field_changes = field_changes.inject({}) do |changes,change|
            changes[change[0]] = change[-1][-1]
            changes
          end
          command.tap {|c|c.set(selector,field_changes)}
        end

        private

        def get_proxy(association)
          proxy = super(association)
          proxy.make_persistable if proxy.can_be_persistable?
          proxy
        end

      end

    end
  end
end
