module MmPartialUpdate
  module OneEmbeddedProxy

    def add_updates_to_command(changes, command)
      selector = association.name
      selector = "#{proxy_owner.database_selector}.#{selector}" if
        proxy_owner.respond_to?(:database_selector)

      if @target.nil?
        command.unset(selector, :nullify=>true) unless changes.blank?
      else
        @target.add_updates_to_command(command)
      end
    end

    def assign_references(doc)
      doc.instance_variable_set("@_association_name",association.name)
      super(doc)
    end

  end
end
