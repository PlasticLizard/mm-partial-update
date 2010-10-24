class Person
  name
  many pets
  one car
end

class Car
  make
  model
  many awards
end

class Award
  name
end

class Pet
  name
  age
  many shots
  one vet
end

class Vet
  name
end

class Degree
  date
end

{:field_changes=>{:name=>"Nathan"},
  :descendent_changes=>[
                        { :selector=>'car',
                          :change_type=>:modified,
                          :field_changes=>{:make=>"Honda"},
                          :descendent_changes=>[
                                                {:selector=>'awards.0',:field_changes=>{:name=>"Some Award"}},
                                                {:selector=>'awards.2',:field_changes=>{:name=>"Another Award"}}
                                               ]
                        },
                        {
                          :selector=>'pets.2',
                          :change_type=>:modified,
                          :field_changes=>{:name=>'Scruffy', :age=>2},
                          :descendent_changes=>[
                                                {:selector=>'vet', :field_changes=>{:name=>'John'}},
                                                {:selector=>'shots.1', :field_changes=>{:name=>'Ketamine'}},
                                                {:selector=>'shots.5', :field_changes=>{:name=>'Dopamine'}}
                                               ]
                        },
                        {
                          :selector=>'pets.3',
                          :change_type=>:deleted
                        },
                        {
                          :selector=>'pets',
                          :change_type=>:added,
                          :field_changes=>{:name=>'Stinky', :age=>9, :vet=>{:name=>'John'},:shots=>[{:name=>'foo'},{:name=>'bar'}]
                        }


