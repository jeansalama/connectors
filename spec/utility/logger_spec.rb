# frozen_string_literal: true

#
# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.
#

require 'spec_helper'
require 'utility/logger'

RSpec.describe Utility::Logger do
  let(:message) { 'this is a test message' }
  let(:long_message) { 'This is a really long test message - it is longer than the max. This is a really long test message - it is longer than the max.' }
  let(:message_with_breaks) { 'This is a message with line breaks.\nThis is a message with line breaks.' }
  let(:message_with_tabs) { 'This is a message  with tabs.\t\t\tThis is a message  with tabs.' }
  let(:message_with_many_spaces) { '  This is a    message with a lot of spaces.  ' }
  let(:logger) { ::Logger.new(STDOUT) }

  before do
    stub_const('Utility::Logger::MAX_SHORT_MESSAGE_LENGTH', 100)
    allow(described_class).to receive(:logger).and_return(logger)
  end

  it 'can give the connectors logger' do
    expect { described_class.info(message) }.to output(/#{message}/).to_stdout_from_any_process
  end

  it 'can shorten a long message' do
    expect(described_class.abbreviated_message(long_message).length).to eq(100)
  end

  it 'can clean line breaks' do
    expect(described_class.abbreviated_message(message_with_breaks).match(/\n/)).to be_falsey
  end

  it 'can clean tabs' do
    expect(described_class.abbreviated_message(message_with_tabs).match(/\t/)).to be_falsey
  end

  it 'can clean extra spaces' do
    msg = described_class.abbreviated_message(message_with_many_spaces)
    expect(msg.match(/\s{2,}/)).to be_falsey
    expect(msg.match(/^\s/)).to be_falsey
    expect(msg.match(/\s$/)).to be_falsey
  end

  context 'with ecs logging' do
    let(:logger) { EcsLogging::Logger.new(STDOUT) }

    it 'outputs ecs fields' do
      expect { described_class.info(message) }.to output(/@timestamp/).to_stdout_from_any_process
      expect { described_class.info(message) }.to output(/ecs\.version/).to_stdout_from_any_process
    end
  end

  describe '.log_stacktrace' do
    let(:stacktrace) { 'stacktrace' }
    it 'outputs stacktrace' do
      expect { described_class.log_stacktrace(stacktrace) }.to output(/#{stacktrace}/).to_stdout_from_any_process
    end

    context 'with ecs logging' do
      let(:logger) { EcsLogging::Logger.new(STDOUT) }

      it 'outputs error.stack_trace' do
        expect { described_class.log_stacktrace(stacktrace) }.to output(/"error":\{"stack_trace":/).to_stdout_from_any_process
        expect { described_class.log_stacktrace(stacktrace) }.to output(/@timestamp/).to_stdout_from_any_process
      end
    end
  end
end
