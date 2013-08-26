# The crud-service gem provides a set of classes to quickly produce a basic CRUD API, from
# a MySQL database with optional memcached caching.
#
# Author::    Tom Cully (mailto:tomhughcully@gmail.com)
# Copyright:: Copyright (c) Tom Cully
# License::   Apache 2

base = File.expand_path('../', __FILE__)

require "#{base}/generic_dal.rb"
require "#{base}/generic_log.rb"
require "#{base}/generic_service.rb"
require "#{base}/generic_api.rb"