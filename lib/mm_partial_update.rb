require 'rubygems'
require "mongo_mapper"
require "observables"
require "mm_dirtier"

base_dir = File.dirname(__FILE__)
[
 'version',
 'embedded_collection',
 'one_embedded_proxy',
 'extensions',
 'update_command',
 'plugins/partial_update',
 'plugins/document',
 'plugins/embedded_document'
].each {|req| require File.join(base_dir,'mm_partial_update',req)}

MongoMapper::Document.append_inclusions(MmPartialUpdate::Plugins::PartialUpdate)
MongoMapper::Document.append_inclusions(MmPartialUpdate::Plugins::PartialUpdate::Document)

MongoMapper::EmbeddedDocument.append_inclusions(MmPartialUpdate::Plugins::PartialUpdate)
MongoMapper::EmbeddedDocument.append_inclusions(MmPartialUpdate::Plugins::PartialUpdate::EmbeddedDocument)

module MmPartialUpdate
  def self.default_persistence_strategy
    @default_persistence_strategy ||= :full_document
  end

  def self.default_persistence_strategy=(strategy)
    @default_persistence_strategy = strategy
  end
end
