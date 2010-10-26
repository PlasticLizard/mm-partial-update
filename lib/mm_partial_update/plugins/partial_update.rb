# encoding: UTF-8
module MmPartialUpdate
  module Plugins
    module PartialUpdate

      def self.included(model)
        model.plugin MmDirtier::Plugins::Dirtier unless
          model.plugins.include?(MmDirtier::Plugins::Dirtier)
        model.plugin MmPartialUpdate::Plugins::PersistenceModel unless
          model.plugins.include?(MmPartialUpdate::Plugins::PersistenceModel)
        model.plugin MmPartialUpdate::Plugins::PartialUpdate
      end

      module InstanceMethods

        def save_changes(options={})
          #We can't update an embedded document if the root isn't saved
          return root.save_changes(options) if root.new? && embeddable?

          @_new = false
          command = new UpdateCommand(self)

          command.execute(options.merge(:upsert=>new?))
        end

      end

    end
  end
end
