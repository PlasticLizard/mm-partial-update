require 'test_helper'
require "models"

class TestPartialUpdate < Test::Unit::TestCase

  context "#prepare_update_command" do

    context "on root documents" do

      should "return an empty command if not changed" do
        doc = Person.create!
        doc.send(:prepare_update_command).to_h.empty?.should be_true
      end

      should "return to_mongo if the entity is new" do
        doc = Person.new
        doc.name = "hello"
        doc.send(:prepare_update_command).to_h.should ==
          {"$set"=>doc.to_mongo}
      end

      should "provide set changed fields" do
        doc = Person.create
        doc.name = "hello"
        doc.send(:prepare_update_command).to_h.should ==
          {"$set"=>{"name"=>"hello"}}
      end

      context "with changes to 'one' embedded associations" do
        should "report a new child" do
          doc = Person.create
          doc.favorite_pet.build :name=>"Magma"
          doc.send(:prepare_update_command).to_h.should == {
            "$set"=>{'favorite_pet'=>doc.favorite_pet.to_mongo}
          }
        end

        should "report changed child" do
          doc = Person.new
          doc.favorite_pet.build :name=>"Magma"
          doc.save
          doc.favorite_pet.name = "Ugly"
          doc.send(:prepare_update_command).to_h.should == {
            "$set"=>{"favorite_pet.name"=>"Ugly"}
          }
        end

        should "report a deleted child" do
          doc = Person.new
          doc.favorite_pet.build :name=>"Magma"
          doc.save
          doc.favorite_pet = nil
          doc.send(:prepare_update_command).to_h.should == {
            "$set"=>{'favorite_pet'=>nil}
          }
        end

      end
      context "with changes to 'many' embedded associations" do
        should "report a new child" do
          doc = Person.create
          doc.pets.build :name=>"Magma"
          doc.send(:prepare_update_command).to_h.should == {
            :pushes=>{"pets"=>[doc.pets[0].to_mongo]}
          }
        end

        should "report a changed child" do
          doc = Person.new
          doc.pets.build :name=>"Magma"
          doc.save!
          doc.pets[0].name = "Ugly"
          doc.send(:prepare_update_command).to_h.should == {
            "$set"=>{"pets.0.name"=>"Ugly"}
          }
        end

        should "report a deleted child" do
          doc = Person.new
          deleted = doc.pets.build :name=>"Magma"
          doc.save!
          doc.pets.pop
          doc.send(:prepare_update_command).to_h.should ==  {
            :pulls=>{"pets"=>[deleted._id]}
          }
        end

        should "report a mix of added, modified and deleted" do
          doc = Person.new
          doc.pets.build :name => "Magma"
          deleted = doc.pets.build :name => "Ugly"
          doc.pets.build :name => "Bipolar"
          doc.save!
          doc.pets.reject! {|p|p.name=="Ugly"}
          doc.pets[0].name = "Debris"
          doc.pets.build :name => "Hades"
          doc.send(:prepare_update_command).to_h.should == {
            "$set"=>{"pets.0.name"=>"Debris"},
            :pulls=>{"pets"=>[deleted._id]},
            :pushes=>{"pets"=>[doc.pets[-1].to_mongo]}
          }
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
            pet.instance_variable_get("@_database_position").should == index
          end
        end
      end

      context "with changes to nested one associations" do
        should "report a new grandchild" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          doc.save!
          pet.favorite_flea.build :name=>"Fleatus"
          doc.send(:prepare_update_command).to_h.should == {
            "$set"=>{"pets.0.favorite_flea"=>pet.favorite_flea.to_mongo}
          }
        end

        should "report a modified grandchild" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          flea = pet.favorite_flea.build :name=>"Fleatus"
          doc.save!
          flea.name = "Fleatasia"
          doc.send(:prepare_update_command).to_h.should == {
            "$set"=>{"pets.0.favorite_flea.name"=>"Fleatasia"}
          }
        end

        should "report a deleted grandchild" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          pet.favorite_flea.build :name=>"Fleatus"
          doc.save!
          pet.favorite_flea = nil
          doc.send(:prepare_update_command).to_h.should == {
            "$set"=>{"pets.0.favorite_flea"=>nil}
          }
        end
      end

      context "with changes to nested many associations" do
        should "report a new grandchild" do
          doc = Person.create
          pet = doc.pets.build :name=>"Magma"
          doc.save!
          pet.fleas.build :name=>'Fleatus'
          doc.send(:prepare_update_command).to_h.should == {
            :pushes=>{"pets.0.fleas"=>[pet.fleas[0].to_mongo]}
          }
        end
        should "report a changed grandchild" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          pet.fleas.build :name=>"Fleatus"
          doc.save!
          pet.fleas[0].name = "Fleatasia"
          doc.send(:prepare_update_command).to_h.should == {
            "$set"=>{"pets.0.fleas.0.name"=>"Fleatasia"}
          }
        end

        should "report a deleted child" do
          doc = Person.new
          doc.pets.build :name=>"Magma"
          doc.pets[0].fleas.build :name=>"Fleatus"
          doc.save!
          deleted = doc.pets[0].fleas.pop
          doc.send(:prepare_update_command).to_h.should ==  {
            :pulls=>{"pets.0.fleas"=>[deleted._id]}
          }
        end

        should "report a mix of added, modified and deleted" do
          doc = Person.new
          pet = doc.pets.build :name=>"Magma"
          pet.fleas.build :name => "Fleatus"
          deleted = pet.fleas.build :name => "Fleatasia"
          pet.fleas.build :name => "Soto"
          doc.save!
          pet.fleas.reject! {|f|f.name=="Fleatasia"}
          pet.fleas[0].name = "Rinsai"
          pet.fleas.build :name => "Dogen"
          doc.send(:prepare_update_command).to_h.should == {
            :pulls=>{"pets.0.fleas"=>[deleted._id]},
            :pushes=>{"pets.0.fleas"=>[doc.pets[0].fleas[-1].to_mongo]},
            "$set"=>{"pets.0.fleas.0.name"=>"Rinsai"}
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
            flea.instance_variable_get("@_database_position").should == index
          end
        end

      end

    end
  end
end
