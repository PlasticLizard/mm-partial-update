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

    def unset(selector)
      raise "'unset' requires a non-blank selector" if selector.blank?
      selector = selector.to_s
      commands["$unset"][selector] = true
    end

    def push(selector, document)
      raise "'push' requires a non-blank selector" if selector.blank?
      selector = selector.to_s
      (commands["$pushAll"][selector] ||= []) << document
    end

    def pull(selector, document_id)
      raise "'pull' requires a non-blank selector" if selector.blank?
      selector = selector.to_s
      commands["$pull"][selector] ||= {"_id"=>{"$in"=>[]}}
      commands["$pull"][selector]["_id"]["$in"] << document_id
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

    def execute(options={})
      selector = document_selector.tap {|s|s.merge!("$atomic"=>true) if options[:atomic]}

      #if there are no commands, there is nothing to do...
      return if empty?

      #puts "#{root_document.class.name}.collection.update(#{selector.inspect}, #{commands.inspect}, :multi=>false, :upsert=>#{options[:upsert]}, :safe=>#{options[:safe]})"
      root_document.collection.update(selector, commands, :multi=>false,
                                      :upsert=>true, :safe=>options[:safe])
    end
  end
end
