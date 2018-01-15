guard :rspec, cmd: 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})         { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/factories/.+\.rb}) { "spec" }
  watch('spec/spec_helper.rb')      { "spec" }
  watch(%r{^spec/standard_cases/})  { "spec/determinator/control_spec.rb" }
end
