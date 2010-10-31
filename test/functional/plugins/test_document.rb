require 'test_helper'
require "models"

class TestDocumentPlugin < Test::Unit::TestCase

  context "Document#save" do
    should "respect persistence_strategy" do
      Person.persistence_strategy(:changes_only)
      #Person one should not have anything in the pets collection
      person = Person.create! :name=>"Willard"

      person2 = Person.find(person.id)
      person2.pets.build :name=>"Magma"
      person2.save!

      person.name = "Timmy"
      person.save!
      person.reload
      person.name.should == "Timmy"
      person.pets.length.should == 1

      Person.persistence_strategy(:full_document)
    end
  end

  context "#save_to_collection" do

    should "overwrite the document when the strategy is :full_document" do
      #Person one should not have anything in the pets collection
      person = Person.create! :name=>"Willard"

      person2 = Person.find(person.id)
      person2.pets.build :name=>"Magma"
      person2.save!

      person.name = "Timmy"
      person.save_to_collection(:persistence_strategy=>:full_document) #this is the default
      person.reload
      person.name.should == "Timmy"
      person.pets.length.should == 0
    end


    should "only save changes when the strategy is :changes_only" do
      #Person one should not have anything in the pets collection
      person = Person.create! :name=>"Willard"

      person2 = Person.find(person.id)
      person2.pets.build :name=>"Magma"
      person2.save!

      person.name = "Timmy"
      person.save_to_collection(:changes_only=>true)
      person.reload
      person.name.should == "Timmy"
      person.pets.length.should == 1
    end

  end

  context "#determine_persistence_strategy" do
    should "return a default strategy if none is set or provided" do
      Person.new.send(:determine_persistence_strategy,{}).should == :full_document
    end

    should "return the plugin level persistence strategy if defined" do
      MmPartialUpdate.default_persistence_strategy =  :changes_only
      Person.new.send(:determine_persistence_strategy,{}).should == :changes_only
      MmPartialUpdate.default_persistence_strategy = :full_document
    end

    should "use class level persistence strategy if defined" do
      Person.persistence_strategy(:changes_only)
      Person.new.send(:determine_persistence_strategy,{}).should == :changes_only
      Person.persistence_strategy(:full_document)
    end

    should "use persistence strategy in the options if defined" do
      Person.new.send(:determine_persistence_strategy,
                      {:persistence_strategy=>:changes_only}).should == :changes_only
    end

    should "interpret :changes_only=>true in the options as a strategy of :changes_only" do
      Person.new.send(:determine_persistence_strategy,:changes_only=>true).
        should == :changes_only
    end

  end


end
