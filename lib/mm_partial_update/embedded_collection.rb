module MmPartialUpdate
  module EmbeddedCollection

    def save_to_collection(options)
      super
      assign_database_indexes
    end


    private


    def find_target
      super
      assign_database_indexes
    end

    def assign_database_indexes
      @target.each_with_index do |value, index|
        value.instance_variable_set("@_database_selector","#{association.name}.#{index}")
      end if @target
    end

    def assign_references(*docs)
      super(*docs)
      docs.each do |doc|
        doc.instance_variable_set("@_database_selector",association.name)
      end
    end

  end
end
