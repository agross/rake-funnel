# frozen_string_literal: true

describe Rake::Funnel::Extensions::CommonPath do
  describe 'Manual debugging test case' do
    it 'should work' do
      expect(%w(/common/one /com/two).common_path).to be_truthy

      skip('for manual testing only')
    end
  end

  describe 'modification of FileList' do
    it 'should not modify the input' do
      input = FileList[File.join(File.dirname(__FILE__), '**/*')]
      duped = input.dup

      expect(input.common_path).to be_truthy

      expect(input).to match_array(duped)
    end
  end

  {
    array: [
      { input: [], expected: '' },
      { input: %w(one two), expected: '' },
      { input: %w(1-common 2-common), expected: '' },
      { input: %w(common.1 common-2), expected: '' },
      { input: %w(common-1 common-2), expected: '' },
      { input: %w(/common common), expected: '' },
      { input: %w(/ /foo), expected: '/' },
      { input: %w(/common/one /com/two), expected: '/' },
      { input: %w(/common/1 /common/2), expected: '/common' },
      { input: %w(/common/1 /common/2 /common/3/4), expected: '/common' },
      { input: %w(/common /common), expected: '/common' },
      { input: %w(/common /common/), expected: '/common' },
      { input: %w(/common/ /common/), expected: '/common' },
      { input: ['common/ 1', 'common/ 2'], expected: 'common' },
      { input: ['com mon/1', 'com mon/2'], expected: 'com mon' },
      { input: [' common/1', ' common/2'], expected: ' common' },
      { input: ['common /1', 'common /2'], expected: 'common ' },
      { input: [''], expected: '' },
      { input: ['', nil], expected: '' }
    ],
    file_list: [
      { input: FileList.new, expected: '' },
      { input: FileList['lib/*', 'spec/*'], expected: '' },
      { input: FileList['spec/*'], expected: 'spec' }
    ]
  }.each do |group, pairs|
    describe group do
      pairs.each do |pair|
        it "#{pair[:input]} should equal '#{pair[:expected]}'" do
          expect(pair[:input].common_path).to eq(pair[:expected])
        end
      end
    end
  end
end
