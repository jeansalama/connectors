#
# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.
#

# frozen_string_literal: true

require 'bson'
require 'utility/logger'

module Connectors
  module Base
    class Connector
      def initialize
        @status = {
          :index_document_count => 0,
          :deleted_document_count => 0,
          :error => nil
        }
      end

      def sync_content_and_yield(connector)
        sync_content(connector)
      rescue StandardError => e
        Utility::Logger.error_with_backtrace(message: "Error happened when syncing #{display_name}", exception: e)
        @status[:error] = e.message
      ensure
        yield @status.dup
      end

      def sync_content(connector)
        sync(connector)
      rescue StandardError => e
        Utility::Logger.error("Error happened when syncing #{display_name}. Error: #{e.message}")
        @status[:error] = e.message
      ensure
        yield @status.dup
      end

      def sync(connector)
        @sink = Utility::Sink::CombinedSink.new(
          [Utility::Sink::ConsoleSink.new,
           Utility::Sink::ElasticSink.new(connector['index_name'])]
        )
      end

      def source_status(params = {})
        health_check(params)
        { :status => 'OK', :statusCode => 200, :message => "Connected to #{display_name}" }
      rescue StandardError => e
        { :status => 'FAILURE', :statusCode => e.is_a?(custom_client_error) ? e.status_code : 500, :message => e.message }
      end

      def display_name
        raise 'Not implemented for this connector'
      end

      def service_type
        self.class::SERVICE_TYPE
      end

      def configurable_fields
        {}
      end
    end
  end
end
