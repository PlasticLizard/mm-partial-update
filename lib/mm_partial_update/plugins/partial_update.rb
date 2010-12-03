require "mongo_mapper/exceptions.rb"

module MmPartialUpdate
  module Plugins
    module PartialUpdate

      def self.included(model)
        model.plugin MmDirtier::Plugins::Dirtier unless
          model.plugins.include?(MmDirtier::Plugins::Dirtier)
        model.plugin(MmPartialUpdate::Plugins::PartialUpdate)
      end

      module ClassMethods

        def inherited(descendant)
          descendant.instance_variable_set("@_persistence_strategy",
                                           self.persistence_strategy)
          super
        end

        def persistence_strategy(new_strategy=nil)
          return @_persistence_strategy ||= nil unless new_strategy
          @_persistence_strategy = new_strategy
        end

      end

      module InstanceMethods

        def save_changes(options={})
          options.assert_valid_keys(:validate, :callbacks, :safe, :changes_only)
          options.reverse_merge!(:validate=>true, :callbacks=>true)
          !options[:validate] || valid? ? create_or_update_changes(options) : false
        end

        def save_changes!(options={})
          options.assert_valid_keys(:callbacks, :safe, :changes_only)
          save_changes(options) || raise(MongoMapper::DocumentNotValid.new(self))
        end

        def create_or_update_changes(options={})
          #assert_root_saved
          update_command  = prepare_update_command
          execute_command(update_command, options)
          #callbacks and changes_only are not valid
          # options for regular MongoMapper saves.
          # clear_changes_to_subtree will pass this options
          # hash to downstream saves, which can errors
          # so they need to be removed
          options.reject!{ |k,v|[:callbacks, :changes_only].include?(k)}
          clear_changes_to_subtree(options)
        end

        def prepare_update_command
          UpdateCommand.new(self).tap { |command| add_updates_to_command(command) }
        end

        def add_updates_to_command(command)

          selector = respond_to?(:database_selector) ? database_selector : nil

          add_create_self_to_command(selector, command) and return if new?

          field_changes = persistable_changes

          associations.values.each do |association|
            proxy = get_proxy(association)
            association_changes = field_changes.delete(association.name)
            proxy.add_updates_to_command(association_changes, command) if
              proxy.respond_to?(:add_updates_to_command)
          end

          field_changes = field_changes.inject({}) do |changes,change|
            changes[change[0]] = change[-1][-1]
            changes
          end
          command.tap {|c|c.set(selector,field_changes)}
        end

        #Since we are going to persist the values directly from
        # the changes hash, we need to make sure they are
        # propertly readied for storage
        def persistable_changes
          changes.tap do |persistable_changes|
            persistable_changes.each_pair do |key_name, value|
              if (key = keys[key_name])
                value[-1] = key.set(value[-1])
              end
            end
          end
        end

        private

        def add_create_self_to_command(selector, command)
          command.tap { |c| c.set(selector, self.to_mongo, :replace=>true)}
        end

        def get_proxy(association)
          proxy = super(association)
          proxy.make_persistable if proxy.can_be_persistable?
          proxy
        end

        def clear_changes_to_subtree(options)
          @_new = false
          clear_changes
          associations.each do |_, association|
            proxy = get_proxy(association)
            proxy.save_to_collection(options) if
              proxy.proxy_respond_to?(:save_to_collection)
          end
        end

        def execute_command(update_command,options)
           if options[:callbacks]
             context = new? ? :create : :update
             run_callbacks(:save) do
              run_callbacks(context) do
                update_command.execute()
              end
            end
          else
            update_command.execute()
           end
        end

      end

    end
  end
end
