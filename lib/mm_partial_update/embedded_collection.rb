module MmPartialUpdate
  module EmbeddedCollection

    def save_to_collection(options)
      super.tap { assign_database_indexes }
    end

    def add_updates_to_command(parent_selector, changes, command)
      selector = parent_selector.blank? ? association.name :
        "#{parent_selector}.#{association.name}"

      unless changes.blank?
        deleted = changes[0] - changes[1]
        deleted.each { |d| command.pull(selector, d._id) }
      end

      unless @target.blank?
        @target.each do |child|
          child.new? ? command.push(selector, child.to_mongo) :
            child.add_updates_to_command(selector, command)
        end
      end

    end

    private

    def find_target
      super.tap { assign_database_indexes }
    end

    def assign_database_indexes
      @target.each_with_index do |value, index|
        value.instance_variable_set("@_database_position",index)
      end if @target
    end

  end
end
