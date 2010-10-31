# encoding: UTF-8
module MmPartialUpdate
  module Plugins
    module PartialUpdate
      module EmbeddedDocument

        def self.included(model)
          model.plugin MmPartialUpdate::Plugins::PartialUpdate::EmbeddedDocument
        end

        module InstanceMethods

        end

      end
    end
  end
end

