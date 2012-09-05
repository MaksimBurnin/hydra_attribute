# hydra_attribute [![Build Status](https://secure.travis-ci.org/kostyantyn/hydra_attribute.png)](http://travis-ci.org/kostyantyn/hydra_attribute)

[Wiki](https://github.com/kostyantyn/hydra_attribute/wiki) | [RDoc](http://rdoc.info/github/kostyantyn/hydra_attribute)

hydra_attribute is an implementation of
[EAV (Entity-Attribute-Value) pattern](http://en.wikipedia.org/wiki/Entity–attribute–value_model) for ActiveRecord models.

## Requirements
* ruby >= 1.9.2
* active_record >= 3.1

## Installation

Add the following line to Gemfile:
```ruby
gem 'hydra_attribute'
```
and run `bundle install` from your shell.
    
Then we should generate our migration:
```shell
rails generate migration create_hydra_attributes
```    
The content should be:
```ruby    
class CreateHydraAttributeTables < ActiveRecord::Migration
  def up
    create_hydra_entity :products do |t|
      # add here all other columns that should be in the entity table
      t.timestamps
    end
  end
      
  def down
    drop_hydra_entity :products
  end
end
```

**or if we have already the entity table**

```ruby    
class CreateHydraAttributeTables < ActiveRecord::Migration
  def up
    migrate_to_hydra_entity :products
  end
      
  def down
    rollback_from_hydra_entity :products
  end
end
```

## Usage

### Create model
```shell
rails generate model Product type:string name:string --migration=false
rake db:migrate
```

and add `use_hydra_attributes` to Product class
```ruby
class Product < ActiveRecord::Base
  use_hydra_attributes
end
```

**Starting from version 0.4.0 `use_hydra_attributes` method will be removed.**
```ruby
class Product < ActiveRecord::Base
  include HydraAttribute::ActiveRecord
end
```

### Create hydra attributes
```ruby
Product.hydra_attributes.create(name: 'color', backend_type: 'string', default_value: 'green')
Product.hydra_attributes.create(name: 'title', backend_type: 'string')
Product.hydra_attributes.create(name: 'total', backend_type: 'integer', default_value: 1)
```

Creating method accepts the following options:
* **name**. The **required** parameter. Allowed any string.   
* **backend_type**. The **required** parameter. Allowed one of the following strings: `string`, `text`, `integer`, `float`, `boolean` and `datetime`.
* **default_value**. The **optional** parameter. Allowed any value. By default is `nil`.
* **white_list**. The **optional** parameter. Should be `true` or `flase`. By defauls is `false`. if pass `white_list: true` this attribute will be added to white list and will be allowed for mass-assignment. This parameter is in black list for creation by default so if you want to pass it, you have to pass the role `as: :admin` too.

  ```ruby
    Product.hydra_attributes.create({name: 'title', backend_type: 'string', white_list: true}, as: :admin)
  ```

### Create records
```ruby
Product.create
#<Product id: 1, hydra_set_id: nil, created_at: ..., updated_at: ..., color: "green", title: nil, total: 1>
Product.create(color: 'red', title: 'toy')
#<Product id: 2, hydra_set_id: nil, created_at: ..., updated_at: ..., color: "red", title: "toy", total: 1>
Product.create(title: 'book', total: 2)
#<Product id: 3, hydra_set_id: nil, created_at: ..., updated_at: ..., color: "green", title: "book", total: 2>
```

### Add new hydra attribute in runtime
```ruby
Product.hydra_attributes.create(name: 'price', backend_type: 'float', default_value: 0.0)
Product.create(title: 'car', price: 2.50)
#<Product id: 4, hydra_set_id: nil, created_at: ..., updated_at: ..., color: "green", title: "car", total: 2, price: 2.5>
```

### Create hydra set
**Hydra set** allows set unique attribute list for each entity.

```ruby
hydra_set = Product.hydra_sets.create(name: 'Default')
hydra_set.hydra_attributes = Product.hydra_attributes.where(name: %w(color title price))

Product.create(color: 'black', title: 'ipod', price: 49.95, total: 5) do |product|
  product.hydra_set_id = hydra_set.id
end
#<Product id: 5, hydra_set_id: 1, created_at: ..., updated_at: ..., color: "black", title: "ipod", price: 49.95>
```
**Notice:** the `total` attribute was skipped because it doesn't exist in hydra set.

### Obtain data
```ruby
Product.where(color: 'red')
# [#<Product id: 2, hydra_set_id: nil, created_at: ..., updated_at: ..., color: "red", title: "toy", price: 0.0, total: 1>]
Product.where(color: 'green', price: nil)
# [
    #<Product id: 1, hydra_set_id: nil, created_at: ..., updated_at: ..., color: "green", title: nil, price: 0.0, total: 1>,
    #<Product id: 3, hydra_set_id: nil, created_at: ..., updated_at: ..., color: "green", title: "book", price: 0.0, total: 2>
# ]
```
**Notice**: the attribute `price` was added in runtime and records that were created before have not this attribute
so they matched this condition `where(price: nil)`

### Order data
```ruby
Product.order(:color, :title).first
#<Product id: 5, hydra_set_id: 1, created_at: ..., updated_at: ..., color: "black", title: "ipod", price: 49.95>
Product.order(:color, :title).reverse_order.first
#<Product id: 2, hydra_set_id: nil, created_at: ..., updated_at: ..., color: "red", title: "toy", price: 0.0, total: 1>
```

### Select concrete attributes
```ruby
Product.select([:color, :title])
# [
    #<Product id: 1, hydra_set_id: nil, color: "green", title: nil>,
    #<Product id: 2, hydra_set_id: nil, color: "red", title: "toy">,
    #<Product id: 3, hydra_set_id: nil, color: "green", title: "book">,
    #<Product id: 4, hydra_set_id: nil, color: "green", title: "car">,
    #<Product id: 5, hydra_set_id: 1, color: "black", title: "ipod">
# ] 
```
**Notice:** `id` and `hydra_set_id` attributes are forced added because they are important for correct work.

### Group by attribute
```ruby
Product.group(:color).count
# {"black"=>1, "green"=>3, "red"=>1}
```

## Wiki Docs
* [Create migration](https://github.com/kostyantyn/hydra_attribute/wiki/Create-migration)
* [Create attributes in runtime](https://github.com/kostyantyn/hydra_attribute/wiki/Create-attributes-in-runtime)
* [Create sets of attributes](https://github.com/kostyantyn/hydra_attribute/wiki/Create-sets-of-attributes)
* [Query methods](https://github.com/kostyantyn/hydra_attribute/wiki/Query-methods)

## Notice

The each new minor version doesn't guarantee back compatibility with previous one 
until the first major version will be released. 

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
