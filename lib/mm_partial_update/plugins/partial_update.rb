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
      end

      module InstanceMethods

        protected

        private
       
      end
    end
  end
end
