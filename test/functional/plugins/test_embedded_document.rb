require 'test_helper'
require "models"

class TestEmbeddedDocumentPlugin < Test::Unit::TestCase

  context "#database_selector" do

    should "be defined for new one relationships" do
      person = Person.new
      pet = person.favorite_pet.build
      pet.database_selector.should == "favorite_pet"
    end

    should "be defined for one relationships loaded from the database" do
      person = Person.new
      person.favorite_pet.build
      person.save!
      person = Person.find(person.id)
      person.favorite_pet.database_selector.should == "favorite_pet"
    end

    should "be defined for new many_embedded relationships" do
      person = Person.new
      pet = person.pets.build
      pet.database_selector.should == "pets"
    end

    should "be defined for new many_embedded relationships loaded from the database" do
      person = Person.new
      person.pets.build
      person.save!
      person = Person.find(person.id)
      person.pets[0].database_selector.should == "pets.0"
    end

    should "be defined for new nested one relationships" do
      person = Person.new
      person.pets.build
      person.save!
      person = Person.find(person.id)
      flea = person.pets[0].favorite_flea.build
      flea.database_selector.should == "pets.0.favorite_flea"
    end

    should "be defined for nested one relationships loaded from the database" do
      person = Person.new
      person.pets.build
      person.pets[0].favorite_flea.build
      person.save!
      person = Person.find(person.id)
      person.pets[0].favorite_flea.database_selector.should == "pets.0.favorite_flea"
    end

    should "be defined for new nested many relationships" do
      person = Person.new
      person.pets.build
      person.save!
      person = Person.find(person.id)
      person.pets[0].fleas.build
      person.pets[0].fleas[0].database_selector.should == "pets.0.fleas"
    end

    should "be defined for nested many relationships loaded from the database" do
      person = Person.new
      person.pets.build
      person.pets[0].fleas.build
      person.save!
      person = Person.find(person.id)
      person.pets[0].fleas[0].database_selector.should == "pets.0.fleas.0"
    end

  end

  context "#save_changes" do

    should "save an unsaved parent when a descendent is saved" do
      person = Person.new :name=>"Willard"
      pet = person.pets.build :name=>"Magma"
      pet.save_changes
      person = Person.find(person.id)
      person.should_not be_nil
      person.name.should == "Willard"
      person.pets.count.should == 1
      person.pets[0].name.should == "Magma"
    end

    should "create an embedded document that doesn't already exist" do
      person = Person.create! :name=>"Nathan"
      pet = person.pets.build :name=>"Magma", :age=>3
      pet.save_changes
      person.reload
      person.pets.count.should == 1
      person.pets[0].name.should == "Magma"
      person.pets[0].age.should == 3
    end

    should "create an embedded document without saving the parent" do
      person = Person.create! :name=>"Willard"
      person.name = "Nevermore"
      pet = person.pets.build :name=>"Magma"
      pet.save_changes
      pet.changed?.should be_false
      person.changed?.should be_true
      person.reload
      person.name.should == "Willard"
      person.pets.count.should == 1
      person.pets[0].name.should == "Magma"
    end

  end

end
