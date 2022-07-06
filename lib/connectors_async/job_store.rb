#
# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.
#

require 'concurrent'
require 'securerandom'

require 'connectors_async/job'
require 'connectors_async/job_watcher'

module ConnectorsAsync
  class JobStore
    class JobNotFoundError < StandardError; end

    def initialize
      # multiple threads can write to the store
      @store = Concurrent::Hash.new
      @watcher = ConnectorsAsync::JobWatcher.new(job_store: self)
      @watcher.watch
    end

    def create_job
      job_id = SecureRandom.uuid

      job = ConnectorsAsync::Job.new(job_id)

      @store[job_id] = job

      job # get one
    end

    def fetch_job(job_id)
      raise JobNotFoundError unless @store.has_key?(job_id)

      @store[job_id]
    end

    def fetch_all
      @store.values
    end

    def delete_job!(job_id)
      raise JobNotFoundError unless @store.has_key?(job_id)

      @store.delete(job_id)
    end
  end
end