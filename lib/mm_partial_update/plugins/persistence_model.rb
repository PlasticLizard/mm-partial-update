# encoding: UTF-8
module MmPartialUpdate
  module Plugins
    module PersistenceModel
      module InstanceMethods

        def database_selector
          return "" unless respond_to?(:_parent_document) #Root
          "#{_parent_document.database_selector.blank? ? "" : _parent_document.database_selector + "."}#{@_database_selector}"
        end

        protected

        def get_proxy(association)
          proxy = super
          proxy.make_persistable if proxy.can_be_persistable?
          proxy
        end

        def persistence_model
          model = {}

          model[:selector] = database_selector if respond_to?(:_parent_document)

          return model.tap do |m|
            m[:field_changes] = to_mongo
            m[:change_type] = :added
          end if new?

          field_changes = changes
          descendent_changes = []
          embedded_associations.each do |asn|
            proxy = get_proxy(asn)
            unless (my_changes = field_changes.delete(asn.name)).blank?

              my_changes = my_changes[1].blank? ? [my_changes[0]].flatten :
                ([my_changes[0]].flatten - [my_changes[1]].flatten)

              my_changes.each do |deleted|
                descendent_changes << {
                  :selector => deleted.database_selector,
                  :change_type => :deleted
                } unless deleted.nil?
              end
            end

            unless proxy.nil?
              proxy = [proxy] unless proxy.respond_to?(:each)
              proxy.each do |child|
                child_model = child.persistence_model
                descendent_changes << child_model unless child_model.blank?
              end
            end

          end

          return {} if field_changes.blank? && descendent_changes.blank?

          model.tap do |m|
            model[:field_changes] = field_changes.inject({}) do |changes,change|
              changes[change[0]] = change[-1][-1]
              changes
            end unless field_changes.blank?

            model[:descendent_changes] = descendent_changes unless descendent_changes.blank?
            model[:change_type] = :modified
          end
        end

      end
    end
  end
end



