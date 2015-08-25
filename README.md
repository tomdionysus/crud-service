# crud-service

[![Build Status](https://travis-ci.org/tomdionysus/crud-service.svg?branch=master)](https://travis-ci.org/tomdionysus/crud-service)
[![Coverage Status](https://coveralls.io/repos/tomdionysus/crud-service/badge.svg?branch=master&service=github)](https://coveralls.io/github/tomdionysus/crud-service?branch=master)
[![Gem Version](https://badge.fury.io/rb/crud-service.svg)](http://rubygems.org/gems/crud-service)
[![Dependency Status](https://gemnasium.com/tomdionysus/crud-service.svg)](https://gemnasium.com/tomdionysus/crud-service)
[![Gem Downloads](http://ruby-gem-downloads-badge.herokuapp.com/crud-service?color=brightgreen)](http://ruby-gem-downloads-badge.herokuapp.com/crud-service?color=brightgreen)

## Introduction

`crud-service` provides classes to implement a basic JSON CRUD service using Sinatra, MySQL and memcached.

## Usage

The gem is intended to provide a set of classes to produce a simple MySQL/Memcached backed RESTful CRUD API for a given number of MySQL entities.

## Getting Started

You should have:

* A MySQL database
* (Optional) An available Memcached instance.
* An empty Sinatra app

## Classes

### Dal

`Dal` instances provide a DAL layer for a specific MySQL table, including optional write through Memcached caching using key expiry.

To use `CrudService::Dal`, extend the class and add configuration for your own database schema like the following:

```ruby
class CountryDal < CrudService::Dal

    def initialize(mysql, memcache, log) 
      super mysql, memcache, log
      @table_name = 'countries'
      @fields = {
        "code_alpha_2"          => { :type=>:string, :length=>2, :required=>true },
        "code_alpha_3"          => { :type=>:string, :length=>3, :required=>true },
        "code_numeric"          => { :type=>:string, :length=>3, :required=>true },
        "name"                  => { :type=>:string, :length=>128, :required=>true },
        "default_currency_code" => { :type=>:string, :length=>3 },
      }
      @relations = {
        "currency" => { 
          :type         => :has_one, 
          :table        => 'currencies',
          :table_key    => 'code', 
          :this_key     => 'default_currency_code',
          :table_fields => 'code,name,symbol'
        },
        "subdivisions" => { 
          :type         => :has_many, 
          :table        => 'subdivisions',
          :table_key    => 'country_code_alpha_2', 
          :this_key     => 'code_alpha_2',
          :table_fields => 'code,name,category,parent_code,timezone_code'
        },
        "regions" => { 
          :type         => :has_many_through, 
          :table        => 'regions',
          :link_table   => 'region_countries',
          :link_key     => 'country_code_alpha_2',
          :link_field   => 'region_code',
          :table_key    => 'code', 
          :this_key     => 'code_alpha_2',
          :table_fields => 'code,name,parent_code',
        },
      }
      @primary_key = 'code_alpha_2'
      @auto_primary_key = false
      @cache_prefix = "geo-countries"
    end
end
```

Then, instantiate the class passing your MySQL client, a logger and optionally your memcached client.

```ruby
logger = Logger.new(STDOUT)

dal_instance = DAL::CountryDal.new(mysql, memcache, logger)
```

If you would like to use MySQL query caching, or disable memcache functionality, pass nil as the memcache parameter.

### Service

`Service` provides a set of methods with basic CRUD operations, given a DAL instance and a logger.

To use CrudService::Service, instantiate the class with the following parameters:

```ruby
service = CrudService::Service.new(dal_instance, log)
```

The dal_instance should be an instance of CrudService::Dal

### Api

The `Api` sinatra extension adds the `crud_api` method that takes the resource name, a setting key symbol for the DAL instance, and the primary key field name in the DAL, and sets up GET, POST, PUT and DELETE routes at the resource specified in the options.

```ruby
class GeoApi < Sinatra::Base

    register CrudService::Api

    before do
      content_type 'application/json; charset=utf-8'

      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    end

    crud_api 'countries', :dal_instance, 'code_alpha_2', :enable_write => false

end

GeoApi.set :dal_instance, dal_instance
```

The crud_api takes options as follows, these are the defaults:

```ruby
options = {
  :enable_read => true,     # Enable all reads (GET)
  :enable_write => true,    # Enable all writes (POST, PUT and DELETE)

  :enable_options => true,  # Enable OPTIONS
  :enable_get_all => true,  # Enable GET /resource
  :enable_get => true,      # Enable GET /resource/:primary_key
  :enable_post => true,     # Enable POST /resource
  :enable_put => true,      # Enable PUT /resource/:primary_key
  :enable_delete => true,   # Enable DELETE /resource/:primary_key
}
```

The routes are set up as follows (from the above example):

* GET    `/countries` - Returns all records from the associated DAL
* GET    `/countries/:code_alpha_2` - Returns the specific record with the associated primary key
* POST   `/countries` - Creates a record from the request body JSON
* PUT    `/countries/:code_alpha_2` - Updates a record with the associated primary key from the request body JSON, only updating the supplied fields
* DELETE `/countries/:code_alpha_2` - Deletes the specific record with the associated primary key

Routes return HTTP Status Codes 200 / 204 on OK, 400 if validation fails, or 404 if the record cannot be found.
In addition, query parameters can be passed to the GET routes as follows:

Return only records where all fields equal the stated values:

	  ?field=value
	  ?field=value&field2=value2

Returns records with relation subobjects/arrays as defined in the DAL:

	  ?include=regions
	  ?include=regions,currency

Returns records without the named field or fields:

	  ?exclude=field
	  ?exclude=field,field2

These query parameters can be combined:

	  ?region_code=002&include=subdivisions,currency&exclude=code_alpha_3,code_numeric

## Notes

* All route keys and queries are SQL escaped/sanitized.
* The classes are UTF-8 compatible.
* Length and non-null validation is performed according to the field definitions in the DAL.

## Dependencies

`crud-service` requires the following gems to run:

* dalli
* json
* mysql2
* sinatra

## Caveats

* Please note `crud-service` performs no kind of authentication. You should implement authentication for reads and writes either in your Sinatra class, or by extending `CrudService::Api`.
* Cache expiry after a write is based on table versions, stored in memcache. It is important that all running instances of your service use the same memcache cluster, or instances using a different cache cluster may return stale data after a write a service not using that cluster. Workaround: Disable memcache as detailed above and use MySQL query caching at the DB server level.

## Code of Conduct

The crud-service project is committed to the [Contributor Covenant](http://contributor-covenant.org). Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before making any contributions or comments.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
