guard 'rspec', cmd: 'rspec --color --format=nested --format=doc --format=Nc' do
  # watch /lib/ files
  watch(%r{^lib/(.+)\.rb$}) do |m|
    "spec/#{m[1]}_spec.rb"
  end

  # watch /spec/ files
  watch(%r{^spec/(.+)\.rb$}) do |m|
    "spec/#{m[1]}.rb"
  end
end
