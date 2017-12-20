# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alarmable do
  it 'has a version number' do
    expect(Alarmable::VERSION).not_to be nil
  end
end
