require 'spec_helper'

describe AppsignalReport::VERSION do
  let(:version) { AppsignalReport::VERSION }
  let(:split_version) { version.split('.') }

  it 'be a semantic version' do
    version.must_be_instance_of String
    (split_version.count >= 3).must_equal true
    split_version[0].must_match /^\d+$/
    split_version[1].must_match /^\d+$/
    split_version[2].must_match /^\d+(-pre|-alpha|-beta)?$/
  end
end
