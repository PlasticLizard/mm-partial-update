module MmPartialUpdate
  module OneEmbeddedProxy

    def add_updates_to_command(parent_selector, changes, command)
      selector = parent_selector.blank? ? association.name :
        "#{parent_selector}.#{association.name}"

      if @target.nil?
        command.unset(selector, :nullify=>true) unless changes.blank?
      else
        @target.add_updates_to_command(selector, command)
      end
    end

  end
end
