# encoding: UTF-8
module MmPartialUpdate
  module Plugins
    module PartialUpdate

      def self.included(model)
        model.plugin MmPartialUpdate::Plugins::PartialUpdate
      end

      def self.configure(model)
        model.plugin MmDirtier::Plugins::Dirtier unless
          model.plugins.include?(MmDirtier::Plugins::Dirtier)

        model.plugin MmPartialUpdate::Plugins::PersistenceModel unless
          model.plugins.include?(MmPartialUpdate::Plugins::PersistenceModel)
      end

      module InstanceMethods

      end

    end
  end
end
