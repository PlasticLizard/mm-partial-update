module MmPartialUpdate
  module OneEmbeddedProxy
    protected
    def assign_references(doc)
      super.tap do
        doc.instance_variable_set("@_database_selector",association.name.to_s) if doc
      end
    end
  end
end
