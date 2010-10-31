module MmPartialUpdate
  module EmbeddedCollection

    def save_to_collection(options)
      super.tap { assign_database_indexes }
    end

    def add_updates_to_command(changes, command)
      selector = association.name
      selector = "#{proxy_owner.database_selector}.#{selector}" if
        proxy_owner.respond_to?(:database_selector)

      unless changes.blank?
        deleted = changes[0] - changes[1]
        deleted.each { |d| command.pull(selector, d._id) }
      end

      unless @target.blank?
        @target.each do |child|
          child.new? ? command.push(selector, child.to_mongo) :
            child.add_updates_to_command(command)
        end
      end

    end

    private

    def find_target
      super.tap { |docs| assign_database_indexes(docs) }
    end

    def assign_database_indexes(docs = nil)
      docs ||= @target
      docs.each_with_index do |value, index|
        value.instance_variable_set("@_database_position",index)
      end if docs
    end

    def assign_references(*docs)
      docs.each { |doc| doc.instance_variable_set("@_association_name", association.name) }
      super(*docs)
    end


  end
end
