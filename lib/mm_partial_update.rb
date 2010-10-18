require 'rubygems'
require "mongo_mapper"
require "observables"
require "mm_dirtier"

base_dir = File.dirname(__FILE__)
[
 'version',
 'extensions',
 'plugins/partial_update'
].each {|req| require File.join(base_dir,'mm_partial_update',req)}


MongoMapper::Document.append_inclusions(MmPartialUpdate::Plugins::PartialUpdate)
MongoMapper::EmbeddedDocument.append_inclusions(MmPartialUpdate::Plugins::PartialUpdate)
