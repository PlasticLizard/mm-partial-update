class Person
  include MongoMapper::Document
  key :name, String
  many :pets
  one :favorite_pet, :class_name=>'Pet'
end

class Pet
  include MongoMapper::EmbeddedDocument
  key :name, String
  key :age, Integer
  many :fleas
  one :favorite_flea, :class_name=>'Flea'
end

class Flea
  include MongoMapper::EmbeddedDocument
  key :name, String
end

