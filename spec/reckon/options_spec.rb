require "spec_helper"

describe '#parse_opts' do
  it 'should assign to :string option' do
    options = Reckon::Options.parse_command_line_options(
      %w[-f - --unattended --account bank],
      StringIO.new('foo,bar,baz')
    )
    expect(options[:string]).to eq('foo,bar,baz')
  end

  it 'should require --unattended flag' do
    expect { Reckon::Options.parse_command_line_options(%w[-f - --account bank]) }.to(
      raise_error(RuntimeError, "--unattended is required to use STDIN as CSV source.")
    )
  end
end
