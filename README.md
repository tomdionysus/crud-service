CRUD Service
============

# Introduction

crud-service provides classes to implement a basic JSON CRUD service amnd CrudService using Sinatra, MySQL and memcached.

# Usage

The gem is intended to provide a set of classes to produce a simple MySQL/Memcached backed RESTful CRUD API for a given number of MySQL entities.

# Getting Started

You should have:

* A MySQL database
* (Optional) An available Memcached instance.
* An empty Sinatra app

# Classes

## GenericLog

CrudService::GenericLog provides instances of a generic logger with the following methods:

* log(message)
* warn(message)
* error(message)

You can provide instances of this class - or any class that supports these methods - to GenericDal and GenericService.

logger = CrudService::GenericLog.new

## GenericDal

GenericDal instances provide a DAL layer for a specific MySQL table, including optional write through Memcached caching using key expiry.

To use CrudService::GenericDal, extend the class and add configuration for your own database schema like the following:

	class CountryDal < CrudService::GenericDal

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
	    end
	end

Then, instantiate the class passing your MySQL client, a logger and optionally your memcached client.

	dal_instance = DAL::CountryDal.new(mysql, memcache, logger)

If you would like to use MySQL query caching, or disable memcache functionality, pass nil as the memcache parameter.

## GenericService

GenericService provides a set of methods with basic CRUD operations, given a DAL instance and a logger.

To use CrudService::GenericService, instantiate the class with the following parameters:

	service = CrudService::GenericService.new(dal_instance, log)

The dal_instance should be an instance of CrudService::GenericDal

## GenericAPI

GenericAPI configures a sinatra class for a specific service layer. The crud_api method takes a sinatra instance, a setting key symbol for the DAL instance, the resource name, and the primary key field name in the DAL, and sets up GET, POST, PUT and DELETE routes at the resource specified.

	class GeoApi < Sinatra::Base

	    before do
	      content_type 'application/json; charset=utf-8'

	      response.headers['Access-Control-Allow-Origin'] = '*'
	      response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
	    end

	    CrudService::GenericApi.crud_api(self, :dal_instance, 'countries', 'code_alpha_2')

	end

	GeoApi.set :dal_instance, dal_instance

The routes are set up as follows (from the above example):

GET    /countries - Returns all records from the associated DAL
GET    /countries/:code_alpha_2 - Returns the specific record with the associated primary key
POST   /countries - Creates a record from the request body JSON
PUT    /countries/:code_alpha_2 - Updates a record with the associated primary key from the request body JSON, only updating the supplied fields
DELETE /countries/:code_alpha_2 - Deletes the specific record with the associated primary key

Routes return 200 / 204 on OK, 400 if validation fails, or 404 if the record cannot be found. In addition, query parameters can be passed to the GET routes as follows:

Return only records where all fields equal the stated values:

	?field=value
	?field=value&field2=value2

Returns records with relation subobjects/arrays as defined in the DAL:

	?include=regions
	?include=regions, currency

Returns records without the named field or fields:

	?exclude=field
	?exclude=field,field2

These query parameters can be combined:

	?region_code=002&include=subdivisions,currency&exclude=code_alpha_3,code_numeric

# Notes

* All route keys and queries are SQL escaped/sanitized.
* The classes are UTF-8 compatible.
* Length and non-null validation is performed according to the field definitions in the DAL.

# Caveats

* Please note crud-service performs no kind of authentication, and you should implement authentication for reads and writes either in your sinatra class, or by extending CrudService::GenericApi.





