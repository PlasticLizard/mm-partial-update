module MmPartialUpdate
  class UpdateCommand
    attr_reader :target_document, :root_document, :commands

    def initialize(target_document)
      @target_document = target_document
      @root_document = target_document.send(:_root_document)
      @commands = BSON::OrderedHash.new { |hash,key| hash[key] = BSON::OrderedHash.new }
    end

    def document_selector
      {:_id=>root_document._id}
    end

    def set(selector, fields, options={})

      return if fields.blank?

      selector = selector.to_s if selector

      if selector.blank? && options[:replace]
        commands["$set"] = fields
      elsif selector.blank?
        commands["$set"].merge!(fields)
      elsif options[:replace]
        commands["$set"][selector] = fields
      else
        commands["$set"].merge!(fields.keys.inject(BSON::OrderedHash.new) do |hash,field_name|
                                  hash["#{selector}.#{field_name}"] = fields[field_name]
                                  hash
                                end)
      end
    end

    def unset(selector, options={})
      raise "'unset' requires a non-blank selector" if selector.blank?
      selector = selector.to_s
      options[:nullify] ? commands["$set"][selector] = nil : commands["$unset"][selector] = true
    end

    def push(selector, document)
      raise "'push' requires a non-blank selector" if selector.blank?
      selector = selector.to_s
      (commands[:pushes][selector] ||= []) << document
    end

    def pull(selector, document_id)
      raise "'pull' requires a non-blank selector" if selector.blank?
      selector = selector.to_s
      (commands[:pulls][selector] ||= []) << document_id
    end

    def merge(other_command)
      commands.merge! other_command.to_h
    end

    def to_h
      commands
    end

    def empty?
      commands.blank?
    end

    def reset
      commands.clear
    end

    def execute(options={})
       #if there are no commands, there is nothing to do...
      return if empty?

      selector = document_selector.tap {|s|s.merge!("$atomic"=>true) if options[:atomic]}

      dbcommands = prepare_mongodb_commands

      dbcommands.each do |command|
        root_document.collection.update(selector, command, :multi=>false,
                                        :upsert=>true, :safe=>options[:safe])
      end
    end

    private

    def prepare_mongodb_commands
      dbcommands = []

      initial_command = commands.dup
      pushes, pulls = initial_command.delete(:pushes), initial_command.delete(:pulls)

      dbcommands << initial_command unless initial_command.blank?

      while (next_op = next_pull(pulls)); dbcommands << next_op; end
      while (next_op = next_push(pushes)); dbcommands << next_op; end

      dbcommands
    end

    def next_push(pushes)
      return nil if pushes.blank?
      selector = pushes.keys[0]
      docs = pushes.delete(selector)
      {"$pushAll" => { selector => docs } }
    end

    def next_pull(pulls)
      return nil if pulls.blank?
      selector = pulls.keys[0]
      doc_ids = pulls.delete(selector)
      {"$pull" => { selector => { "_id" => { "$in" => doc_ids } } } }
    end

  end
end
