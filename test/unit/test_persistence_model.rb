require 'test_helper'
require "models"

class TestPersistenceModel < Test::Unit::TestCase

  context "persistence_model" do

    context "on root documents" do

      should "return an empty hash if not changed" do
        doc = Person.create!
        doc.send(:persistence_model).should == {}
      end

      should "return to_mongo if the entity is new" do
        doc = Person.new
        doc.name = "hello"
        doc.send(:persistence_model).should == {:field_changes=>doc.to_mongo, :change_type=>:added}
      end

      should "provide a hash of changed fields" do
        doc = Person.create
        doc.name = "hello"
        doc.send(:persistence_model).should == {:field_changes=>{"name"=>"hello"}, :change_type=>:modified}
      end

      context "with changes to 'one' embedded associations" do
        should "report a new child" do
          doc = Person.create
          doc.favorite_pet.build :name=>"Magma"
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'favorite_pet',
                                    :change_type=>:added,
                                    :field_changes=>doc.favorite_pet.to_mongo
                                  }
                                 ], :change_type=>:modified}

        end
        should "report changed child" do
          doc = Person.new
          doc.favorite_pet.build :name=>"Magma"
          doc.save
          doc.favorite_pet.name = "Ugly"
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'favorite_pet',
                                    :change_type=>:modified,
                                    :field_changes=>{"name"=>"Ugly"}
                                  }
                                 ], :change_type=>:modified}
        end
        should "report a deleted child" do
          doc = Person.new
          doc.favorite_pet.build :name=>"Magma"
          doc.save
          doc.favorite_pet = nil
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'favorite_pet',
                                    :change_type=>:deleted
                                  }
                                 ], :change_type=>:modified}
        end

      end
      context "with changes to 'many' embedded associations" do
        should "report a new child" do
          doc = Person.create
          doc.pets.build :name=>"Magma"
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets',
                                    :change_type=>:added,
                                    :field_changes=>doc.pets[0].to_mongo
                                  }
                                 ], :change_type=>:modified}
        end
        should "report a changed child" do
          doc = Person.new
          doc.pets.build :name=>"Magma"
          doc.save!
          doc.pets[0].name = "Ugly"
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.0',
                                    :change_type=>:modified,
                                    :field_changes=>{"name"=>"Ugly"}
                                  }
                                 ], :change_type=>:modified}
        end
        should "report a deleted child" do
          doc = Person.new
          doc.pets.build :name=>"Magma"
          doc.save!
          doc.pets.pop
          doc.send(:persistence_model).should ==  {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.0',
                                    :change_type=>:deleted
                                  }
                                 ], :change_type=>:modified}
        end

        should "report a mix of added, modified and deleted" do
          doc = Person.new
          doc.pets.build :name => "Magma"
          doc.pets.build :name => "Ugly"
          doc.pets.build :name => "Bipolar"
          doc.save!
          doc.pets.reject! {|p|p.name=="Ugly"}
          doc.pets[0].name = "Debris"
          doc.pets.build :name => "Hades"
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.1',
                                    :change_type=>:deleted
                                  },
                                  {
                                    :selector=>'pets.0',
                                    :change_type=>:modified,
                                    :field_changes=>{"name"=>"Debris"}
                                  },
                                  {
                                    :selector=>'pets',
                                    :change_type=>:added,
                                    :field_changes=>doc.pets[-1].to_mongo
                                  }
                                 ], :change_type=>:modified}
        end

        should "update database selectors after save" do
          doc = Person.new
          doc.pets.build :name=>"Magma"
          doc.pets.build :name=>"Ugly"
          doc.pets.build :name=>"Bipolar"
          doc.save!
          doc.pets.reject! {|p|p.name=="Ugly"}
          doc.save!
          doc.pets.length.should == 2
          doc.pets.each_with_index do |pet,index|
            pet.instance_variable_get("@_database_selector").should == "pets.#{index}"
          end
        end
      end

      context "with changes to nested one associations" do
        should "report a new grandchild" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          doc.save!
          pet.favorite_flea.build :name=>"Fleatus"
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.0',
                                    :descendent_changes=>[
                                                          {
                                                            :selector=>'pets.0.favorite_flea',
                                                            :field_changes=>pet.favorite_flea.to_mongo,
                                                            :change_type=>:added
                                                          }
                                                         ], :change_type=>:modified
                                  }
                                 ], :change_type=>:modified
          }
        end
        should "report a modified grandchild" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          flea = pet.favorite_flea.build :name=>"Fleatus"
          doc.save!
          flea.name = "Fleatasia"
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.0',
                                    :descendent_changes=>[
                                                          {
                                                            :selector=>'pets.0.favorite_flea',
                                                            :field_changes=>{"name"=>"Fleatasia"},
                                                            :change_type=>:modified
                                                          }
                                                         ], :change_type=>:modified
                                  }
                                 ], :change_type=>:modified
          }
        end
        should "report a deleted grandchild" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          pet.favorite_flea.build :name=>"Fleatus"
          doc.save!
          pet.favorite_flea = nil
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.0',
                                    :descendent_changes=>[
                                                          {
                                                            :selector=>'pets.0.favorite_flea',
                                                            :change_type=>:deleted
                                                          }
                                                         ], :change_type=>:modified
                                  }
                                 ], :change_type=>:modified
          }
        end
      end
      context "with changes to nested many associations" do
        should "report a new grandchild" do
          doc = Person.create
          pet = doc.pets.build :name=>"Magma"
          doc.save!
          pet.fleas.build :name=>'Fleatus'
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.0',
                                    :descendent_changes=>[
                                                          {
                                                            :selector=>'pets.0.fleas',
                                                            :field_changes=>pet.fleas[0].to_mongo,
                                                            :change_type=>:added
                                                          }
                                                         ], :change_type=>:modified
                                  }
                                 ], :change_type=>:modified
          }
        end
        should "report a changed grandchild" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          pet.fleas.build :name=>"Fleatus"
          doc.save!
          pet.fleas[0].name = "Fleatasia"
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.0',
                                    :descendent_changes=>[
                                                          {
                                                            :selector=>'pets.0.fleas.0',
                                                            :field_changes=>{"name"=>"Fleatasia"},
                                                            :change_type=>:modified
                                                          }
                                                         ], :change_type=>:modified
                                  }
                                 ], :change_type=>:modified
          }
        end
        should "report a deleted child" do
          doc = Person.new
          doc.pets.build :name=>"Magma"
          doc.pets[0].fleas.build :name=>"Fleatus"
          doc.save!
          doc.pets[0].fleas.pop
          doc.send(:persistence_model).should ==  {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.0',
                                    :descendent_changes=>[
                                                          {
                                                            :selector=>'pets.0.fleas.0',
                                                            :change_type=>:deleted
                                                          }
                                                         ], :change_type=>:modified
                                  }
                                 ], :change_type=>:modified
          }
        end

        should "report a mix of added, modified and deleted" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          pet.fleas.build :name => "Fleatus"
          pet.fleas.build :name => "Fleatasia"
          pet.fleas.build :name => "Soto"
          doc.save!
          pet.fleas.reject! {|f|f.name=="Fleatasia"}
          pet.fleas[0].name = "Rinsai"
          pet.fleas.build :name => "Dogen"
          doc.send(:persistence_model).should == {
            :descendent_changes=>[
                                  {
                                    :selector=>'pets.0',
                                    :descendent_changes=>[
                                                          {
                                                            :selector=>'pets.0.fleas.1',
                                                            :change_type=>:deleted
                                                          },
                                                          {
                                                            :selector=>'pets.0.fleas.0',
                                                            :change_type=>:modified,
                                                            :field_changes=>{"name"=>"Rinsai"}
                                                          },
                                                          {
                                                            :selector=>'pets.0.fleas',
                                                            :change_type=>:added,
                                                            :field_changes=>pet.fleas[-1].to_mongo
                                                          }
                                                         ], :change_type=>:modified
                                  }
                                 ], :change_type=>:modified
          }
        end

        should "update database selectors after save" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          pet.fleas.build :name=>"Fleatus"
          pet.fleas.build :name=>"Soto"
          pet.fleas.build :name=>"Rinsai"
          doc.save!
          pet.fleas.reject! {|p|p.name=="Soto"}
          doc.save!
          pet.fleas.length.should == 2
          pet.fleas.each_with_index do |flea,index|
            flea.instance_variable_get("@_database_selector").should == "fleas.#{index}"
          end
        end

      end

    end
  end
end
