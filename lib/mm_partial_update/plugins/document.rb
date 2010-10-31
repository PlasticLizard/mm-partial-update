# encoding: UTF-8
module MmPartialUpdate
  module Plugins
    module PartialUpdate
      module Document

        def self.included(model)
          model.plugin MmPartialUpdate::Plugins::PartialUpdate::Document
        end

        module InstanceMethods

          def save_to_collection(options={})
            strategy = determine_persistence_strategy(options)
            return super if new? || strategy == :full_document

            save_changes(options)
          end

          private

          def assert_valid_persistence_strategy(strategy)
            raise "Invalid persistence strategy (#{strategy}). Valid options are :full_document or :changes_only" unless ["full_document", "changes_only"].include?(strategy.to_s)
          end

          def determine_persistence_strategy(options)
            strategy =  options[:changes_only] ? :changes_only :
              options[:persistence_strategy] ||
              self.class.persistence_strategy ||
              MmPartialUpdate.default_persistence_strategy ||
              :full_document

            strategy.tap { assert_valid_persistence_strategy(strategy) }
          end

        end


      end
    end
  end
end


